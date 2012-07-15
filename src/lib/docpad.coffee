# =====================================
# Requires

# Necessary
pathUtil = require('path')
_ = require('underscore')
caterpillar = require('caterpillar')
CSON = require('cson')
balUtil = require('bal-util')
{EventEmitterEnhanced} = balUtil

# Optional
airbrake = null
growl = null

# Base
{queryEngine,Backbone,Events,Model,Collection,View,QueryCollection} = require(__dirname+'/base')

# Models
FileModel = require(__dirname+'/models/file')
DocumentModel = require(__dirname+'/models/document')

# Collections
FilesCollection = require(__dirname+'/collections/files')
ElementsCollection = require(__dirname+'/collections/elements')
MetaCollection = require(__dirname+'/collections/meta')
ScriptsCollection = require(__dirname+'/collections/scripts')
StylesCollection = require(__dirname+'/collections/styles')

# Plugins
PluginLoader = require(__dirname+'/plugin-loader')
BasePlugin = require(__dirname+'/plugin')

# Prototypes
require(__dirname+'/prototypes')


# =====================================
# DocPad

###
The DocPad Class
It extends the EventSystem from bal-util to provide system events
It allows us to support multiple instances of docpad at the same time
###
class DocPad extends EventEmitterEnhanced

	# =================================
	# Variables

	# ---------------------------------
	# Modules

	# Base
	Events: Events
	Model: Model
	Collection: Collection
	View: View
	QueryCollection: QueryCollection

	# Models
	FileModel: FileModel
	DocumentModel: DocumentModel

	# Collections
	FilesCollection: FilesCollection
	ElementsCollection: ElementsCollection
	MetaCollection: MetaCollection
	ScriptsCollection: ScriptsCollection
	StylesCollection: StylesCollection

	# Plugins
	PluginLoader: PluginLoader
	BasePlugin: BasePlugin


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

	# The runner instance bound to docpad
	runnerInstance: null
	getRunner: ->
		@runnerInstance

	# Event Listing
	# Whenever a event is created, it must be applied here to be available to plugins and configuration files
	# https://github.com/bevry/docpad/wiki/Events
	events: [
		'docpadReady'
		'extendTemplateData'
		'extendCollections'
		'consoleSetup'
		'generateBefore'
		'generateAfter'
		'parseBefore'
		'parseAfter'
		'renderBefore'
		'render'
		'renderDocument'
		'renderAfter'
		'writeBefore'
		'writeAfter'
		'serverBefore'
		'serverExtend'
		'serverAfter'
	]
	getEvents: ->
		@events

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
	# Collection Helpers

	# Get Files (will use live collections)
	getFiles: (query,sorting,paging) ->
		key = JSON.stringify({query,sorting,paging})
		result = @getCollection(key)
		unless result
			result = @getDatabase().findAllLive(query,sorting,paging)
			@setCollection(key, result)
		return result

	# Get another file's model based on a relative path
	getFile: (query,sorting,paging) ->
		result = @getDatabase().findOne(query,sorting,paging)
		return result

	# Get Files At Path
	getFilesAtPath: (path,sorting,paging) ->
		query = $or: [{relativePath: $startsWith: path}, {fullPath: $startsWith: path}]
		result = @getFiles(query,sorting,paging)
		return result

	# Get another file's model based on a relative path
	getFileAtPath: (path,sorting,paging) ->
		query = $or: [{relativePath: path}, {fullPath: path}]
		result = @getDatabase().findOne(query,sorting,paging)
		return result


	# ---------------------------------
	# Skeletons

	# Skeletons Collection
	skeletonsCollection: null

	# Get Skeletons
	# Get all the available skeletons for us and their details
	# next(err,skeletonsCollection)
	getSkeletons: (next) ->
		# Prepare
		docpad = @

		# Check if we have cached locally
		if @skeletonsCollection?
			return next(null,@skeletonsCollection)

		# Fetch the skeletons from the exchange
		@skeletonsCollection = new Collection()
		@skeletonsCollection.comparator = queryEngine.generateComparator(position:1, name:1)
		@getExchange (err,exchange) ->
			return next(err)  if err
			# Add options
			index = 0
			for own skeletonKey,skeleton of exchange.skeletons
				skeleton.id ?= skeletonKey
				skeleton.name ?= skeletonKey
				skeleton.position ?= index
				docpad.skeletonsCollection.add(new Model(skeleton))
				++index
			# Add No Skeleton Option
			docpad.skeletonsCollection.add(new Model(
				id: 'none'
				name: 'No Skeleton'
				description: 'Prefer to start from scratch? You can get started without any skeleton if you wish'
				position: Infinity
			))
			# Return Collection
			return next(null,docpad.skeletonsCollection)
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
	corePath: pathUtil.join(__dirname, '..', '..')

	# The DocPad library directory
	libPath: __dirname

	# The main DocPad file
	mainPath: pathUtil.join(__dirname, 'docpad')

	# The DocPad package.json path
	packagePath: pathUtil.join(__dirname, '..', '..', 'package.json')


	# -----------------------------
	# Template Data

	# DocPad's Template Data
	initialTemplateData: null  # {}

	# Plugin's Extended Template Data
	pluginsTemplateData: null  # {}

	# Get Complete Template Data
	getTemplateData: (userTemplateData) ->
		# Prepare
		userTemplateData or= {}
		docpad = @

		# Set the initial docpad template data
		@initialTemplateData ?=
			# Site Properties
			site: {}

			# Set that we reference other files
			referencesOthers: (flag) ->
				document = @getDocument()
				document.referencesOthers()
				return null

			# Get the Document
			getDocument: ->
				return @documentModel

			# Get a Path in respect to the current document
			getPath: (path,parentPath) ->
				document = @getDocument()
				path = document.getPath(path,parentPath)
				return path

			# Get Files
			getFiles: (query,sorting,paging) ->
				@referencesOthers()
				result = docpad.getFiles(query,sorting,paging)
				return result

			# Get another file's URL based on a relative path
			getFile: (query,sorting,paging) ->
				@referencesOthers()
				result = docpad.getFile(query,sorting,paging)
				return result

			# Get Files At Path
			getFilesAtPath: (path,sorting,paging) ->
				@referencesOthers()
				path = @getPath(path)
				result = docpad.getFilesAtPath(path,sorting,paging)
				return result

			# Get another file's model based on a relative path
			getFileAtPath: (relativePath) ->
				@referencesOthers()
				path = @getPath(relativePath)
				result = docpad.getFileAtPath(path)
				return result

			# Get the entire database
			getDatabase: ->
				@referencesOthers()
				return docpad.getDatabase()

			# Get a pre-defined collection
			getCollection: (name) ->
				@referencesOthers()
				return docpad.getCollection(name)

			# Get a block
			getBlock: (name) ->
				return docpad.getBlock(name,true)

			# Include another file taking in a relative path
			# Will return the contentRendered otherwise content
			include: (subRelativePath) ->
				result = @getFileAtPath(subRelativePath)
				if result
					return result.get('contentRendered') or result.get('content')
				else
					err = new Error("Could not include the file at path [#{subRelativePath}] as we could not find it")
					throw err

		# Fetch our result template data
		templateData = balUtil.extend({}, @initialTemplateData, @pluginsTemplateData, @config.templateData, userTemplateData)

		# Add site data
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if _.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Return
		templateData


	# -----------------------------
	# Configuration

	# Merged Configuration
	# Merged in the order of:
	# - initialConfig
	# - websitePackageConfig
	# - websiteConfig
	# - instanceConfig
	# - environmentConfig
	config: null  # {}

	# Instance Configuration
	instanceConfig: null  # {}

	# Website Configuration
	websiteConfig: null  # {}

	# Website Package Configuration
	websitePackageConfig: null  # {}

	# Initial Configuration
	initialConfig:

		# -----------------------------
		# Plugins

		# Force re-install of all plugin dependencies
		force: false

		# Whether or not we should enable plugins that have not been listed or not
		enableUnlistedPlugins: true

		# Plugins which should be enabled or not pluginName: pluginEnabled
		enabledPlugins: {}

		# Whether or not we should skip unsupported plugins
		skipUnsupportedPlugins: true

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: {}

		# Where to fetch the exchange information from
		exchangeUrl: 'https://raw.github.com/bevry/docpad-extras/docpad-6.x/exchange.json'


		# -----------------------------
		# Website Paths

		# The website directory
		rootPath: process.cwd()

		# The website's package.json path
		packagePath: 'package.json'

		# The website's configuration paths
		# Reads only the first one that exists
		# If you want to read multiple configuration paths, then point it to a coffee|js file that requires
		# the other paths you want and exports the merged config
		configPaths: [
			'docpad.js'
			'docpad.coffee'
			'docpad.json'
			'docpad.cson'
		]

		# The website's out directory
		outPath: 'out'

		# The website's src directory
		srcPath: 'src'

		# The website's documents directories
		# relative to the srcPath
		documentsPaths: [
			'documents'
		]

		# The website's files directories
		# relative to the srcPath
		filesPaths: [
			'files'
			'public'
		]

		# The website's layouts directory
		# relative to the srcPath
		layoutsPaths: [
			'layouts'
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
		port: process.env.PORT ? 9778

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

		# Catch uncaught exceptions
		catchExceptions: true


		# -----------------------------
		# Other

		# Welcome
		# Whether or not to display the welcome message
		welcome: true

		# NPM Path
		# The location of our npm executable
		npmPath: null

		# Node Path
		# The location of our node executable
		nodePath: null

		# Git Path
		# The location of our git executable
		gitPath: null

		# Safe Mode
		# If enabled, we will try our best to sandbox our template rendering so that they cannot modify things outside of them
		# Not yet implemented
		safeMode: false

		# Template Data
		# What data would you like to expose to your templates
		templateData: {}

		# Report Errors
		# Whether or not we should report our errors back to DocPad
		reportErrors: true

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: true

		# Collections
		# A hash of functions that create collections
		collections: {}

		# Events
		# A hash of event handlers
		events: {}


		# -----------------------------
		# Environment Configuration

		# Environment
		# Whether or not we are in production or development
		# Separate environments using a comma or a space
		env: process.env.NODE_ENV or 'development'

		# Environments
		# Environment specific configuration to over-ride the global configuration
		environments:
			production:
				checkVersion: false
				maxAge: 86400000


	# Get Environment
	getEnvironment: ->
		return @config.env

	# Get Environments
	getEnvironments: ->
		return @getEnvironment().split(/[, ]+/)

	# Get the Configuration
	getConfig: ->
		return @config

	# Resolve the Configuration
	# next(err,config)
	resolveConfig: (instanceConfig,next) ->
		# Prepare
		docpad = @
		instanceConfig or= {}

		# Reset configurations
		@websitePackageConfig = {}
		@websiteConfig = {}
		@config = {}

		# Merge in the instance configurations
		balUtil.extend(@instanceConfig,instanceConfig)

		# Prepare the Load Tasks
		preTasks = new balUtil.Group (err) =>
			return next(err)  if err

			# Get environments
			@config.env = @instanceConfig.env or @websiteConfig.env or @websitePackageConfig.env or @initialConfig.env
			envs = @getEnvironments()

			# Merge configurations
			configPackages = [@initialConfig, @websitePackageConfig, @websiteConfig, @instanceConfig]
			configsToMerge = [@config]
			for configPackage in configPackages
				configsToMerge.push(configPackage)
				for env in envs
					envConfig = configPackage.environments?[env]
					configsToMerge.push(envConfig)  if envConfig
			balUtil.deepExtendPlainObjects(configsToMerge...)
			console.log(@config.env, envs, @instanceConfig,instanceConfig)

			# Extract and apply the server
			@setServer(@config.server)  if @config.server

			# Extract and apply the logger
			@setLogger(@config.logger)  if @config.logger
			@setLogLevel(@config.logLevel)

			# Resolve any paths
			@config.rootPath = pathUtil.resolve(@config.rootPath)
			@config.outPath = pathUtil.resolve(@config.rootPath, @config.outPath)
			@config.srcPath = pathUtil.resolve(@config.rootPath, @config.srcPath)

			# Resolve Documents, Files, Layouts paths
			for type in ['documents','files','layouts']
				typePaths = @config[type+'Paths']
				for typePath,key in typePaths
					typePaths[key] = pathUtil.resolve(@config.srcPath,typePath)

			# Resolve Plugins paths
			for type in ['plugins']
				typePaths = @config[type+'Paths']
				for typePath,key in typePaths
					typePaths[key] = pathUtil.resolve(@config.rootPath,typePath)

			# Prepare the Post Tasks
			postTasks = new balUtil.Group (err) =>
				return next(err,@config)

			# Get the git path
			unless @config.gitPath?
				postTasks.push (complete) =>
					balUtil.getGitPath (err,gitPath) =>
						return docpad.error(err)  if err
						@config.gitPath = gitPath
						complete()

			# Get the node path
			unless @config.nodePath?
				postTasks.push (complete) =>
					balUtil.getNodePath (err,nodePath) =>
						return docpad.error(err)  if err
						@config.nodePath = nodePath
						complete()

			# Load collections
			postTasks.push (complete) ->
				docpad.loadCollections(complete)

			# Initialize
			postTasks.push (complete) ->
				docpad.loadPlugins(complete)

			# Fetch plugins templateData
			postTasks.push (complete) ->
				docpad.emitSync 'extendTemplateData', {templateData:docpad.pluginsTemplateData,extend:balUtil.extend}, (err) ->
					# Forward
					return complete(err)

			# Fire post tasks
			postTasks.sync()

		# Load DocPad's Package Configuration
		preTasks.push (complete) =>
			@loadConfigPath @packagePath, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Version
				@version = data.version
				airbrake.appVersion = data.version  if airbrake

				# Done loading
				complete()

		# Load Website's Package Configuration
		preTasks.push (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			websitePackagePath = pathUtil.resolve(rootPath, @instanceConfig.packagePath or @initialConfig.packagePath)
			@loadConfigPath websitePackagePath, (err,data) =>
				return complete(err)  if err
				data or= {}
				data.docpad or= {}

				# Apply loaded data
				balUtil.extend(@websitePackageConfig, data.docpad)

				# Done loading
				complete()

		# Load Website's Configuration
		preTasks.push (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @websitePackageConfig.rootPath or @initialConfig.rootPath)
			configPaths = @instanceConfig.configPaths or @websitePackageConfig.configPaths or @initialConfig.configPaths
			for configPath, index in configPaths
				configPaths[index] = pathUtil.resolve(rootPath, configPath)
			@loadConfigPaths configPaths, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				balUtil.extend(@websiteConfig, data)

				# Done loading
				complete()

		# Run the load tasks synchronously
		preTasks.sync()

		# Chain
		@


	# =================================
	# Initialization Functions

	# Construct DocPad
	# next(err)
	constructor: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @

		# Ensure certain functions always have the scope of this instance
		_.bindAll(@, 'createDocument', 'createFile')

		# Allow DocPad to have unlimited event listeners
		@setMaxListeners(0)

		# Setup configuration event wrappers
		configEventContext = {docpad}  # here to allow the config event context to persist between event calls
		_.each @getEvents(), (eventName) ->
			# Bind to the event
			docpad.on eventName, (opts,next) ->
				eventHandler = docpad.getConfig().events?[eventName]
				# Fire the config event handler for this event, if it exists
				if balUtil.isFunction(eventHandler)
					args = [opts,next]
					balUtil.fireWithOptionalCallback(eventHandler,args,configEventContext)
				# It doesn't exist, so lets continue
				else
					next()

		# Create our runner
		@runnerInstance = new balUtil.Group 'sync', (err) ->
			# Error?
			return docpad.error(err)  if err
		@runnerInstance.total = Infinity

		# Initialize a default logger
		logger = new caterpillar.Logger(
			transports:
				formatter: module: module
		)
		@setLogger(logger)
		@setLogLevel(6)

		# Log to bubbled events
		@on 'log', (args...) ->
			docpad.log.apply(@,args)

		# Dereference and initialise advanced variables
		# we deliberately ommit initialTemplateData here, as it is setup in getTemplateData
		@slowPlugins = {}
		@foundPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@collections = {}
		@blocks = {}
		@pluginsTemplateData = {}
		@instanceConfig = {}
		@initialConfig = balUtil.dereference(@initialConfig)

		# Initialize the collections
		@database = new FilesCollection()

		# Apply and load configuration
		@action 'load', instanceConfig, (err,config) =>
			# Error?
			return @fatal(err)  if err

			# Bind the error handler, so we don't crash on errors
			if config.catchExceptions
				process.setMaxListeners(0)
				process.on 'uncaughtException', (err) ->
					docpad.error(err)

			# Standard Collections
			documentsCollection = @database.createLiveChildCollection()
				.setQuery('isDocument', {
					$or:
						isDocument: true
						fullPath: $startsWith: config.documentsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding document: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isDocument: true
						render: true
						write: true
					})
				)
			filesCollection = @database.createLiveChildCollection()
				.setQuery('isFile', {
					$or:
						isFile: true
						fullPath: $startsWith: config.filesPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding file: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isFile: true
						render: false
						write: true
					})
				)
			layoutsCollection = @database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isLayout: true
						fullPath: $startsWith: config.layoutsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding layout: #{model.attributes.fullPath}")
					_.defaults(model.attributes,{
						isLayout: true
						render: false
						write: false
					})
				)

			# Special Collections
			htmlCollection = @database.createLiveChildCollection()
				.setQuery('isHTML', {
					$or:
						isDocument: true
						isFile: true
					outPath: $endsWith: '.html'
				})
				.on('add', (model) ->
					docpad.log('debug', "Adding html file: #{model.attributes.fullPath}")
				)

			# Apply collections
			@setCollection('documents',documentsCollection)
			@setCollection('files',filesCollection)
			@setCollection('layouts',layoutsCollection)
			@setCollection('html',htmlCollection)


			# Blocks
			metaBlock = new MetaCollection()
			scriptsBlock = new ScriptsCollection()
			stylesBlock = new StylesCollection()

			# Apply Blocks
			@setBlock('meta', metaBlock)
			@setBlock('scripts', scriptsBlock)
			@setBlock('styles', stylesBlock)


			# Load Airbrake if we want to reportErrors
			if config.reportErrors and /win/.test(process.platform) is false
				try
					airbrake = require('airbrake').createClient('e7374dd1c5a346efe3895b9b0c1c0325')
				catch err
					airbrake = false


			# Version Check
			@compareVersion()


			# Log
			if @config.welcome
				@log 'debug', "Welcome to DocPad v#{@getVersion()}"
				@log 'debug', 'Environment:', @getEnvironment()
				@log 'debug', 'Plugins:', _.keys(@loadedPlugins).sort().join(', ')


			# Ready
			@emitSync 'docpadReady', {docpad}, (err) ->
				# Error?
				return docpad.error(err)  if err

				# All done, forward our DocPad instance onto our creator
				return next?(null,docpad)


	# =================================
	# Configuration

	# Clean Resources
	# next(err)
	cleanResources: (next) ->
		# Perform a complete clean of our collections
		@getDatabase().reset([])
		@getBlock('meta').reset([]).add([
			'<meta http-equiv="X-Powered-By" content="DocPad"/>'
		])
		@getBlock('scripts').reset([])
		@getBlock('styles').reset([])

		# Perform any plugin extensions to what we just cleaned
		@emitSync('extendCollections',{},next)

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
	# next(err,parsedData)
	loadConfigPath: (configPath,next) ->
		# Log
		@log 'debug', "Loading configuration path: #{configPath}"

		# Check that it exists
		balUtil.exists configPath, (exists) ->
			return next(null,null)  unless exists
			# Read the path using CSON
			CSON.parseFile(configPath, next)

		# Chain
		@

	# Load a series of configuration paths
	# next(err,parsedData)
	loadConfigPaths: (configPaths,next) ->
		# Prepare
		docpad = @
		result = {}

		# Ensure array
		configPaths = [configPaths]  unless _.isArray(configPaths)

		# Group
		tasks = new balUtil.Group (err) ->
			return next(err,result)

		# Read our files
		# On the first file that returns a result, exit
		_.each configPaths, (configPath) ->
			tasks.push (complete) ->
				docpad.loadConfigPath configPath, (err,config) ->
					return complete(err)  if err
					if config
						result = config
						tasks.exit()
					else
						complete()

		# Run them synchronously
		tasks.sync()

		# Chain
		@

	# Load collections
	loadCollections: (next) ->
		# Prepare
		docpad = @
		database = @getDatabase()
		@config.collections or= {}

		# Group
		tasks = new balUtil.Group (err) ->
			docpad.error(err)  if err
			return next()

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

	# Init Git Repo
	# next(err,results)
	initGitRepo: (opts) ->
		# Prepare
		opts.gitPath ?= @config.gitPath

		# Forward
		balUtil.initGitRepo(opts)

		# Chain
		@

	# Init Node Modules
	# next(err,results)
	initNodeModules: (opts={}) ->
		# Prepare
		opts.npmPath ?= @config.npmPath
		opts.nodePath ?= @config.nodePath
		opts.force ?= @config.force
		opts.output ?= @getDebugging()

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
		docpad = @
		return @  unless err
		@error err, 'err', ->
			if docpad.config.catchExceptions
				process.exit(-1)
			else
				throw err
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
			growl = require('growl')  unless growl?

			# Use growl
			growl.apply(growl,args)  if growl

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
		options = balUtil.extend(
			outDirPath: @config.outPath
		,options)

		# Create and return
		file = new FileModel(data,options)

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
		options = balUtil.extend(
			outDirPath: @config.outPath
		,options)

		# Create and return
		document = new DocumentModel(data,options)

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
		fileFullPath = data.fullPath
		result = database.findOne(fullPath: fileFullPath)

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
		{path,createFunction} = opts
		filesToLoad = new FilesCollection()

		# Check if the directory exists
		unless balUtil.existsSync(path)
			# Log
			me.log 'debug', "Skipped directory: #{path} (it does not exist)"

			# Forward
			return next()

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
				filesToLoad.add(file)

				# Next
				nextFile()

			# Next
			next: (err) ->
				# Check
				return next(err)  if err

				# Log
				me.log 'debug', "Parsed directory: #{path}"

				# Load the files
				me.loadFiles {collection:filesToLoad}, (err) ->
					# Forward
					return next(err)
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
			return next(err)

		# Load website plugins
		_.each @config.pluginsPaths or [], (pluginsPath) =>
			exists = balUtil.existsSync(pluginsPath)
			if exists
				tasks.push (complete) =>
					@loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		_.each @config.pluginPaths or [], (pluginPath) =>
			exists = balUtil.existsSync(pluginPath)
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

		# Check
		loaded = docpad.loadedPlugins[pluginName]?
		next(null,loaded)

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
		loader = new PluginLoader(
			dirPath: fileFullPath
			docpad: @
			BasePlugin: BasePlugin
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
			
			# Check if it exists
			loader.exists (err,exists) ->
				# Error or doesn't exist?
				return next(err)  if err or not exists
				
				# Check if it is supported
				loader.unsupported (err,unsupported) ->
					# Error?
					return next(err)  if err
					
					# Unsupported?
					if unsupported
						# Version?
						if unsupported is 'version' and  docpad.config.skipUnsupportedPlugins is false
							docpad.log 'warn', "Continuing with the unsupported plugin: #{pluginName}"
						else
							# Type?
							if unsupported is 'type'
								docpad.log 'debug', "Skipped the unsupported plugin: #{pluginName} due to #{unsupported}"
							
							# Something else?
							else
								docpad.log 'warn', "Skipped the unsupported plugin: #{pluginName} due to #{unsupported}"
							return next()
					
					# It is supported, install its deps
					loader.install (err) ->
						return next(err)  if err
						
						# It is now installed, load it
						loader.load (err) ->
							return next(err)  if err
							
							# It is loaded, create it
							loader.create {}, (err,pluginInstance) ->
								return next(err)  if err
								
								# Enabled?
								if pluginInstance.isEnabled() is false
									docpad.log 'info', "Skipped the disabled plugin: #{pluginName}"
									return next()
								
								# Add to plugin stores
								console.log(loader.pluginName,pluginInstance.config,docpad.getEnvironments())
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
				return next(err)
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

	# Install a Skeleton to a Directory
	# next(err)
	installSkeleton: (skeletonModel,destinationPath,next) ->
		# Prepare
		docpad = @
		packagePath = pathUtil.join(destinationPath, 'package.json')

		# Configure
		repoConfig =
			path: destinationPath
			url: skeletonModel.get('repo')
			branch: skeletonModel.get('branch')
			remote: 'skeleton'
			output: true
			next: (err) ->
				# Error?
				return docpad.error(err)  if err

				# Initialise the Website's modules for the first time
				docpad.initNodeModules(
					path: destinationPath
					output: true
					next: (err) ->
						# Error?
						return docpad.error(err)  if err

						# Done
						return next()
				)

		# Check if the skeleton path already exists
		balUtil.ensurePath destinationPath, (err) ->
			# Error?
			return docpad.error(err)  if err

			# Initalize the git repository
			docpad.initGitRepo(repoConfig)

		# Chain
		@



	# ---------------------------------
	# Utilities: Files


	# Loading files
	# next(err)
	loadFiles: (opts={},next) ->
		# Prepare
		docpad = @
		database = @getDatabase()
		{collection} = opts

		# Log
		docpad.log 'debug', "Loading #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'loadAfter', {collection}, (err) ->
				docpad.log 'debug', "Loaded #{collection.length} files"
				next()

		# Fetch
		collection.forEach (file) -> tasks.push (complete) ->
			# Prepare
			fileRelativePath = file.get('relativePath')

			# Log
			docpad.log 'debug', "Loading file: #{fileRelativePath}"

			# Load the file
			file.load (err) ->
				# Check
				if err
					docpad.warn("Failed to load the file: #{fileRelativePath}. The error follows:", err)
					return complete()

				# Prepare
				fileIgnored = file.get('ignored')
				fileParse = file.get('parse')

				# Ignored?
				if fileIgnored or (fileParse? and !fileParse)
					docpad.log 'info', "Skipped manually ignored file: #{fileRelativePath}"
					collection.remove(file)
					return complete()
				else
					docpad.log 'debug', "Loaded file: #{fileRelativePath}"

				# Store Document
				database.add(file)

				# Forward
				return complete()

		# Start contextualizing
		if tasks.total
			docpad.emitSync 'loadBefore', {collection}, (err) ->
				return next(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

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
				return next(err)  if err
				docpad.log 'debug', "Contextualized #{collection.length} files"
				return next()

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
				return next(err)  if err
				docpad.log 'debug', "Rendered #{collection.length} files"
				return next()

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
				return next(err)  if err
				docpad.log 'debug', "Wrote #{collection.length} files"
				return next()

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

	# Perform an action
	# next(err,...), ... = any special arguments from the action
	action: (action,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		runner = @getRunner()

		# Multiple actions?
		actions = action.split /[,\s]+/g
		if actions.length > 1
			tasks = new balUtil.Group (err) ->
				return next(err)
			_.each actions, (action) -> tasks.push (complete) ->
				docpad.action(action,opts,complete)
			tasks.sync()
			return docpad

		# Log
		@log 'debug', "Performing the action #{action}"

		# Next
		next ?= (err) ->
			docpad.fatal(err)  if err

		# Wrap
		runner.pushAndRun (complete) ->
			# Handle
			switch action
				when 'install', 'update'
					docpad.install opts, (args...) ->
						next(args...)
						complete()

				when 'skeleton', 'scaffold'
					docpad.skeleton opts, (args...) ->
						next(args...)
						complete()

				when 'load'
					docpad.load opts, (args...) ->
						next(args...)
						complete()

				when 'generate'
					docpad.generate opts, (args...) ->
						next(args...)
						complete()

				when 'clean'
					docpad.clean opts, (args...) ->
						next(args...)
						complete()

				when 'render'
					docpad.render opts, (args...) ->
						next(args...)
						complete()

				when 'watch'
					docpad.watch opts, (args...) ->
						next(args...)
						complete()

				when 'server'
					docpad.server opts, (args...) ->
						next(args...)
						complete()

				else
					docpad.run opts, (args...) ->
						next(args...)
						complete()

		# Chain
		@


	# ---------------------------------
	# Setup and Loading

	# Load Configuration
	# next(err,config)
	load: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Resolve the configuration
		@resolveConfig(opts,next)

		# Chain
		@

	# Install
	# next(err)
	install: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Re-Initialise the Website's modules
		@initNodeModules(
			path: @config.rootPath
			output: true
			next: (err) ->
				# Forward on error?
				return next(err)  if err

				# Re-load configuration
				docpad.load (err) ->
					# Forward
					return next(err)
		)

		# Chain
		@

	# Clean
	# next(err)
	clean: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		{rootPath,outPath} = @config

		# Log
		docpad.log 'debug', 'Cleaning files'

		# Clean collections
		docpad.cleanResources (err) ->
			# Check
			return next(err)  if err

			# Clean files
			# but only if our outPath is not a parent of our rootPath
			if rootPath.indexOf(outPath) is -1
				# our outPath is higher than our root path, so do not remove files
				return next()
			else
				# our outPath is not related or lower than our root path, so do remove it
				balUtil.rmdirDeep @config.outPath, (err,list,tree) ->
					docpad.log 'debug', 'Cleaned files'  unless err
					return next()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Prepare
	# next(err)
	generatePrepare: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

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
	# next(err)
	generateCheck: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Check plugin count
		unless docpad.hasPlugins()
			docpad.log 'warn', """
				DocPad is currently running without any plugins installed. You probably want to install some: https://github.com/bevry/docpad/wiki/Plugins
				"""

		# Check if the source directory exists
		balUtil.exists docpad.config.srcPath, (exists) ->
			# Check and forward
			if exists is false
				err = new Error('Cannot generate website as the src dir was not found')
				return next(err)
			else
				return next()

		# Chain
		@

	# Generate Clean
	# next(err)
	generateClean: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Perform a complete clean of our collections
		docpad.cleanResources(next)

		# Chain
		@

	# Parse the files
	# next(err)
	generateParse: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
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
	# next(err)
	generateRender: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
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
	# next(err)
	generatePostpare: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Fire plugins
		docpad.emitSync 'generateAfter', server: docpad.getServer(), (err) ->
			return next(err)  if err

			# Log generated
			if opts.count?
				docpad.log 'info', "Generated #{opts.count} files"
			else
				docpad.log 'info', "Generated all files"
			docpad.notify (new Date()).toLocaleTimeString(), title: 'Website generated'

			# Completed
			return next()

		# Chain
		@

	# Date object of the last generate
	lastGenerate: null

	# Generate
	# next(err)
	generate: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		docpad.lastGenerate ?= new Date('1970')

		# Re-load and re-render only what is necessary
		if opts.reset? and opts.reset is false
			# Prepare
			docpad.generatePrepare (err) ->
				return next(err)  if err
				database = docpad.getDatabase()

				# Create a colelction for the files to reload
				filesToReload = opts.filesToReload or new FilesCollection()
				# Add anything which was modified since our last generate
				filesToReload.add(database.findAll(mtime: $gte: docpad.lastGenerate).models)

				# Update our generate time
				docpad.lastGenerate = new Date()

				# Perform the reload of the selected files
				docpad.loadFiles {collection:filesToReload}, (err) ->
					return next(err)  if err

					# Create a collection for the files to render
					filesToRender = opts.filesToRender or new FilesCollection()
					# For anything that gets added, if it is a layout, then add that layouts children too
					filesToRender.on 'add', (fileToRender) ->
						if fileToRender.get('isLayout')
							filesToRender.add(database.findAll(layout: fileToRender.id).models)
					# Add anything that references other documents (e.g. partials, listing, etc)
					filesToRender.add(database.findAll(referencesOthers: true).models)
					# Add anything that was re-loaded
					filesToRender.add(filesToReload.models)

					# Perform the re-render of the selected files
					docpad.generateRender {collection:filesToRender}, (err) ->
						return next(err)  if err

						# Finish up
						docpad.generatePostpare {count:filesToRender.length}, (err) ->
							return next(err)

		# Re-load and re-render everything
		else
			docpad.lastGenerate = new Date()
			balUtil.flow(
				object: docpad
				action: 'generatePrepare generateCheck generateClean generateParse generateRender generatePostpare'
				args: [opts]
				next: (err) ->
					return next(err)
			)

		# Chain
		@


	# ---------------------------------
	# Render

	# Load and Render a Document
	# next(err,document)
	loadAndRenderDocument: (document,opts,next) ->
		balUtil.flow(
			object: document
			action: 'load contextualize render'
			args: [opts]
			next: (err) ->
				result = document.get('contentRendered')
				return next(err,result,document)
		)
		@

	# Render Document
	# next(err,result)
	renderDocument: (document,opts,next) ->
		document.render(opts,next)
		@

	# Render Path
	# next(err,result)
	renderPath: (path,opts,next) ->
		document = @ensureDocument(
			fullPath: path
		)
		@loadAndRenderDocument(document,opts,next)
		@

	# Render Data
	# next(err,result)
	renderData: (content,opts,next) ->
		document = @createDocument(
			filename: opts.filename
			data: content
		)
		@loadAndRenderDocument(document,opts,next)
		@

	# Render Text
	# next(err,result)
	renderText: (text,opts,next) ->
		document = @createDocument(
			filename: opts.filename
			data: text
			body: text
			content: text
		)
		opts.actions ?= ['renderExtensions','renderDocument']
		balUtil.flow(
			object: document
			action: 'normalize contextualize render'
			args: [opts]
			next: (err) ->
				result = document.get('contentRendered')
				return next(err,result,document)
		)
		@

	# Render Action
	# next(err,document,result)
	render: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)

		# Extract document
		if opts.document
			@renderDocument(opts.document, opts, next)
		else if opts.data
			@renderData(opts.data, opts, next)
		else if opts.text
			@renderText(opts.text, opts, next)
		else
			path = opts.path or opts.fullPath or opts.filename or null
			if path
				@renderPath(path, opts, next)
			else
				# Check
				err = new Error('Invalid options passed to the render action')
				return next(err)

		# Chain
		@


	# ---------------------------------
	# Watch

	# Watch
	watch: (opts,next) ->
		# Require
		watchr = require('watchr')

		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		database = @getDatabase()
		watchrs = []

		# Close our watchers
		closeWatchers = ->
			for watchr in watchrs
				watchr.close()
				watchr = null
			watchrs = []

		# Restart our watchers
		resetWatchers = (next) ->
			# Close our watchers
			closeWatchers()

			# Start a group
			tasks = new balUtil.Group(next)
			tasks.total = 2

			# Watch the config
			watchrs = watchr.watch(
				paths: docpad.config.configPaths
				listener: ->
					docpad.log 'info', "Configuration change detected at #{new Date().toLocaleTimeString()}"
					docpad.action 'load', (err) ->
						return docpad.fatal(err)  if err
						performGenerate(reset:true)
				next: tasks.completer()
			)

			# Watch the source
			watchrs.push watchr.watch(
				path: docpad.config.srcPath
				listener: changeHandler
				next: tasks.completer()
				ignorePatterns: true
			)

		# Timer
		regenerateTimer = null
		regenerateDelay = 100
		queueRegeneration = ->
			# Reset the wait
			if regenerateTimer
				clearTimeout(regenerateTimer)
				regenerateTimer = null
			# Regenerat after a while
			regenerateTimer = setTimeout(performGenerate, regenerateDelay)
		performGenerate = (opts) ->
			# Prepare
			opts or= {}
			# Do not reset when we do this generate
			opts.reset ?= false
			# Log
			docpad.log "Regenerating at #{new Date().toLocaleTimeString()}"
			# Afterwards, re-render anything that should always re-render
			docpad.action 'generate', opts, (err) ->
				docpad.error(err)  if err
				docpad.log "Regenerated at #{new Date().toLocaleTimeString()}"

		# Change event handler
		changeHandler = (eventName,filePath,fileCurrentStat,filePreviousStat) ->
			# Fetch the file
			docpad.log 'debug', "Change detected at #{new Date().toLocaleTimeString()}", eventName, filePath

			# Check if we are a file we don't care about
			if ( balUtil.commonIgnorePatterns.test(pathUtil.basename(filePath)) )
				docpad.log 'debug', "Ignored change at #{new Date().toLocaleTimeString()}", filePath
				return

			# Don't care if we are a directory
			if (fileCurrentStat or filePreviousStat).isDirectory()
				docpad.log 'debug', "Directory change at #{new Date().toLocaleTimeString()}", filePath
				return

			# Create the file object
			file = docpad.ensureFileOrDocument({fullPath:filePath})

			# File was deleted, delete the rendered file, and remove it from the database
			if eventName is 'unlink'
				database.remove(file)
				queueRegeneration()
				file.delete (err) ->
					return docpad.error(err)  if err

			# File is new or was changed, update it's mtime by setting the stat
			else if eventName in ['new','change']
				file.setStat(fileCurrentStat)
				queueRegeneration()

		# Watch
		docpad.log 'Watching setup starting...'
		resetWatchers (err) ->
			docpad.log 'Watching setup'
			return next(err)

		# Chain
		@


	# ---------------------------------
	# Run Action

	run: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		srcPath = @config.srcPath
		destinationPath = @config.rootPath

		# Run docpad
		runDocpad = ->
			balUtil.flow(
				object: docpad
				action: 'generate server watch'
				args: [opts]
				next: (err) ->
					return next(err)
			)

		# Check if we have the docpad structure
		if balUtil.existsSync(srcPath)
			# We have the correct structure, so let's proceed with DocPad
			runDocpad()
		else
			# We don't have the correct structure
			# Check if we are running on an empty directory
			balUtil.readdir destinationPath, (err,files) ->
				return next(err)  if err

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
					return next()
				else
					docpad.skeleton opts, (err) ->
						return next(err)  if err
						runDocpad()

		# Chain
		@


	# ---------------------------------
	# Skeleton

	# Skeleton
	skeleton: (opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		skeletonId = @config.skeleton
		srcPath = @config.srcPath
		destinationPath = @config.rootPath
		selectSkeletonCallback = opts.selectSkeletonCallback or null

		# Use a Skeleton
		useSkeleton = (skeletonModel) ->
			# Log
			docpad.log 'info', "Installing the #{skeletonModel.get('name')} skeleton into #{destinationPath}"

			# Install Skeleton
			docpad.installSkeleton skeletonModel, destinationPath, (err) ->
				# Error?
				return next(err)  if err

				# Re-load configuration
				docpad.load (err) ->
					# Error?
					return next(err)  if err

					# Log
					docpad.log 'info', "Installed the skeleton succesfully"

					# Forward
					return next(err)

		# Use No Skeleton
		useNoSkeleton = ->
			# Create the paths
			balUtil.ensurePath srcPath, (err) ->
				# Error?
				return next(err)  if err

				# Group
				tasks = new balUtil.Group(next)
				tasks.total = 3

				# Create
				balUtil.ensurePath(docpad.config.documentsPaths[0], tasks.completer())

				# Create
				balUtil.ensurePath(docpad.config.layoutsPaths[0], tasks.completer())

				# Create
				balUtil.ensurePath(docpad.config.filesPaths[0], tasks.completer())

		# Check if already exists
		balUtil.exists srcPath, (exists) ->
			# Check
			if exists
				docpad.log 'warn', "Didn't place the skeleton as the desired structure already exists"
				return next()

			# Do we already have a skeletonId selected?
			if skeletonId
				useSkeleton()
			else
				# Get the available skeletons
				docpad.getSkeletons (err,skeletonsCollection) ->
					# Check
					return next(err)  if err
					# Provide selection to the interface
					selectSkeletonCallback skeletonsCollection, (err,skeletonModel) ->
						return next(err)  if err
						if skeletonModel? is false or skeletonModel.id is 'none'
							useNoSkeleton()
						else
							useSkeleton(skeletonModel)

		# Chain
		@


	# ---------------------------------
	# Server

	# Server
	server: (opts,next) ->
		# Require
		express = require('express')

		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		config = @config
		server = null

		# Handlers
		complete = (err) ->
			return next(err)  if err
			# Plugins
			docpad.emitSync 'serverAfter', {server}, (err) ->
				return next(err)  if err
				# Complete
				docpad.log 'debug', 'Server setup'
				return next()
		startServer = ->
			# Start the server
			try
				server.listen(config.port)
				address = server.address()
				unless address?
					throw new Error("Could not start the web server, chances are the desired port #{config.port} is already in use")
				serverHostname = if address.address is '0.0.0.0' then 'localhost' else address.address
				serverPort = address.port
				serverLocation = "http://#{serverHostname}:#{serverPort}/"
				serverDir = config.outPath
				docpad.log 'info', "DocPad listening to #{serverLocation} on directory #{serverDir}"
				complete()
			catch err
				complete(err)

		# Plugins
		docpad.emitSync 'serverBefore', {}, (err) ->
			return complete(err)  if err

			# Server
			server = docpad.getServer()
			unless server
				server = express.createServer()
				docpad.setServer(server)

			# Extend the server
			unless config.extendServer
				# Start the Server
				startServer()
			else
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

					# Emit the serverExtend event
					# So plugins can define their routes earlier than the DocPad routes
					docpad.emitSync 'serverExtend', {server}, (err) ->
						return next(err)  if err

						# Router Middleware
						server.use server.router

						# Routing
						server.use (req,res,next) ->
							# Check
							database = docpad.getDatabase()
							return next()  unless database

							# Prepare
							pageUrl = req.url.replace(/\?.*/,'')
							document = database.findOne(urls: $has: pageUrl)
							return next()  unless document

							# Check if we are the desired url
							# if we aren't do a permanent redirect
							url = document.get('url')
							if url isnt pageUrl
								return res.redirect(url,301)

							# Fetch
							contentTypeRendered = document.get('contentTypeRendered')
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
									return next()

						# Static
						if config.maxAge
							server.use(express.static config.outPath, maxAge: config.maxAge)
						else
							server.use(express.static config.outPath)

						# 404 Middleware
						server.use (req,res,next) ->
							return res.send(404)

				# Start the Server
				startServer()


		# Chain
		@


# =====================================
# Export

# Export
module.exports =
	# Modules
	DocPad: DocPad
	queryEngine: queryEngine
	Backbone: Backbone

	# Create Instance
	# Wrapper for creating a DocPad instance
	# good for future compatibility in case the API changes
	createInstance: (args...) ->
		return new DocPad(args...)
