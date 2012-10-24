# Requires
pathUtil = require('path')
semver = require('semver')
balUtil = require('bal-util')
util = require('util')

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
	# Loads in the plugin either via a package.json file, or a guessing based on the name
	# next(err,exists)
	exists: (next) ->
		# Package.json
		packagePath = @packagePath or pathUtil.resolve(@dirPath, "package.json")
		pluginPath = @pluginPath or pathUtil.resolve(@dirPath, "#{@pluginName}.plugin.coffee")
		# the fetch of the this value above allows advanced use cases of plugin loading
		# hover, as of yet, we don't do any such advanced use cases
		balUtil.exists packagePath, (exists) =>
			unless exists
				balUtil.exists pluginPath, (exists) =>
					unless exists
						return next(null,false)
					else
						@pluginPath = pluginPath
						return next(null,true)
			else
				@packagePath = packagePath
				balUtil.readFile packagePath, (err,data) =>
					if err
						return next(err,false)
					else
						try
							@packageData = JSON.parse data.toString()
						catch err
							return next(err,false)
						return next(null,false)  unless @packageData

						# Fetch the plugin path
						pluginPath = @packageData.main? and pathUtil.join(@dirPath, @pluginPath) or pluginPath
						@pluginVersion = @packageData.version
						balUtil.exists pluginPath, (exists) =>
							unless exists
								return next(null,false)
							else
								@pluginPath = pluginPath
								return next(null,true)

		# Chain
		@

	# Unsupported
	# Check if this plugin is unsupported
	# next(err,supported)
	unsupported: (next) ->
		# Prepare
		docpad = @docpad
		unsupported = false

		# Check type
		if @packageData
			keywords = @packageData.keywords or []
			unless 'docpad-plugin' in keywords
				unsupported = 'type'

		# Check platform
		if @packageData and @packageData.platforms
			platforms = @packageData.platforms or []
			unless process.platform in platforms
				unsupported = 'platform'

		# Check engines
		if @packageData and @packageData.engines
			engines = @packageData.engines or {}

			# Node engine
			if engines.node?
				unless semver.satisfies(process.version, engines.node)
					unsupported = 'engine'

			# DocPad engine
			if engines.docpad?
				unless semver.satisfies(docpad.version, engines.docpad)
					unsupported = 'version'

		# Supported
		next(null,unsupported)

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
			return next(err,null)

		# Return our plugin
		next(null,@pluginClass)

		# Chain
		@

	# Create Instance
	# next(err,pluginInstance)
	create: (userConfiguration={},next) ->
		# Load
		try
			# Merge configurations
			config = balUtil.deepExtendPlainObjects({}, @docpad.config.plugins[@pluginName], userConfiguration)

			# Create instance with merged configuration
			docpad = @docpad
			pluginInstance = new @pluginClass({docpad,config})
		catch err
			# An error occured, return it
			return next(err,null)

		# Return our instance
		return next(null,pluginInstance)

		# Chain
		@


# Export
module.exports = PluginLoader