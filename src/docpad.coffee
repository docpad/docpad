# =====================================
# Requires

# Necessary
pathUtil = require('path')
fsUtil = require('fs')
_ = require('underscore')
caterpillar = require('caterpillar')
CSON = require('cson')
balUtil = require('bal-util')
EventSystem = balUtil.EventSystem

# Optionals
airbrake = null

# Locals
Base = require(__dirname+'/base')
require(__dirname+'/prototypes')

# =====================================
# DocPad

###
The DocPad Class
It extends the EventSystem from bal-util to provide system events
It allows us to support multiple instances of docpad at the same time
###
class DocPad extends EventSystem

	# =================================
	# Variables

	# ---------------------------------
	# Modules

	# Bases
	PluginLoader: require(__dirname+'/plugin-loader')
	BasePlugin: require(__dirname+'/plugin')
	Base: Base

	# Models
	FileModel: require(__dirname+'/models/file')
	DocumentModel: require(__dirname+'/models/document')

	# Collections
	QueryCollection: Base.QueryCollection
	FilesCollection: require(__dirname+'/collections/files')
	ElementsCollection: require(__dirname+'/collections/elements')
	MetaCollection: require(__dirname+'/collections/meta')
	ScriptsCollection: require(__dirname+'/collections/scripts')
	StylesCollection: require(__dirname+'/collections/styles')


	# ---------------------------------
	# DocPad

	# DocPad's version number
	version: null
	getVersion: ->
		@version

	# The express server instance bound to docpad
	serverInstance: null
	getServer: ->
		@serverInstance
	setServer: (value) ->
		@serverInstance = value
		@

	# The caterpillar instance bound to docpad
	loggerInstance: null
	getLogger: ->
		@loggerInstance
	setLogger: (value) ->
		@loggerInstance = value
		@


	# ---------------------------------
	# Collections

	# Database collection
	database: null  # QueryEngine Collection
	getDatabase: -> @database

	# Blocks
	blocks: null
	### {
		# A collection of meta elements
		meta: null  # Elements Collection

		# A collection of script elements
		scripts: null  # Scripts Collection

		# Collection of style elements
		styles: null  # Styles Collection
	} ###

	# Get a block
	getBlock: (name,clone) ->
		block = @blocks[name]
		if clone
			classname = name[0].toUpperCase()+name[1..]+'Collection'
			block = new @[classname](block.models)
		return block

	#  Set a block
	setBlock: (name,value) ->
		@blocks[name] = value
		@

	# Collections
	collections: null
	### {
		# Documents collection
		documents: null  # QueryEngine Collection

		# Files collection
		files: null  # QueryEngine Collection

		# Layouts collection
		layouts: null  # QueryEngine Collection
	} ###

	# Get a collection
	getCollection: (name) ->
		@collections[name]

	# Set a collection
	setCollection: (name,value) ->
		@collections[name] = value
		@

	# ---------------------------------
	# Plugins

	# Plugins that are loading really slow
	slowPlugins: null  # {}

	# Plugins which DocPad have found
	foundPlugins: null  # {}

	# Loaded plugins indexed by name
	loadedPlugins: null  # {}

	# A listing of all the available extensions for DocPad
	exchange: null  # {}


	# -----------------------------
	# Paths

	# The DocPad directory
	corePath: pathUtil.join(__dirname, '..')

	# The DocPad library directory
	libPath: __dirname

	# The main DocPad file
	mainPath: pathUtil.join(__dirname, 'docpad')

	# The DocPad package.json path
	packagePath: pathUtil.join(__dirname, '..', 'package.json')

	# The DocPad local NPM path
	npmPath: pathUtil.join(__dirname, '..', 'node_modules', 'npm', 'bin', 'npm-cli.js')


	# -----------------------------
	# Configuration

	###
	Instance Configuration
	Loaded from:
		- the passed instanceConfiguration when creating a new DocPad instance
		- the detected websiteConfiguration inside ./docpad.cson>docpad
		- the following configuration
	###
	config:

		# -----------------------------
		# Plugins

		# Force re-install of all plugin dependencies
		force: false

		# Whether or not we should enable plugins that have not been listed or not
		enableUnlistedPlugins: true

		# Plugins which should be enabled or not pluginName: pluginEnabled
		enabledPlugins: null  # {}

		# Whether or not we should skip unsupported plugins
		skipUnsupportedPlugins: true

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: null  # {}

		# Where to fetch the exchange information from
		exchangeUrl: 'https://raw.github.com/bevry/docpad-extras/docpad-5.x/exchange.json'


		# -----------------------------
		# Website Paths

		# The website directory
		rootPath: '.'

		# The website's package.json path
		packagePath: 'package.json'

		# The website's docpad.cson path
		configPath: 'docpad.cson'

		# The website's out directory
		outPath: 'out'

		# The website's src directory
		srcPath: 'src'

		# The website's documents directories
		documentsPaths: [
			pathUtil.join('src', 'documents')
		]

		# The website's files directories
		filesPaths: [
			pathUtil.join('src', 'files')
			pathUtil.join('src', 'public')
		]

		# The website's layouts directory
		layoutsPaths: [
			pathUtil.join('src', 'layouts')
		]

		# Plugin directories to load
		pluginPaths: []

		# The website's plugins directory
		pluginsPaths: ['node_modules','plugins']


		# -----------------------------
		# Server

		# Server
		# A express server that we want docpad to use
		server: null

		# Extend Server
		# Whether or not we should extend the server with extra middleware and routing
		extendServer: true

		# Port
		# The port that the server should use
		port: 9778

		# Max Age
		# The caching time limit that is sent to the client
		maxAge: false


		# -----------------------------
		# Logging

		# Log Level
		# Which level of logging should we actually output
		logLevel: (if ('-d' in process.argv) then 7 else 6)

		# Logger
		# A caterpillar instance if we already have one
		logger: null

		# Growl
		# Whether or not to send notifications to growl when we have them
		growl: true


		# -----------------------------
		# Other

		# Node Path
		# The location of our node executable
		nodePath: if /node$/.test(process.execPath) then process.execPath else 'node'

		# Git Path
		# The location of our git executable
		gitPath: if /^win/.test(process.platform) then 'git.cmd' else 'git'

		# Template Data
		# What data would you like to expose to your templates
		templateData: null  # {}

		# Report Errors
		# Whether or not we should report our errors back to DocPad
		reportErrors: true

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: true

		# Collections
		# A hash of functions that create collections
		collections: null  # {}


	# =================================
	# Initialization Functions

	# Construct DocPad
	# next(err)
	constructor: (config={},next) ->
		# Prepare
		docpad = @

		# Ensure certain functions always have the scope of this instance
		_.bindAll(@, 'createDocument', 'createFile')

		# Allow DocPad to have unlimited event listeners
		@setMaxListeners(0)

		# Initialize a default logger
		logger = new caterpillar.Logger(
			transports:
				formatter: module: module
		)
		@setLogger(logger)
		@setLogLevel(6)
		debugger

		# Bind the error handler, so we don't crash on errors
		process.setMaxListeners(0)
		process.on 'uncaughtException', (err) ->
			docpad.error(err)

		# Log to bubbled events
		@on 'log', (args...) ->
			@log.apply(@,args)

		# Dereference and initialise advanced variables
		@slowPlugins = {}
		@foundPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@collections = {}
		@blocks = {}
		@config = _.clone(@config)
		@config.enabledPlugins = {}
		@config.plugins = {}
		@config.templateData = {}
		@config.collections = {}
		@config.documentsPaths = @config.documentsPaths.slice()
		@config.filesPaths = @config.filesPaths.slice()
		@config.layoutsPaths = @config.layoutsPaths.slice()
		@config.pluginPaths = @config.pluginPaths.slice()
		@config.pluginsPaths = @config.pluginsPaths.slice()

		# Initialize the collections
		@database = new @FilesCollection()

		# Apply configuration
		@loadConfiguration config, {}, (err) =>
			# Error?
			return @error(err)  if err


			# Collections
			documents = @database.createLiveChildCollection()
				.setQuery('isDocument', {
					$or:
						isDocument: true
						fullPath: $startsWith: @config.documentsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding document: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isDocument: true
						render: true
						write: true
					})
				)
			files = @database.createLiveChildCollection()
				.setQuery('isFile', {
					$or:
						isFile: true
						fullPath: $startsWith: @config.filesPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding file: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isFile: true
						render: false
						write: true
					})
				)
			layouts = @database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isLayout: true
						fullPath: $startsWith: @config.layoutsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding layout: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isLayout: true
						render: false
						write: false
					})
				)

			# Apply collections
			@setCollection('documents',documents)
			@setCollection('files',files)
			@setCollection('layouts',layouts)


			# Blocks
			meta = new @MetaCollection().add([
				'<meta http-equiv="X-Powered-By" content="DocPad"/>'
			])
			scripts = new @MetaCollection()
			styles = new @MetaCollection()

			# Apply Blocks
			@setBlock('meta',meta)
			@setBlock('scripts',scripts)
			@setBlock('styles',styles)


			# Load Airbrake if we want to reportErrors
			if @config.reportErrors and /win/.test(process.platform) is false
				airbrake = require('airbrake').createClient('e7374dd1c5a346efe3895b9b0c1c0325')

			# Version Check
			@compareVersion()

			# Log
			@log 'debug', 'DocPad loaded succesfully'
			@log 'debug', 'Loaded the following plugins:', _.keys(@loadedPlugins).sort().join(', ')

			# Next
			return next?()


	# =================================
	# Configuration

	# Clean Resources
	cleanResources: ->
		# Perform a complete clean of our collections
		@getDatabase().reset([])
		@getBlock('meta').reset([])
		@getBlock('scripts').reset([])
		@getBlock('styles').reset([])

		# Chain
		@

	# Load a configuration url
	# next(err,parsedData)
	loadConfigUrl: (configUrl,next) ->
		# Log
		@log 'debug', "Loading configuration url: #{configUrl}"

		# Read the url using balUtil
		balUtil.readPath configUrl, (err,data) ->
			return next(err)  if err
			# Read the string using CSON
			CSON.parse(data.toString(),next)

		# Chain
		@

	# Load a configuration file
	# CSON supports CSON and JSON
	# next(err,parsedData)
	loadConfigPath: (configPath,next) ->
		# Log
		@log 'debug', "Loading configuration path: #{configPath}"

		# Check that it exists
		pathUtil.exists configPath, (exists) ->
			return next?(null,null)  unless exists
			# Read the path using CSON
			CSON.parseFile(configPath, next)

		# Chain
		@

	# Load collections
	loadCollections: (next) ->
		# Prepare
		docpad = @
		database = @getDatabase()
		@config.collections or= {}

		# Group
		tasks = new balUtil.Group (err) =>
			docpad.error(err)  if err
			return next?()

		# Cycle
		_.each @config.collections, (fn,name) ->
			tasks.push (complete) ->
				if fn.length is 2 # callback
					fn database, (err,collection) ->
						docpad.error(err)  if err
						if collection
							collection.live(true)  # make it a live collection
							docpad.setCollection(name,collection)  # apply the collection
						complete()
				else
					collection = fn(database)
					if collection
						collection.live(true)  # make it a live collection
						docpad.setCollection(name,collection)  # apply the collection
					complete()

		# Run
		tasks.async()

		# Chain
		@

	# Load Configuration
	loadConfiguration: (instanceConfig={},options={},next) ->
		# Prepare
		docpad = @

		# Options
		options.blocking ?= true

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			nextStep = ->
				docpad.finish 'loading', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)
			if options.blocking
				docpad.unblock 'generating, watching, serving', (lockError) ->
					return fatal(lockError)  if lockError
					nextStep()
			else
				nextStep()

		# Define loading
		startLoading = =>
			# Start loading
			docpad.start 'loading', (lockError) =>
				return fatal(lockError)  if lockError

				# Prepare
				instanceConfig.rootPath or= process.cwd()
				instanceConfig.packagePath or= @config.packagePath
				instanceConfig.configPath or= @config.configPath
				docpadPackagePath = @packagePath
				websitePackagePath = pathUtil.resolve(instanceConfig.rootPath, instanceConfig.packagePath)  # only here for b/c
				websiteConfigPath = pathUtil.resolve(instanceConfig.rootPath, instanceConfig.configPath)
				websitePackageConfig = {}
				websiteConfig = {}

				# Async
				tasks = new balUtil.Group (err) =>
					return fatal(err)  if err

					# Merge Configuration (not deep!)
					config = _.extend(
						{}
						@config
						websitePackageConfig  # only here for b/c
						websiteConfig
						instanceConfig
					)

					# Merge enabled plugins
					config.enabledPlugins = _.extend(
						{}
						@config.enabledPlugins or {}
						websiteConfig.enabledPlugins or {}
						instanceConfig.enabledPlugins or {}
					)

					# Merge template data
					config.templateData = _.extend(
						{}
						@config.templateData or {}
						websiteConfig.templateData or {}
						instanceConfig.templateData or {}
					)

					# Apply merged configuration
					@config = config

					# Options
					@server = @config.server  if @config.server

					# Noramlize and resolve the configuration paths
					@config.rootPath = pathUtil.normalize(@config.rootPath or process.cwd())
					@config.outPath = pathUtil.resolve(@config.rootPath, @config.outPath)
					@config.srcPath = pathUtil.resolve(@config.rootPath, @config.srcPath)

					# Documents, Files, Layouts, Plugins paths
					for type in ['documents','files','layouts','plugins']
						typePaths = @config[type+'Paths']
						for typePath,key in typePaths
							typePaths[key] = pathUtil.resolve(@config.rootPath,typePath)

					# Logger
					@setLogger(@config.logger)  if @config.logger
					@setLogLevel(@config.logLevel)

					# Async
					postTasks = new balUtil.Group (err) =>
						return fatal(err)  if err
						return complete()
					postTasks.total = 2

					# Load collections
					@loadCollections(postTasks.completer())

					# Initialize
					@loadPlugins(postTasks.completer())


				# Prepare configuration loading
				tasks.total = 3

				# Load DocPad Configuration
				@loadConfigPath docpadPackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}

					# Version
					docpad.version = data.version
					airbrake.appVersion = docpad.version  if airbrake

					# Compelte the loading
					tasks.complete()

				# Load Website Package Configuration
				# only here for b/c
				@loadConfigPath websitePackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}

					# Apply data to parent scope
					websitePackageConfig = data.docpad or {}

					# Compelte the loading
					tasks.complete()

				# Load Website Configuration
				@loadConfigPath websiteConfigPath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}

					# Apply data to parent scope
					websiteConfig = data

					# Compelte the loading
					tasks.complete()

		# Block other events
		if options.blocking
			docpad.block 'generating, watching, serving', (lockError) =>
				return fatal(lockError)  if lockError
				startLoading()
		else
			startLoading()

		# Chain
		@


	# Init Node Modules
	# next(err,results)
	initNodeModules: (opts={}) ->
		# Prepare
		opts.npmPath = @npmPath
		opts.nodePath = @config.nodePath
		opts.force = @config.force

		# Forward
		balUtil.initNodeModules(opts)

		# Chain
		@


	# =================================
	# Logging

	# Set Log Level
	setLogLevel: (level) ->
		@getLogger().setLevel(level)
		@

	# Are we debugging?
	getLogLevel: ->
		return @config.logLevel

	# Are we debugging?
	getDebugging: ->
		return @getLogLevel() is 7

	# Handle a fatal error
	fatal: (err) ->
		return @  unless err
		@error err, 'err', ->
			process.exit(-1)
		@

	# Log
	log: (args...) ->
		logger = @getLogger()
		logger.log.apply(logger,args)
		@

	# Handle an error
	error: (err,type='err',next) ->
		# Prepare
		docpad = @

		# Check
		if !err or err.logged
			next?()
			return @

		# Log the error only if it hasn't been logged already
		err.logged = true
		err = new Error(err)  unless err instanceof Error
		err.logged = true
		docpad.log(type, 'An error occured:', err.message, err.stack)

		# Report the error back to DocPad using airbrake
		if docpad.config.reportErrors and airbrake
			err.params =
				docpadVersion: @version
				docpadConfig: @config
			airbrake.notify err, (airbrakeErr,airbrakeUrl) ->
				console.log(airbrakeErr)  if airbrakeErr
				console.log('Error has been logged to:', airbrakeUrl)
				next?()
		else
			next?()

		# Chain
		@

	# Handle a warning
	warn: (message,err,next) ->
		# Prepare
		docpad = @

		# Log
		docpad.log('warn', message)
		docpad.error(err, 'warn', next)

		# Chain
		@

	# Perform a growl notification
	notify: (args...) =>
		# Check if we want to use growl
		return @  unless @config.growl

		# Try
		try
			# Load growl
			growl = require('growl')

			# Use growl
			growl.apply(growl,args)

		# Catch
		catch err
			# Ignore

		# Chain
		@


	# =================================
	# Models and Collections

	# Instantiate a File
	createFile: (data={},options={}) ->
		# Prepare
		docpad = @
		options = _.extend(
			outDirPath: @config.outPath
		,options)

		# Create and return
		file = new @FileModel(data,options)

		# Log
		file.on 'log', (args...) ->
			docpad.log(args...)

		# Render
		file.on 'render', (args...) ->
			docpad.emitSync('render', args...)

		# Return
		file

	# Instantiate a Document
	createDocument: (data={},options={}) ->
		# Prepare
		docpad = @
		options = _.extend(
			outDirPath: @config.outPath
		,options)

		# Create and return
		document = new @DocumentModel(data,options)

		# Log
		document.on 'log', (args...) ->
			docpad.log(args...)

		# Fetch a layout
		document.on 'getLayout', (opts,next) ->
			{layoutId} = opts
			layouts = docpad.getCollection('layouts')
			layout = layouts.findOne(id: layoutId)
			layout = layouts.findOne(relativeBase: layoutId)  unless layout
			next(null,{layout})

		# Render
		document.on 'render', (args...) ->
			docpad.emitSync('render', args...)

		# Render document
		document.on 'renderDocument', (args...) ->
			docpad.emitSync('renderDocument', args...)

		# Return
		document

	# Ensure File
	ensureFile: (data={},options={}) ->
		database = @getDatabase()
		result = database.findOne(fullPath: data.fullPath)
		unless result
			result = @createFile(data,options)
			database.add(result)
		result

	# Ensure Document
	ensureDocument: (data={},options={}) ->
		database = @getDatabase()
		result = database.findOne(fullPath: data.fullPath)
		unless result
			result = @createDocument(data,options)
			database.add(result)
		result

	# Ensure File or Document
	ensureFileOrDocument: (data={},options={}) ->
		docpad = @
		database = @getDatabase()
		result = database.findOne(fullPath: data.fullPath)

		# Create result
		unless result
			# Check if we have a document or layout
			for dirPath in docpad.config.documentsPaths.concat(docpad.config.layoutsPaths)
				if fileFullPath.indexOf(dirPath) is 0
					data.relativePath or= fileFullPath.replace(dirPath,'').replace(/^[\/\\]/,'')
					result = @createDocument(data,options)
					break

			# Check if we have a file
			unless result
				for dirPath in docpad.config.filePaths
					if fileFullPath.indexOf(dirPath) is 0
						data.relativePath or= fileFullPath.replace(dirPath,'').replace(/^[\/\\]/,'')
						result = @createFile(data,options)
						break

			# Otherwise, create a file anyway
			unless result
				result = @createFile(data,options)

			# Add result to database
			database.add(result)

		# Return
		result

	# Parse a directory
	# next(err)
	parseDirectory: (opts={},next) ->
		# Prepare
		me = @

		# Extract
		{path,collection,createFunction} = opts

		# Check if the directory exists
		unless pathUtil.existsSync(path)
			# Log
			me.log 'debug', "Skipped directory: #{path} (it does not exist)"

			# Forward
			return next?()

		# Log
		me.log 'debug', "Parsing directory: #{path}"

		# Files
		balUtil.scandir(
			# Path
			path: path

			# Ignore common patterns
			ignorePatterns: true

			# File Action
			fileAction: (fileFullPath,fileRelativePath,nextFile,fileStat) ->
				# Prepare
				data =
					fullPath: fileFullPath
					relativePath: fileRelativePath
				options =
					stat: fileStat

				# Create file
				file = createFunction(data,options)

				# Load the file
				file.load (err) ->
					# Log
					me.log 'debug', "Loading file: #{fileRelativePath}"

					# Check
					if err
						me.warn("Failed to load the file: #{fileRelativePath}. The error follows:", err)
						return nextFile()

					# Prepare
					fileIgnored = file.get('ignored')
					fileParse = file.get('parse')

					# Ignored?
					if fileIgnored or (fileParse? and !fileParse)
						me.log 'info', "Skipped manually ignored file: #{fileRelativePath}"
						return nextFile()
					else
						me.log 'debug', "Loaded file: #{fileRelativePath}"

					# Store Document
					collection.add(file)

					# Forward
					return nextFile()

			# Next
			next: (err) ->
				# Log
				me.log 'debug', "Parsed directory: #{path}"

				# Forward
				return next?(err)
		)

		# Chain
		@


	# =================================
	# Plugins

	# Get a plugin by it's name
	getPlugin: (pluginName) ->
		@loadedPlugins[pluginName]

	# Check if we have any plugins
	hasPlugins: ->
		return _.isEmpty(@loadedPlugins) is false

	# Load Plugins
	loadPlugins: (next) ->
		# Prepare
		docpad = @
		@slowPlugins = {}
		snore = @createSnore ->
			docpad.log 'notice', "We're preparing your plugins, this may take a while the first time. Waiting on the plugins: #{_.keys(docpad.slowPlugins).join(', ')}"

		# Async
		tasks = new balUtil.Group (err) ->
			docpad.slowPlugins = {}
			snore.clear()
			return next?(err)

		# Load website plugins
		_.each @config.pluginsPaths or [], (pluginsPath) =>
			exists = pathUtil.existsSync(pluginsPath)
			if exists
				tasks.push (complete) =>
					@loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		_.each @config.pluginPaths or [], (pluginPath) =>
			exists = pathUtil.existsSync(pluginPath)
			if exists
				tasks.push (complete) =>
					@loadPlugin(pluginPath, complete)

		# Execute the loading asynchronously
		tasks.async()

		# Chain
		@

	# Loaded Plugin
	# Checks if a plugin was loaded succesfully
	# next(err,loaded)
	loadedPlugin: (pluginName,next) ->
		# Prepare
		docpad = @
		# Once loading has finished
		docpad.onceFinished 'loading', (err) ->
			return next(err)  if err
			loaded = docpad.loadedPlugins[pluginName]?
			return next(null,loaded)
		# Chain
		@

	# Load PLugin
	# next(err)
	loadPlugin: (fileFullPath,_next) ->
		# Prepare
		docpad = @
		config = @config
		next = (err) ->
			# Remove from slow plugins
			delete docpad.slowPlugins[pluginName]
			# Forward
			return _next(err)

		# Prepare variables
		loader = new @PluginLoader(
			dirPath: fileFullPath
			docpad: @
			BasePlugin: @BasePlugin
		)
		pluginName = loader.pluginName
		enabled = (
			(config.enableUnlistedPlugins  and  config.enabledPlugins[pluginName]? is false)  or
			config.enabledPlugins[pluginName] is true
		)

		# Check if we already exist
		if docpad.foundPlugins[pluginName]?
			return _next()

		# Add to loading stores
		docpad.slowPlugins[pluginName] = true
		docpad.foundPlugins[pluginName] = true

		# Check
		unless enabled
			# Skip
			docpad.log 'debug', "Skipped plugin: #{pluginName}"
			return next()
		else
			# Load
			docpad.log 'debug', "Loading plugin: #{pluginName}"
			loader.exists (err,exists) ->
				return next(err)  if err or not exists
				loader.unsupported (err,unsupported) ->
					return next(err)  if err
					if unsupported
						if unsupported is 'version' and  docpad.config.skipUnsupportedPlugins is false
							docpad.log 'warn', "Continuing with the unsupported plugin: #{pluginName}"
						else
							if unsupported is 'type'
								docpad.log 'debug', "Skipped the unsupported plugin: #{pluginName} due to #{unsupported}"
							else
								docpad.log 'warn', "Skipped the unsupported plugin: #{pluginName} due to #{unsupported}"
							return next()
					loader.install (err) ->
						return next(err)  if err
						loader.load (err) ->
							return next(err)  if err
							loader.create {}, (err,pluginInstance) ->
								return next(err)  if err
								# Add to plugin stores
								docpad.loadedPlugins[loader.pluginName] = pluginInstance
								# Log completion
								docpad.log 'debug', "Loaded plugin: #{pluginName}"
								# Forward
								return next()

		# Chain
		@

	# Load Plugins
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		docpad = @

		# Load Plugins
		docpad.log 'debug', "Plugins loading for: #{pluginsPath}"
		balUtil.scandir(
			# Path
			path: pluginsPath

			# Ignore common patterns
			ignorePatterns: true

			# Skip files
			fileAction: false

			# Handle directories
			dirAction: (fileFullPath,fileRelativePath,_nextFile) ->
				# Prepare
				pluginName = pathUtil.basename(fileFullPath)
				return _nextFile(null,false)  if fileFullPath is pluginsPath
				nextFile = (err,skip) ->
					if err
						docpad.warn("Failed to load the plugin: #{pluginName} at #{fileFullPath}. The error follows:",err)
					return _nextFile(null,skip)

				# Forward
				docpad.loadPlugin fileFullPath, (err) ->
					return nextFile(err,true)

			# Next
			next: (err) ->
				docpad.log 'debug', "Plugins loaded for: #{pluginsPath}"
				return next?(err)
		)

		# Chain
		@


	# =================================
	# Utilities

	# ---------------------------------
	# Utilities: Misc

	# Create snore
	createSnore: (message) ->
		# Prepare
		docpad = @

		# Create snore object
		snore =
			snoring: false
			timer: setTimeout(
				->
					snore.clear()
					snore.snoring = true
					if _.isFunction(message)
						message()
					else
						docpad.log 'notice', message
				5000
			)
			clear: ->
				if snore.timer
					clearTimeout(snore.timer)
					snore.timer = false

		# Return
		snore


	# Compare current DocPad version to the latest
	compareVersion: ->
		return @  unless @config.checkVersion

		# Prepare
		docpad = @
		notify = @notify

		# Check
		balUtil.packageCompare
			local: pathUtil.join(docpad.corePath, 'package.json')
			remote: 'https://raw.github.com/bevry/docpad/master/package.json'
			newVersionCallback: (details) ->
				docpad.notify "There is a new version of #{details.local.name} available"
				docpad.log 'notice', """
					There is a new version of #{details.local.name} available, you should probably upgrade...
					current version:  #{details.local.version}
					new version:      #{details.remote.version}
					grab it here:     #{details.remote.homepage}
					"""

		# Chain
		@


	# ---------------------------------
	# Utilities: Rendering

	# Get Template Data
	getTemplateData: (userData) ->
		# Prepare
		userData or= {}
		docpad = @

		# Initial merge
		templateData = _.extend({

			# Site Properties
			site: {}

			# Include another file taking in a relative path
			# Will return the contentRendered otherwise content
			include: (subRelativePath) ->
				@documentModel.set({referencesOthers:true})
				fullRelativePath = @document.relativeDirPath+'/'+subRelativePath
				result = docpad.getDatabase().findOne(relativePath: fullRelativePath)
				if result
					return result.get('contentRendered') or result.get('content')
				else
					warn = "The file #{subRelativePath} was not found..."
					docpad.warn(warn)
					return warn

			# Get the database
			getDatabase: ->
				@documentModel.set({referencesOthers:true})
				docpad.getDatabase()

			# Get a pre-defined collection
			getCollection: (name) ->
				@documentModel.set({referencesOthers:true})
				docpad.getCollection(name)

			# Get a block
			getBlock: (name) ->
				docpad.getBlock(name,true)

		}, @config.templateData, userData)

		# Add site data
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if _.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Return
		templateData


	# Render a document
	# next(err,document)
	prepareAndRender: (document,templateData,next) ->
		# Prepare
		docpad = @

		# Contextualize the datbaase, perform two render passes, and perform a write
		balUtil.flow(
			object: document
			action: 'normalize load contextualize render'
			args: [{templateData}]
			next: (err) ->
				return next(err)
		)

		# Chain
		@


	# ---------------------------------
	# Utilities: Exchange

	# Get Exchange
	# Get the exchange data
	# Requires internet access
	# next(err,exchange)
	getExchange: (next) ->
		# Check if it is stored locally
		return next(null,@exchange)  unless _.isEmpty(@exchange)

		# Otherwise fetch it from the exchangeUrl
		@loadConfigUrl @config.exchangeUrl, (err,parsedData) ->
			return next(err)  if err
			@exchange = parsedData
			return next(null,parsedData)

		# Chain
		@


	# ---------------------------------
	# Utilities: Skeletons

	# Get Skeletons
	# Get all the available skeletons for us and their details
	# next(err,skeletons)
	getSkeletons: (next) ->
		@getExchange (err,exchange) ->
			return next(err)  if err
			skeletons = exchange.skeletons
			return next(null,skeletons)
		@

	# Get Skeleton
	# Returns a skeleton's details
	# next(err,skeletonDetails)
	getSkeleton: (skeletonId,next) ->
		@getSkeletons (err,skeletons) ->
			return next(err)  if err
			skeletonDetails = skeletons[skeletonId]
			return next(null,skeletonDetails)
		@

	# Install a Skeleton to a Directory
	# next(err)
	installSkeleton: (skeletonId,destinationPath,next) ->
		# Prepare
		docpad = @
		packagePath = pathUtil.join(destinationPath, 'package.json')

		# Grab the skeletonDetails
		@getSkeleton skeletonId, (err,skeletonDetails) ->
			# Error?
			return docpad.error(err)  if err

			# Configure
			repoConfig =
				gitPath: docpad.config.gitPath
				path: destinationPath
				url: skeletonDetails.repo
				branch: skeletonDetails.branch
				remote: 'skeleton'
				output: docpad.getDebugging()
				next: (err) ->
					# Error?
					return docpad.error(err)  if err

					# Initialise the Website's modules for the first time
					docpad.initNodeModules(
						path: destinationPath
						next: (err) =>
							# Error?
							return docpad.error(err)  if err

							# Done
							return next?()
					)

			# Check if the skeleton path already exists
			balUtil.ensurePath destinationPath, (err) ->
				# Error?
				return docpad.error(err)  if err

				# Initalize the git repository
				balUtil.initGitRepo(repoConfig)

		# Chain
		@



	# ---------------------------------
	# Utilities: Files


	# Contextualize files
	# next(err)
	contextualizeFiles: (opts={},next) ->
		# Prepare
		docpad = @
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', "Contextualizing #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'contextualizeAfter', {collection}, (err) ->
				docpad.log 'debug', "Contextualized #{collection.length} files"
				next()

		# Fetch
		collection.forEach (file) -> tasks.push (complete) ->
			file.contextualize(complete)

		# Start contextualizing
		if tasks.total
			docpad.emitSync 'contextualizeBefore', {collection,templateData}, (err) ->
				return next(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

	# Render files
	# next(err)
	renderFiles: (opts={},next) ->
		# Prepare
		docpad = @
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', "Rendering #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'renderAfter', {collection}, (err) ->
				docpad.log 'debug', "Rendered #{collection.length} files"  unless err
				return next(err)

		# Push the render tasks
		collection.forEach (file) -> tasks.push (complete) ->
			# Skip?
			dynamic = file.get('dynamic')
			render = file.get('render')
			relativePath = file.get('relativePath')

			# Render
			if dynamic or (render? and !render) or !relativePath
				complete()
			else if file.render?
				file.render({templateData},complete)
			else
				complete()

		# Start rendering
		if tasks.total
			docpad.emitSync 'renderBefore', {collection,templateData}, (err) =>
				return next(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

	# Write files
	# next(err)
	writeFiles: (opts={},next) ->
		# Prepare
		docpad = @
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', "Writing #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'writeAfter', {collection}, (err) ->
				docpad.log 'debug', "Wrote #{collection.length} files"  unless err
				return next(err)

		# Cycle
		collection.forEach (file) -> tasks.push (complete) ->
			# Skip
			dynamic = file.get('dynamic')
			write = file.get('write')
			relativePath = file.get('relativePath')

			# Write
			if dynamic or (write? and !write) or !relativePath
				complete()
			else if file.writeRendered?
				file.writeRendered(complete)
			else if file.write?
				file.write(complete)
			else
				complete(new Error('Unknown model in the collection'))

		#  Start writing
		if tasks.total
			docpad.emitSync 'writeBefore', {collection,templateData}, (err) =>
				return next(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@


	# =================================
	# Actions

	# Get the arguments for the action
	# Using this contains the transparency with using opts, and not using opts
	getActionArgs: (opts,next) ->
		if typeof opts is 'function' and next? is false
			next = opts
			opts = {}
		else
			opts or= {}
		next or= opts.next or null
		return {next,opts}

	# Perform an action
	# next(err)
	action: (action,opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)

		# Multiple actions?
		actions = action.split /[,\s]+/g
		if actions.length > 1
			tasks = new balUtil.Group(next)
			tasks.total = actions.length
			for action in actions
				@action action, tasks.completer()
			return @

		# Log
		@log 'debug', "Performing the action #{action}"

		# Handle
		switch action
			when 'install', 'update'
				@install opts, (err) =>
					return @fatal(err)  if err
					return next?()

			when 'skeleton', 'scaffold'
				@skeleton opts, (err) =>
					return @fatal(err)  if err
					return next?()

			when 'generate'
				@generate opts, (err) =>
					return @fatal(err)  if err
					return next?()

			when 'clean'
				@clean opts, (err) =>
					return @fatal(err)  if err
					return next?()

			when 'render'
				@render opts, (err,data) =>
					return @fatal(err)  if err
					return next?(err,data)

			when 'watch'
				@watch opts, (err) =>
					return @fatal(err)  if err
					return next?()

			when 'server'
				@server opts, (err) =>
					return @fatal(err)  if err
					return next?()

			else
				@run opts, (err) =>
					return @fatal(err)  if err
					return next?()

		# Chain
		@



	# ---------------------------------
	# Install

	# Install
	# next(err)
	install: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Re-Initialise the Website's modules
		@initNodeModules(
			path: @config.rootPath
			next: (err) ->
				# Forward on error?
				return next?(err)  if err

				# Re-load configuration
				docpad.loadConfiguration {}, {blocking:false}, (err) ->
					# Forward
					return next?(err)
		)

		# Chain
		@

	# Clean
	# next(err)
	clean: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Log
		docpad.log 'debug', 'Cleaning files'

		# Perform a complete clean of our collections
		docpad.cleanResources()

		# Files
		balUtil.rmdirDeep @config.outPath, (err,list,tree) ->
			docpad.log 'debug', 'Cleaned files'  unless err
			return next?()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Prepare
	generatePrepare: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Block loading
		docpad.block 'loading', (err) ->
			return docpad.fatal(err)  if err

			# Start generating
			docpad.start 'generating', (err) =>
				return docpad.fatal(err)  if err

				# Log generating
				docpad.log 'info', 'Generating...'
				docpad.notify (new Date()).toLocaleTimeString(), title: 'Website generating...'

				# Fire plugins
				docpad.emitSync 'generateBefore', server: docpad.getServer(), (err) ->
					# Forward
					return next(err)

		# Chain
		@

	# Generate Check
	generateCheck: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Check plugin count
		unless docpad.hasPlugins()
			docpad.log 'warn', """
				DocPad is currently running without any plugins installed. You probably want to install some: https://github.com/bevry/docpad/wiki/Plugins
				"""

		# Check if the source directory exists
		pathUtil.exists docpad.config.srcPath, (exists) ->
			# Check and forward
			if exists is false
				err = new Error('Cannot generate website as the src dir was not found')
				return next(err)
			else
				return next()

		# Chain
		@

	# Generate Clean
	generateClean: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Perform a complete clean of our collections
		docpad.cleanResources()

		# Forward
		next()

		# Chain
		@

	# Parse the files
	generateParse: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		database = @getDatabase()
		config = docpad.config

		# Before
		@emitSync 'parseBefore', {}, (err) ->
			return next(err)  if err

			# Log
			docpad.log 'debug', 'Parsing everything'

			# Async
			tasks = new balUtil.Group (err) ->
				return next(err)  if err
				# After
				docpad.emitSync 'parseAfter', {}, (err) ->
					return next(err)  if err
					docpad.log 'debug', 'Parsed everything'
					return next(err)

			# Documents
			_.each config.documentsPaths, (documentsPath) -> tasks.push (complete) ->
				docpad.parseDirectory({
					path: documentsPath
					collection: database
					createFunction: docpad.createDocument
				},complete)

			# Files
			_.each config.filesPaths, (filesPath) -> tasks.push (complete) ->
				docpad.parseDirectory({
					path: filesPath
					collection: database
					createFunction: docpad.createFile
				},complete)

			# Layouts
			_.each config.layoutsPaths, (layoutsPath) -> tasks.push (complete) ->
				docpad.parseDirectory({
					path: layoutsPath
					collection: database
					createFunction: docpad.createDocument
				},complete)

			# Async
			tasks.async()

		# Chain
		@

	# Generate Render
	generateRender: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		templateData = opts.templateData or @getTemplateData()
		collection = opts.collection or @getDatabase()

		# Contextualize the datbaase, perform two render passes, and perform a write
		balUtil.flow(
			object: docpad
			action: 'contextualizeFiles renderFiles renderFiles writeFiles'
			args: [{collection,templateData}]
			next: (err) ->
				return next(err)
		)

		# Chain
		@

	# Generate Postpare
	generatePostpare: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Unblock loading
		docpad.unblock 'loading', (lockError) ->
			return docpad.fatal(lockError)  if lockError

			# Fire plugins
			docpad.emitSync 'generateAfter', server: docpad.getServer(), (err) ->
				return next(err)  if err

				# Finish generating
				docpad.finished 'generating', (lockError) ->
					return docpad.fatal(lockError)  if lockError

					# Log generated
					docpad.log 'info', 'Generated'
					docpad.notify (new Date()).toLocaleTimeString(), title: 'Website generated'

					# Completed
					return next()

		# Chain
		@

	# Generate Error
	# Fired when we have an error occur with generation
	generateError: (err,next) ->
		# Prepare
		docpad = @

		# Unblock kiadubg
		docpad.unblock 'loading', (lockError) ->
			return fatal(lockError)  if lockError

			# Unblock generating
			docpad.finish 'generating', (lockError) ->
				return fatal(lockError)  if lockError

				# Completed
				return next?(err)

		# Chain
		@

	# Date object of the last generate
	lastGenerate: null

	# Generate
	generate: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Re-load and re-render only what is necessary
		if opts.reset? and opts.reset is false
			# Prepare
			docpad.generatePrepare (err) ->
				return docpad.generateError(err,next)  if err

				# Reload changed files
				database = docpad.getDatabase()
				filesToReload = database.findAll(mtime: $gte: docpad.lastGenerate)
				docpad.lastGenerate = new Date()
				filesToReload.load (err) ->
					return docpad.generateError(err,next)  if err

					# Re-render necessary files
					filesToRender = database.findAll(referencesOthers: true).add(filesToReload)
					docpad.generateRender {collection:filesToRender}, (err) ->
						return docpad.generateError(err,next)  if err

						# Finish up
						docpad.generatePostpare {}, (err) ->
							return docpad.generateError(err,next)  if err
							return next?()

		# Re-load and re-render everything
		else
			docpad.lastGenerate = new Date()
			balUtil.flow(
				object: docpad
				action: 'generatePrepare generateCheck generateClean generateParse generateRender generatePostpare'
				args: [opts]
				next: (err) ->
					return docpad.generateError(err,next)  if err
					return next?()
			)

		# Chain
		@


	# ---------------------------------
	# Render

	# Render Action
	render: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @

		# Extract data
		data = opts.data or {}

		# Extract document
		if opts.filename
			document = @createDocument(
				filename: opts.filename
				fullPath: opts.filename
				data: opts.content
			)
			renderFunction = 'prepareAndRender'
		else if opts.document
			document = opts.document
			renderFunction = 'render'

		# Check
		return next? new Error('You must pass a document to the renderAction')  unless document

		# Exits
		fatal = (err) ->
			return docpad.fatal(err,next)
		complete = (err) ->
			docpad.finish 'render', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.unblock 'loading, generating', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err,document)

		# Block loading
		docpad.block 'loading, generating', (lockError) ->
			return fatal(lockError)  if lockError
			docpad.start 'render', (lockError) ->
				return fatal(lockError)  if lockError
				# Render
				docpad[renderFunction](document, data, complete)
				return

		# Chain
		@


	# ---------------------------------
	# Watch

	# Watch
	watch: (opts,next) ->
		# Require
		watchr = require('watchr')

		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		database = @getDatabase()
		srcWatcher = null
		configWatcher = null

		# Close our watchers
		close = ->
			if srcWatcher
				srcWatcher.close()
				srcWatcher = null
			if configWatcher
				configWatcher.close()
				configWatcher = null

		# Restart our watchers
		restart = (next) ->
			# Close our watchers
			close()

			# Start a group
			tasks = new balUtil.Group(next)
			tasks.total = 2

			# Watch the source
			srcWatcher = watchr.watch(
				path: docpad.config.srcPath
				listener: changeHandler
				next: tasks.completer()
				ignorePatterns: true
			)

			# Watch the config
			if pathUtil.existsSync(docpad.config.configPath)
				configWatcher = watchr.watch(
					path: docpad.config.configPath
					listener: ->
						docpad.loadConfiguration {}, {blocking:false}, ->
							changeHandler('config')
					next: tasks.completer()
				)
			else
				tasks.complete()

		# Change event handler
		changeHandler = (eventName,filePath,fileCurrentStat,filePreviousStat) ->
			# Fetch the file
			file = docpad.ensureFileOrDocument({fullPath:filePath})

			# Prepare generate everything else
			performGenerate = (opts={}) ->
				# Do not reset when we do this generate
				opts.reset = false
				# Afterwards, re-render anything that should always re-render
				docpad.generate opts, (err) ->
					docpad.error(err)  if err
					docpad.log "Regenerated at #{new Date().toLocaleTimeString()}"

			# File was deleted, destroy it
			if eventName is 'unlink'
				file.destroy()
				performGenerate()

			# File is new or was changed, update it's mtime by setting the stat
			else if eventName in ['new','change']
				file.setStat(eventName)
				performGenerate()

		# A fatal error occured
		fatal = (err) ->
			docpad.fatal(err,next)

		# Start watching
		watch = ->
			# Block loading
			docpad.block 'loading', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.start 'watching', (lockError) ->
					return fatal(lockError)  if lockError
					docpad.log 'Watching setup starting...'
					restart (err) ->
						docpad.finish 'watching', (lockError) ->
							return fatal(lockError)  if lockError
							docpad.unblock 'loading', (lockError) ->
								return fatal(lockError)  if lockError
								docpad.log 'Watching setup'
								return next?(err)

		# Stop watching if loading starts
		docpad.when 'loading:started', (err) ->
			return fatal(err)  if err
			close()

			# Start watching once loading has finished
			docpad.onceFinished 'loading', (err) ->
				return fatal(err)  if err
				return watch()

		# Stop watching if generating starts
		docpad.whenFinished 'generating:started', (err) ->
			return fatal(err)  if err
			close()

			# Start watching once generating has finished
			docpad.onceFinished 'generating', (err) ->
				return fatal(err)  if err
				return watch()

		# Watch
		watch()

		# Chain
		@


	# ---------------------------------
	# Run Action

	run: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		srcPath = @config.srcPath
		destinationPath = @config.rootPath

		# Run docpad
		runDocpad = =>
			balUtil.flow(
				object: docpad
				action: 'generate server watch'
				args: [opts]
				next: (err) ->
					return docpad.fatal(err)  if err
					return next?()
			)

		# Check if we have the docpad structure
		if pathUtil.existsSync(srcPath)
			# We have the correct structure, so let's proceed with DocPad
			runDocpad()
		else
			# We don't have the correct structure
			# Check if we are running on an empty directory
			fsUtil.readdir destinationPath, (err,files) =>
				return fatal(err)  if err

				# Check if our directory is empty
				if files.length
					# It isn't empty, display a warning
					docpad.log 'warn', """

						We couldn't find an existing DocPad project inside your current directory.
						If you're wanting to use a pre-made skeleton for the basis of your new project, then run DocPad again inside an empty directory.
						If you're wanting to start your new project from scratch, then refer to the Getting Started guide here:
							https://github.com/bevry/docpad/wiki/Getting-Started
						For more information on what this means, visit:
							https://github.com/bevry/docpad/wiki/Troubleshooting
						"""
					return next?()
				else
					@skeletonAction opts, (err) =>
						return @fatal(err)  if err
						runDocpad()

		# Chain
		@


	# ---------------------------------
	# Skeleton

	# Skeleton
	skeleton: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		skeletonId = @config.skeleton
		srcPath = @config.srcPath
		destinationPath = @config.rootPath
		selectSkeletonCallback = opts.selectSkeletonCallback or null

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.finish 'skeleton', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.unblock 'generating, watching, serving', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)
		useSkeleton = ->
			# Install Skeleton
			docpad.installSkeleton skeletonId, destinationPath, (err) ->
				return complete(err)  if err
				# Re-load configuration
				docpad.loadConfiguration {}, {blocking:false}, (err) ->
					# Forward
					return complete(err)

		# Block loading
		docpad.block 'generating, watching, serving', (lockError) ->
			return fatal(lockError)  if lockError

			# Start the skeleton process
			docpad.start 'skeleton', (lockError) ->
				return fatal(lockError)  if lockError

				# Check if already exists
				pathUtil.exists srcPath, (exists) ->
					# Check
					if exists
						docpad.log 'warn', "Didn't place the skeleton as the desired structure already exists"
						return complete()

					# Do we already have a skeletonId selected?
					if skeletonId
						useSkeleton()
					else
						# Get the available skeletons
						docpad.getSkeletons (err,skeletons) ->
							# Check
							return complete(err)  if err
							# Provide selection to the interface
							selectSkeletonCallback skeletons, (err,_skeletonId) ->
								return fatal(err)  if err
								skeletonId = _skeletonId
								useSkeleton()

		# Chain
		@


	# ---------------------------------
	# Server

	# Server
	server: (opts,next) ->
		# Require
		express = require('express')

		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		config = @config

		# Exists
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			# Finish
			docpad.finish 'serving', (lockError) ->
				return fatal(lockError)  if lockError
				# Unblock
				docpad.unblock 'loading', (err) ->
					return fatal(lockError)  if lockError
					return next?(err)

		# Block loading
		docpad.block 'loading', (lockError) ->
			return fatal(lockError)  if lockError
			docpad.start 'serving', (lockError) ->
				return fatal(lockError)  if lockError
				# Plugins
				docpad.emitSync 'serverBefore', {}, (err) ->
					return next?(err)  if err

					# Server
					server = docpad.getServer()
					unless server
						server = express.createServer()
						docpad.setServer(server)

					# Extend the server
					if config.extendServer
						# Configure the server
						server.configure ->
							# POST Middleware
							server.use express.bodyParser()
							server.use express.methodOverride()

							# DocPad Header
							server.use (req,res,next) ->
								tools = res.header('X-Powered-By').split /[,\s]+/g
								tools.push 'DocPad'
								tools = tools.join(',')
								res.header('X-Powered-By',tools)
								next()

							# Router Middleware
							server.use server.router

							# Routing
							server.use (req,res,next) ->
								# Check
								database = docpad.getDatabase()
								return next?()  unless database

								# Prepare
								cleanUrl = req.url.replace(/\?.*/,'')
								document = database.findOne(urls: '$in': cleanUrl)
								return next?()  unless document

								# Fetch
								contentTypeRendered = document.get('contentTypeRendered')
								url = document.get('url')
								dynamic = document.get('dynamic')
								contentRendered = document.get('contentRendered')

								# Content Type
								if contentTypeRendered
									res.contentType(contentTypeRendered)

								# Send
								if dynamic
									templateData = docpad.getTemplateData(req:req)
									document.render {templateData}, (err) ->
										contentRendered = document.get('contentRendered')
										if err
											docpad.error(err)
											return res.send(err.message, 500)
										else
											return res.send(contentRendered)
								else
									if contentRendered
										return res.send(contentRendered)
									else
										return next?()

							# Static
							if config.maxAge
								server.use(express.static config.outPath, maxAge: config.maxAge)
							else
								server.use(express.static config.outPath)

							# 404 Middleware
							server.use (req,res,next) ->
								return res.send(404)

						# Start the server
						result = server.listen config.port
						try
							address = server.address()
							serverHostname = if address.address is '0.0.0.0' then 'localhost' else address.address
							serverPort = address.port
							serverLocation = "http://#{serverHostname}:#{serverPort}/"
							serverDir = config.outPath
							docpad.log 'info', "DocPad listening to #{serverLocation} on directory #{serverDir}"
						catch err
							docpad.log 'err', "Could not start the web server, chances are the desired port #{config.port} is already in use"

					# Plugins
					docpad.emitSync 'serverAfter', {server}, (err) ->
						return complete(err)  if err
						# Complete
						docpad.log 'debug', 'Server setup'  unless err
						return complete()

		# Chain
		@


# =====================================
# Export

# Export API
module.exports =
	DocPad: DocPad
	createInstance: (config,next) ->
		return new DocPad(config,next)
