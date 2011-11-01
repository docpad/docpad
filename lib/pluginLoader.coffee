# Requires
path = require 'path'
fs = require 'fs'

# Define Plugin Loader
class PluginLoader

	# The full path of the plugin's package.json file
	packagePath: null

	# The parsed contents of the plugin's package.json file
	packageData: {}

	# The full path of the plugin's main file
	pluginPath: null

	# The parsed content of the plugin's main file
	pluginClass: {}

	# The full path of the plugin's directory
	dirPath: null

	# Plugin name
	name: null

	# Constructor
	constructor: (dirPath) ->
		# Apply
		@dirPath = dirPath
		@name = path.dirname(dirPath)
	
	# Exists
	# next(err,exists)
	exists: (next) ->
		# Package.json
		packagePath = "#{dirPath}/package.json"
		pluginPath = "#{dirPath}/#{@name}.plugin.coffee"
		path.exists packagePath, (exists) =>
			unless exists
				path.exists pluginPath, (exists) =>
					unless exists
						return next(null,false)  
					else
						@pluginPath = pluginPath
						return next(null,true)
			else
				@packagePath = packagePath
				fs.readFile packagePath, (err,data) =>
					if err
						return next(err,false)
					else
						try
							@packageData = JSON.parse data.toString()
						catch err
							return next(err,false)
						
						pluginPath =  @packageData.main? and @packageData.main or pluginPath
						path.exists pluginPath, (exists) =>
							unless exists
								return next(null,false)  
							else
								@pluginPath = pluginPath
								return next(null,true)
	
	# Load
	# next(err)
	load: (next) ->
		try
			@pluginClass = require(@pluginPath)
		catch err
			return next(err,false)
		next(@pluginClass)
