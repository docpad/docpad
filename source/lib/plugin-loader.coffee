# ---------------------------------
# Requires

# Standard Library
pathUtil = require('path')
util = require('util')

# External
semver = require('semver')
safefs = require('safefs')



# ---------------------------------
# Classes

# Define Plugin Loader
###*
# The Plugin Loader class
# @class PluginLoader
# @constructor
###
class PluginLoader

	# ---------------------------------
	# Constructed

	###*
	# The DocPad Instance
	# @private
	# @property {Object} docpad
	###
	docpad: null


	###*
	# The BasePlugin Class
	# @private
	# @property {Object}
	###
	BasePlugin: null


	###*
	# The full path of the plugin's directory
	# @private
	# @property {String}
	###
	dirPath: null


	# ---------------------------------
	# Loaded

	###*
	# The full path of the plugin's package.json file
	# @private
	# @property {String}
	###
	packagePath: null

	###*
	# The parsed contents of the plugin's package.json file
	# @private
	# @property {Object}
	###
	packageData: {}

	###*
	# The full path of the plugin's main file
	# @private
	# @property {String}
	###
	pluginPath: null


	###*
	# The parsed content of the plugin's main file
	# @private
	# @property {Object}
	###
	pluginClass: {}

	###*
	# The plugin name
	# @private
	# @property {String}
	###
	pluginName: null

	###*
	# The plugin version
	# @private
	# @property {String}
	###
	pluginVersion: null

	###*
	# Node modules path
	# @private
	# @property {String}
	###
	nodeModulesPath: null


	# ---------------------------------
	# Functions

	###*
	# Constructor method
	# @method constructor
	# @param {Object} opts
	# @param {Object} opts.docpad The docpad instance that we are loading plugins for
	# @param {String} opts.dirPath The directory path of the plugin
	# @param {Object} opts.BasePlugin The base plugin class
	###
	constructor: ({@docpad,@dirPath,@BasePlugin}) ->
		# Prepare
		docpad = @docpad

		# Apply
		@pluginName = pathUtil.basename(@dirPath).replace(/^docpad-plugin-/,'')
		@pluginClass = {}
		@packageData = {}
		@nodeModulesPath = pathUtil.resolve(@dirPath, 'node_modules')


	###*
	# Loads the package.json file and extracts the main path
	# next(err,exists)
	# @method exists
	# @param {Function} next
	###
	exists: (next) ->
		# Prepare
		packagePath = @packagePath or pathUtil.resolve(@dirPath, "package.json")
		failure = (err=null) ->
			return next(err, false)
		success = ->
			return next(null, true)

		# Check the package
		safefs.exists packagePath, (exists) =>
			return failure()  unless exists

			# Apply
			@packagePath = packagePath

			# Read the package
			safefs.readFile packagePath, (err,data) =>
				return failure(err)  if err

				# Parse the package
				try
					@packageData = JSON.parse data.toString()
				catch err
					return failure(err)
				finally
					return failure()  unless @packageData

				# Extract the version and main
				pluginVersion = @packageData.version
				pluginPath = @packageData.main and pathUtil.join(@dirPath, @packageData.main)

				# Check defined
				return failure()  unless pluginVersion
				return failure()  unless pluginPath

				# Success
				@pluginVersion = pluginVersion
				@pluginPath = pluginPath
				return success()

		# Chain
		@

	###*
	# Check if this plugin is unsupported
	# Boolean value returned as a parameter
	# in the passed callback
	# next(err,supported)
	# @method unsupported
	# @param {Function} next
	###
	unsupported: (next) ->
		# Prepare
		docpad = @docpad

		# Extract
		version = @packageData.version
		keywords = @packageData.keywords or []
		platforms = @packageData.platforms or []
		engines = @packageData.engines or {}
		peerDependencies = @packageData.peerDependencies or {}

		# Check
		unsupported =
			# Check type
			if 'docpad-plugin' not in keywords
				'type'

			# Check version
			else if version and not semver.satisfies(version, docpad.pluginVersion)
				'version-plugin'

			# Check platform
			else if platforms.length and process.platform not in platforms
				'platform'

			# Check node engine
			else if engines.node? and not semver.satisfies(process.version, engines.node)
				'engine-node'

			# Check docpad engine
			else if engines.docpad? and not semver.satisfies(docpad.getVersion(), engines.docpad)
				'version-docpad'

			# Check docpad peerDependencies
			else if peerDependencies.docpad? and not semver.satisfies(docpad.getVersion(), peerDependencies.docpad)
				'version-docpad'

			# Supported
			else
				false

		# Supported
		next(null, unsupported)

		# Chain
		@

	###*
	# Installs the plugins node modules.
	# next(err)
	# @private
	# @method install
	# @param {Function} next
	###
	install: (next) ->
		# Prepare
		docpad = @docpad

		# Only install if we have a package path
		if @packagePath
			# Install npm modules
			docpad.initNodeModules(
				path: @dirPath
				next: (err,results) ->
					# Forward
					return next(err)
			)
		else
			# Continue
			next()

		# Chain
		@

	###*
	# Load in the pluginClass from the plugin file.
	# The plugin class that has been loaded is returned
	# in the passed callback
	# next(err,pluginClass)
	# @method load
	# @param {Function} next
	###
	load: (next) ->
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Ensure we still have deprecated support for old-style uncompiled plugins
		if pathUtil.extname(@pluginPath) is '.coffee'
			# Warn the user they are trying to include an uncompiled plugin (if they want to be warned)
			# They have the option of opting out of warnings for private plugins
			unless @packageData.private is true and docpad.getConfig().warnUncompiledPrivatePlugins is false
				docpad.warn util.format(locale.pluginUncompiled, @pluginName, @packageData.bugs?.url or locale.pluginIssueTracker)

			# Attempt to include the coffee-script register extension
			# coffee-script is an external party dependency (docpad doesn't depend on it, so we don't install it)
			# so we may not have it, hence the try catch
			try
				require('coffee-script/register')
			catch err
				# Including coffee-script has failed, so let the user know, and exit
				err.context = util.format(locale.pluginUncompiledFailed, @pluginName, @packageData.bugs?.url or locale.pluginIssueTracker)
				return next(err); @


		# Attempt to load the plugin
		try
			@pluginClass = require(@pluginPath)(@BasePlugin)
		catch err
			# Loading the plugin has failed, so let the user know, and exit
			err.context = util.format(locale.pluginLoadFailed, @pluginName, @packageData.bugs?.url or locale.pluginIssueTracker)
			return next(err); @

		# Plugin loaded, inject it's version and grab its name
		@pluginClass::version ?= @pluginVersion
		pluginPrototypeName = @pluginClass::name

		# Check Alphanumeric Name
		if /^[a-z0-9]+$/.test(@pluginName) is false
			validPluginName = @pluginName.replace(/[^a-z0-9]/,'')
			docpad.warn util.format(locale.pluginNamingConventionInvalid, @pluginName, validPluginName)

		# Check for Empty Name
		if pluginPrototypeName is null
			@pluginClass::name = @pluginName
			docpad.warn util.format(locale.pluginPrototypeNameUndefined, @pluginName)

		# Check for Same Name
		else if pluginPrototypeName isnt @pluginName
			docpad.warn util.format(locale.pluginPrototypeNameDifferent, @pluginName, pluginPrototypeName)

		# Return our plugin
		next(null, @pluginClass)

		# Chain
		@

	###*
	# Create an instance of a plugin
	# defined by the passed config.
	# The plugin instance is returned in
	# the passed callback.
	# next(err,pluginInstance)
	# @method create
	# @param {Object} config
	# @param {Function} next
	###
	create: (config,next) ->
		# Load
		try
			# Create instance with merged configuration
			docpad = @docpad
			pluginInstance = new @pluginClass({docpad,config})
		catch err
			# An error occured, return it
			return next(err, null)

		# Return our instance
		return next(null, pluginInstance)

		# Chain
		@


# ---------------------------------
# Export
module.exports = PluginLoader
