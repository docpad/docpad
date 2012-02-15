# Requires
path = require 'path'
fs = require 'fs'
_ = require 'underscore'
exec = require('child_process').exec

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

	# The plugin configuration to load into it
	pluginConfig: {}

	# The full path of the plugin's main file
	pluginPath: null

	# The parsed content of the plugin's main file
	pluginClass: {}

	# Plugin name
	pluginName: null

	# Node modules path
	nodeModulesPath: null


	# ---------------------------------
	# Functions

	# Constructor
	constructor: ({@docpad,@dirPath,@BasePlugin}) ->
		# Apply
		@pluginName = path.basename(@dirPath)
		@pluginClass = {}
		@pluginConfig = {}
		@packageData = {}
		@nodeModulesPath = path.resolve @dirPath, 'node_modules'
	
	# Exists
	# Loads in the plugin either via a package.json file, or a guessing based on the name
	# next(err,exists)
	exists: (next) ->
		# Package.json
		packagePath = path.resolve @dirPath, "package.json"
		pluginPath = path.resolve @dirPath, "#{@pluginName}.plugin.coffee"
		path.exists packagePath, (exists) =>
			unless exists
				path.exists pluginPath, (exists) =>
					unless exists
						return next?(null,false)  
					else
						@pluginPath = pluginPath
						return next?(null,true)
			else
				@packagePath = packagePath
				fs.readFile packagePath, (err,data) =>
					if err
						return next?(err,false)
					else
						try
							@packageData = JSON.parse data.toString()
						catch err
							return next?(err,false)
						return next?(null,false)  unless @packageData

						@pluginConfig = @packageData.docpad and @packageData.docpad.plugin or {}
						
						pluginPath =  @packageData.main? and path.join(@dirPath, @pluginPath) or pluginPath
						path.exists pluginPath, (exists) =>
							unless exists
								return next?(null,false)  
							else
								@pluginPath = pluginPath
								return next?(null,true)
		
		# Chain
		return @
	
	# Supported
	# Check if this plugin is supported on our platform
	# next(err,supported)
	supported: (next) ->
		# Check support status
		if @packageData and @packageData.platforms
			platforms = @packageData.platforms or []
			if process.platform in platforms
				supported = true
			else
				supported = false
		else
			supported = true
		
		# Supported
		next?(null,supported)

		# Chain
		@
	
	# Installed
	# Has this plugin already been installed?
	# next(err,installed)
	installed: (next) ->
		path.exists @nodeModulesPath, (exists) ->
			next?(null,exists)
		@
	
	# Install
	# Installs the plugins dependencies via NPM
	# It doesn't appear that the npm module yet supports parallel processing
	# So until it does, then we have to spawn it instead
	# next(err)
	install: (next) ->
		# Global NPM on Windows
		if /^win/.test(process.platform)
			command = "npm install"
		
		# Local NPM on everything else
		else
			nodePath = if /node$/.test(process.execPath) then process.execPath else 'node'
			npmPath = path.resolve @docpad.corePath,'node_modules','npm','bin','npm-cli.js'
			command = "\"#{nodePath}\" \"#{npmPath}\" install"

		# Execute npm install inside the pugin directory
		child = exec(
			# Command
			command

			# Options
			{ cwd: @dirPath }

			# Callback
			(error, stdout, stderr) ->
				# Forward
				next?(error)
		)

		# Chain
		return @

	# Load
	# Load in the pluginClass from the pugin file
	# next(err,pluginClass)
	load: (next) ->
		# Load
		try
			@pluginClass = require(@pluginPath)(@BasePlugin)
			next?(null,@pluginClass)
		catch err
			next?(err,null)
		
		# Chain
		return @
	
	# Create Instance
	# next(err,pluginInstance)
	create: (userConfiguration={},next) ->
		# Load
		try
			docpadConfiguration = @docpad.config.plugins[@pluginName] or {}
			config = _.extend {}, @pluginConfig, docpadConfiguration, userConfiguration
			config.docpad = @docpad
			pluginInstance = new @pluginClass config
			next?(null,pluginInstance)
		catch err
			next?(err,null)
		
		# Chain
		return @


# Export
module.exports = PluginLoader