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
	pluginName: null

	# Constructor
	constructor: (dirPath) ->
		# Apply
		@dirPath = dirPath
		@pluginName = path.basename(dirPath)
	
	# Exists
	# next(err,exists)
	exists: (next) ->
		# Check 
		if @pluginPath
			next(null,true)
			return @

		# Package.json
		packagePath = "#{@dirPath}/package.json"
		pluginPath = "#{@dirPath}/#{@pluginName}.plugin.coffee"
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
						
						pluginPath =  @packageData.main? and path.join(@dirPath, @pluginPath) or pluginPath
						path.exists pluginPath, (exists) =>
							unless exists
								return next(null,false)  
							else
								@pluginPath = pluginPath
								return next(null,true)
		return @
	
	# Load
	# next(err,pluginClass)
	load: (next) ->
		# Check if exists
		if @pluginPath is null
			@exists (err,exists) =>
				return next(err,null)  if err or not exists
				return @load(next)
			return @
		
		# It doesn't exist
		else if @pluginPath is false
			next(null,null)
			return @
		
		# We're already loaded
		if @pluginClass
			next(null,@pluginClass)
			return @

		# Load
		try
			@pluginClass = require(@pluginPath)
		catch err
			return next(err,null)
		
		# Return loaded
		next(null,@pluginClass)
		return @
	
	# Create Instance
	# next(err,instance)
	create: (next) ->
		# Loaded
		


# Export
module.exports = PluginLoader