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
class PluginLoader

	# ---------------------------------
	# Constructed

	# DocPad Instance
	docpad: null

	# BasePlugin Class
	BasePlugin: null

	# The full path of the plugin's directory
	dirPath: null


	# ---------------------------------
	# Loaded

	# The full path of the plugin's package.json file
	packagePath: null

	# The parsed contents of the plugin's package.json file
	packageData: {}

	# The full path of the plugin's main file
	pluginPath: null

	# The parsed content of the plugin's main file
	pluginClass: {}

	# Plugin name
	pluginName: null

	# Plugin version
	pluginVersion: null

	# Node modules path
	nodeModulesPath: null


	# ---------------------------------
	# Functions

	# Constructor
	constructor: ({@docpad,@dirPath,@BasePlugin}) ->
		# Prepare
		docpad = @docpad

		# Apply
		@pluginName = pathUtil.basename(@dirPath).replace(/^docpad-plugin-/,'')
		@pluginClass = {}
		@packageData = {}
		@nodeModulesPath = pathUtil.resolve(@dirPath, 'node_modules')

	# Exists
	# Loads the package.json file and extracts the main path
	# next(err,exists)
	exists: (next) ->
		# Prepare
		packagePath = @packagePath or pathUtil.resolve(@dirPath, "package.json")
		failure = (err=null) ->
			return next(err, false)
		success = =>
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

	# Unsupported
	# Check if this plugin is unsupported
	# next(err,supported)
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

	# Install
	# Installs the plugins node modules
	# next(err)
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

	# Load
	# Load in the pluginClass from the pugin file
	# next(err,pluginClass)
	load: (next) ->
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Load
		try
			# Load in our plugin
			@pluginClass = require(@pluginPath)(@BasePlugin)
			@pluginClass::version ?= @pluginVersion
			pluginPrototypeName = @pluginClass::name

			# Checks
			# Alphanumeric
			if /^[a-z0-9]+$/.test(@pluginName) is false
				validPluginName = @pluginName.replace(/[^a-z0-9]/,'')
				docpad.log('warn', util.format(locale.pluginNamingConventionInvalid, @pluginName, validPluginName))
			# Same name
			if pluginPrototypeName is null
				@pluginClass::name = @pluginName
				docpad.log('warn',  util.format(locale.pluginPrototypeNameUndefined, @pluginName))
			else if pluginPrototypeName isnt @pluginName
				docpad.log('warn', util.format(locale.pluginPrototypeNameDifferent, @pluginName, pluginPrototypeName))
		catch err
			# An error occured, return it
			return next(err, null)

		# Return our plugin
		next(null,@pluginClass)

		# Chain
		@

	# Create Instance
	# next(err,pluginInstance)
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
