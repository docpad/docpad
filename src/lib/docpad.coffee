# =====================================
# Requires

# Profile
if ('--profile' in process.argv)
	try
		agent = require('webkit-devtools-agent')
	catch err
		console.log('no profiling')

# Necessary
pathUtil = require('path')
_ = require('underscore')
caterpillar = require('caterpillar')
CSON = require('cson')
balUtil = require('bal-util')
util = require('util')
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

	# The express and http server instances bound to docpad
	serverExpress: null
	serverHttp: null
	getServer: (both) ->
		{serverExpress,serverHttp} = @
		if both
			return {serverExpress,serverHttp}
		else
			return serverExpress
	setServer: (servers) ->
		@serverExpress = servers.serverExpress
		@serverHttp = servers.serverHttp

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
		'extendTemplateData'
		'extendCollections'
		'docpadLoaded'
		'docpadReady'
		'consoleSetup'
		'generateBefore'
		'populateCollections'
		'generateAfter'
		'parseBefore'
		'parseAfter'
		'contextualizeBefore'
		'contextualizeAfter'
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
		locale = @getLocale()

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
				name: locale.skeletonNoneName
				description: locale.skeletonNoneDescription
				position: Infinity
			))
			# Return Collection
			return next(null,docpad.skeletonsCollection)
		@


	# ---------------------------------
	# Plugins

	# Plugins that are loading really slow
	slowPlugins: null  # {}

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

	# The User's configuration path
	userConfigPath: '.docpad.cson'


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
					locale = @getLocale()
					err = new Error(util.format(locale.includeFailed, subRelativePath))
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

	# Locales Configuration
	locales:
		en: CSON.parseFileSync(pathUtil.join(__dirname, '..', '..', 'locale', 'en.cson'))


	# Merged Configuration
	# Merged in the order of:
	# - initialConfig
	# - userConfig
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

	# User Configuraiton
	userConfig:
		# Name
		name: null

		# Email
		email: null

		# Username
		username: null

		# Subscribed
		subscribed: null

		# Subcribe Try Again
		# If our subscription has failed, when should we try again?
		subscribeTryAgain: null

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
		exchangeUrl: 'https://docpad.org/exchange.json'


		# -----------------------------
		# Website Paths

		# The website directory
		rootPath: process.cwd()

		# The website's package.json path
		packagePath: 'package.json'

		# Where to get the latest package information from
		latestPackageUrl: 'https://docpad.org/latest.json'

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
		pluginsPaths: [
			'node_modules',
			'plugins'
		]

		# Ignored files patterns during directory parsing
		# Default to balUtil.commonIgnorePatterns
		ignorePatterns: true


		# -----------------------------
		# Server

		# Server
		# The Express.js server that we want docpad to use
		serverExpress: null
		# The HTTP server that we want docpad to use
		serverHttp: null

		# Extend Server
		# Whether or not we should extend the server with extra middleware and routing
		extendServer: true

		# Port
		# The port that the server should use
		# PORT - Heroku, Nodejitsu, Custom
		# VCAP_APP_PORT - AppFog
		# VMC_APP_PORT - CloudFoundry
		port: null

		# Max Age
		# The caching time limit that is sent to the client
		maxAge: 86400000

		# Which middlewares would you like us to activate
		# The standard middlewares (bodePArser, methodOverride, express router)
		middlewareStandard: true
		# The standard bodyParser middleware
		middlewareBodyParser: true
		# The standard methodOverride middleware
		middlewareMethodOverride: true
		# The standard express router middleware
		middlewareExpressRouter: true
		# Our own 404 middleware
		middleware404: true
		# Our own 500 middleware
		middleware500: true


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

		# Report Errors
		# Whether or not we should report our errors back to DocPad
		reportErrors: true

		# Airbrake Token
		airbrakeToken: 'e7374dd1c5a346efe3895b9b0c1c0325'


		# -----------------------------
		# Other

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: false

		# Welcome
		# Whether or not we should display any custom welcome callbacks
		welcome: false

		# Prompts
		# Whether or not we should display any prompts
		prompts: false

		# Helper Url
		# Used for subscribing to newsletter, account information, and statistics etc
		helperUrl: 'https://docpad.org/helper/'

		# Safe Mode
		# If enabled, we will try our best to sandbox our template rendering so that they cannot modify things outside of them
		# Not yet implemented
		safeMode: false

		# Template Data
		# What data would you like to expose to your templates
		templateData: {}

		# Collections
		# A hash of functions that create collections
		collections: {}

		# Events
		# A hash of event handlers
		events: {}

		# Regenerate Every
		# Performs a rengeraete every x milliseconds, useful for always having the latest data
		regenerateEvery: false


		# -----------------------------
		# Environment Configuration

		# Environment
		# Whether or not we are in production or development
		# Separate environments using a comma or a space
		env: null

		# Environments
		# Environment specific configuration to over-ride the global configuration
		environments:
			development:
				# Always refresh from server
				maxAge: false

				# Only do these if we are running standalone (aka not included in a module)
				checkVersion: process.argv.length >= 2 and /docpad$/.test(process.argv[1])
				welcome: process.argv.length >= 2 and /docpad$/.test(process.argv[1])
				prompts: process.argv.length >= 2 and /docpad$/.test(process.argv[1])


	# Regenerate Timer
	# When config.regenerateEvery is set to a value, we create a timer here
	regenerateTimer: null

	# Get Locale
	getLocale: ->
		return @locales.en

	# Get Environment
	getEnvironment: ->
		return @getConfig().env

	# Get Environments
	getEnvironments: ->
		return @getEnvironment().split(/[, ]+/)

	# Get the Configuration
	getConfig: ->
		return @config or {}


	# =================================
	# Initialization Functions

	# Construct DocPad
	# next(err)
	constructor: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @

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
		@loadedPlugins = {}
		@exchange = {}
		@pluginsTemplateData = {}
		@instanceConfig = {}
		@locales = balUtil.dereference(@locales)
		@userConfig = balUtil.dereference(@userConfig)
		@initialConfig = balUtil.dereference(@initialConfig)

		# Check if we want to perform the initial configuration load automatically
		if instanceConfig.load is false
			next?(null,docpad)
		else
			@action 'load ready', instanceConfig, (err) ->
				return docpad.fatal(err)  if err
				next?(null,docpad)

		# Chain
		@


	# ---------------------------------
	# Setup and Loading

	# Ready
	# next(err,docpadInstance)
	ready: (opts,next) =>
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()

		# Version Check
		@compareVersion()

		# Welcome prepare
		if @getDebugging()
			pluginsList = ("#{pluginName} v#{@loadedPlugins[pluginName].version}"  for pluginName in _.keys(@loadedPlugins).sort()).join(', ')
		else
			pluginsList = _.keys(@loadedPlugins).sort().join(', ')

		# Welcome log
		@log 'info', util.format(locale.welcome, "v#{@getVersion()}")
		@log 'info', util.format(locale.welcomePlugins, pluginsList)
		@log 'info', util.format(locale.welcomeEnvironment, @getEnvironment())

		# Prepare
		tasks = new balUtil.Group (err) ->
			# Error?
			return docpad.error(err)  if err
			# All done, forward our DocPad instance onto our creator
			return next?(null,docpad)

		# Welcome
		tasks.push (complete) =>
			return complete()  unless docpad.config.welcome
			@emitSync('welcome', {docpad}, complete)

		# DocPad Ready
		tasks.push (complete) =>
			@emitSync('docpadReady', {docpad}, complete)

		# Run tasks
		tasks.sync()

		# Chain
		@

	# Load Configuration
	# next(err,config)
	load: (instanceConfig,next) =>
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()
		instanceConfig or= {}

		# Reset non persistant configurations
		@websitePackageConfig = {}
		@websiteConfig = {}
		@config = {}

		# Merge in the instance configurations
		balUtil.extend(@instanceConfig,instanceConfig)

		# Prepare the Load Tasks
		preTasks = new balUtil.Group (err) =>
			return next(err)  if err

			# Get environments
			@initialConfig.port ?= process.env.PORT ? process.env.VCAP_APP_PORT ? process.env.VMC_APP_PORT ? 9778
			@initialConfig.env or= process.env.NODE_ENV or 'development'
			@config.env = @instanceConfig.env or @websiteConfig.env or @websitePackageConfig.env or @initialConfig.env
			envs = @getEnvironments()

			# Merge configurations
			configPackages = [@initialConfig, @userConfig, @websitePackageConfig, @websiteConfig, @instanceConfig]
			configsToMerge = [@config]
			for configPackage in configPackages
				configsToMerge.push(configPackage)
				for env in envs
					envConfig = configPackage.environments?[env]
					configsToMerge.push(envConfig)  if envConfig
			balUtil.deepExtendPlainObjects(configsToMerge...)

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

			# Bind the error handler, so we don't crash on errors
			if @config.catchExceptions
				process.setMaxListeners(0)
				process.on('uncaughtException', @error)
			else
				process.removeListener('uncaughtException', @error)

			# Load Airbrake if we want to reportErrors
			if @config.reportErrors and /win/.test(process.platform) is false
				try
					airbrake = require('airbrake').createClient(@config.airbrakeToken)
				catch err
					airbrake = false

			# Regenerate Timer
			if @regenerateTimer
				clearInterval(@regenerateTimer)
				@regenerateTimer = null
			if @config.regenerateEvery
				@regenerateTimer = setInterval(
					->
						docpad.log('info', locale.renderInterval)
						docpad.action('generate')
					@config.regenerateEvery
				)

			# Prepare the Post Tasks
			postTasks = new balUtil.Group (err) =>
				return next(err,@config)

			# Initialize
			postTasks.push (complete) =>
				@loadPlugins(complete)

			# Load collections
			postTasks.push (complete) =>
				@createCollections(complete)

			# Fetch plugins templateData
			postTasks.push (complete) =>
				@emitSync('extendTemplateData', {templateData:@pluginsTemplateData}, complete)

			# Fire the docpadLoaded event
			postTasks.push (complete) =>
				@emitSync('docpadLoaded', {}, complete)

			# Fire post tasks
			postTasks.sync()

		# Normalize the userConfigPath
		preTasks.push (complete) =>
			balUtil.getHomePath (err,homePath) =>
				return complete(err)  if err
				dropboxPath = pathUtil.join(homePath,'Dropbox')
				balUtil.exists dropboxPath, (dropboxPathExists) =>
					userConfigDirPath = if dropboxPathExists then dropboxPath else homePath
					@userConfigPath = pathUtil.join(userConfigDirPath, @userConfigPath)
					complete()

		# Load User's Configuration
		preTasks.push (complete) =>
			@loadConfigPath @userConfigPath, (err,data) =>
				return complete(err)  if err

				# Apply loaded data
				balUtil.extend(@userConfig, data or {})

				# Done loading
				complete()

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

		# Read the .env file if it exists
		preTasks.push (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @websitePackageConfig.rootPath or @initialConfig.rootPath)
			envPath = pathUtil.join(rootPath, '.env')
			balUtil.exists envPath, (exists) ->
				return complete()  unless exists
				balUtil.readFile envPath, (err,data) ->
					return complete(err)  if err
					result = data.toString()
					lines = result.split('\n')
					for line in lines
						match = line.match(/^([^=]+?)=(.*)/)
						if match
							key = match[1]
							value = match[2]
							process.env[key] = value
					return complete()

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

	# Install
	# next(err)
	install: (opts,next) =>
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
	clean: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		{rootPath,outPath} = @config

		# Log
		docpad.log 'debug', locale.renderCleaning

		# Clean collections
		docpad.resetCollections (err) ->
			# Check
			return next(err)  if err

			# Clean files
			# but only if our outPath is not a parent of our rootPath
			if rootPath.indexOf(outPath) isnt -1
				# our outPath is higher than our root path, so do not remove files
				return next()
			else
				# our outPath is not related or lower than our root path, so do remove it
				balUtil.rmdirDeep outPath, (err,list,tree) ->
					docpad.log('debug', locale.renderCleaned)  unless err
					return next()

		# Chain
		@


	# =================================
	# Configuration

	# Update User Configuration
	updateUserConfig: (data,next) ->
		# Prepare
		[data,next] = balUtil.extractOptsAndCallback(data,next)
		docpad = @
		userConfigPath = @userConfigPath

		# Apply back to our loaded configuration
		# does not apply to @config as we would have to reparse everything
		# and that appears to be an imaginary problem
		balUtil.extend(@userConfig,data)  if data

		# Write it with CSON
		CSON.stringify @userConfig, (err,userConfigString) ->
			# Check
			return next(err)  if err

			# Write it
			balUtil.writeFile userConfigPath, userConfigString, 'utf8', (err) ->
				# Forward
				return next(err)

		# Chain
		@

	# Load a configuration url
	# next(err,parsedData)
	loadConfigUrl: (configUrl,next) ->
		# Prepare
		locale = @getLocale()
		request = require('request')

		# Log
		@log 'debug', util.format(locale.loadingConfigUrl, configUrl)

		# Read the URL
		request configUrl, (err,res,body) ->
			# Check
			return next(err)  if err

			# Read the string using CSON
			CSON.parse(body,next)

		# Chain
		@

	# Load a configuration file
	# next(err,parsedData)
	loadConfigPath: (configPath,next) ->
		# Prepare
		locale = @getLocale()

		# Log
		@log 'debug', util.format(locale.loadingConfigPath, configPath)

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

	# Create Collections
	# next(err)
	createCollections: (next) ->
		# Prepare
		docpad = @
		config = @config
		locale = @getLocale()
		@database = database = new FilesCollection()
		@collections = {}
		@blocks = {}
		config.collections or= {}

		# Standard Collections
		documentsCollection = database.createLiveChildCollection()
			.setQuery('isDocument', {
				$or:
					isDocument: true
					fullPath: $startsWith: config.documentsPaths
			})
			.on('add', (model) ->
				docpad.log('debug', util.format(locale.addingDocument, model.attributes.fullPath))
				_.defaults(model.attributes,{
					isDocument: true
					render: true
					write: true
				})
			)
		filesCollection = database.createLiveChildCollection()
			.setQuery('isFile', {
				$or:
					isFile: true
					fullPath: $startsWith: config.filesPaths
			})
			.on('add', (model) ->
				docpad.log('debug', util.format(locale.addingFile, model.attributes.fullPath))
				_.defaults(model.attributes,{
					isFile: true
					render: false
					write: true
				})
			)
		layoutsCollection = database.createLiveChildCollection()
			.setQuery('isLayout', {
				$or:
					isLayout: true
					fullPath: $startsWith: config.layoutsPaths
			})
			.on('add', (model) ->
				docpad.log('debug', util.format(locale.addingLayout, model.attributes.fullPath))
				_.defaults(model.attributes,{
					isLayout: true
					render: false
					write: false
				})
			)

		# Special Collections
		htmlCollection = database.createLiveChildCollection()
			.setQuery('isHTML', {
				$or:
					isDocument: true
					isFile: true
				outExtension: 'html'
			})
			.on('add', (model) ->
				docpad.log('debug', util.format(locale.addingHtml, model.attributes.fullPath))
			)
		stylesheetCollection = database.createLiveChildCollection()
			.setQuery('isStylesheet', {
				$or:
					isDocument: true
					isFile: true
				outExtension: $in: [
					'css',
					'scss', 'sass',
					'styl', 'stylus'
					'less'
				]
			})
			.on('add', (model) ->
				docpad.log('debug', util.format(locale.addingStylesheet, model.attributes.fullPath))
				model.attributes.referencesOthers = true
			)

		# Apply collections
		@setCollection('documents', documentsCollection)
		@setCollection('files', filesCollection)
		@setCollection('layouts', layoutsCollection)
		@setCollection('html', htmlCollection)
		@setCollection('stylesheets', stylesheetCollection)

		# Blocks
		metaBlock = new MetaCollection()
		scriptsBlock = new ScriptsCollection()
		stylesBlock = new StylesCollection()

		# Apply Blocks
		@setBlock('meta', metaBlock)
		@setBlock('scripts', scriptsBlock)
		@setBlock('styles', stylesBlock)

		# Custom Collections Group
		tasks = new balUtil.Group (err) ->
			docpad.error(err)  if err
			docpad.emitSync('extendCollections',{},next)

		# Cycle through Custom Collections
		_.each @config.collections, (fn,name) ->
			tasks.push (complete) ->
				if fn.length is 2 # callback
					fn.call docpad, database, (err,collection) ->
						docpad.error(err)  if err
						if collection
							collection.live(true)  # make it a live collection
							docpad.setCollection(name,collection)  # apply the collection
						complete()
				else
					collection = fn.call(docpad,database)
					if collection
						collection.live(true)  # make it a live collection
						docpad.setCollection(name,collection)  # apply the collection
					complete()

		# Run Custom collections
		tasks.async()

		# Chain
		@

	# Reset Collections
	# next(err)
	resetCollections: (next) ->
		# Perform a complete clean of our collections
		@getDatabase().reset([])
		@getBlock('meta').reset([]).add([
			'<meta http-equiv="X-Powered-By" content="DocPad"/>'
		])
		@getBlock('scripts').reset([])
		@getBlock('styles').reset([])

		# Perform any plugin extensions to what we just cleaned
		# and forward
		@emitSync('populateCollections',{},next)

		# Chain
		@

	# Init Git Repo
	# next(err,results)
	initGitRepo: (opts) ->
		# Forward
		balUtil.initGitRepo(opts)

		# Chain
		@

	# Init Node Modules
	# next(err,results)
	initNodeModules: (opts={}) ->
		# Prepare
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
	fatal: (err) =>
		docpad = @
		return @  unless err
		@error err, 'err', ->
			if docpad.config.catchExceptions
				process.exit(-1)
			else
				throw err
		@

	# Log
	log: (args...) =>
		logger = @getLogger()
		logger.log.apply(logger,args)
		@

	# Handle an error
	error: (err,type='err',next) =>
		# Prepare
		docpad = @
		locale = @getLocale()

		# Check
		if !err or err.logged
			next?()
			return @

		# Log the error only if it hasn't been logged already
		err.logged = true
		err = new Error(err)  unless err instanceof Error
		err.logged = true
		docpad.log(type, locale.errorOccured, err.message, err.stack)

		# Report the error back to DocPad using airbrake
		if docpad.config.reportErrors and airbrake
			err.params =
				docpadVersion: @version
				docpadConfig: @config
			airbrake.notify err, (airbrakeErr,airbrakeUrl) ->
				console.log(airbrakeErr)  if airbrakeErr
				console.log(util.format(locale.errorLoggedTo, airbrakeUrl))
				next?()
		else
			next?()

		# Chain
		@

	# Handle a warning
	warn: (message,err,next) =>
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
	createFile: (data={},options={}) =>
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
	createDocument: (data={},options={}) =>
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
			layout = layouts.findOne(relativePath: layoutId)  unless layout
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
	ensureFile: (data={},options={}) =>
		database = @getDatabase()
		result = database.findOne(fullPath: data.fullPath)
		unless result
			result = @createFile(data,options)
			database.add(result)
		result

	# Ensure Document
	ensureDocument: (data={},options={}) =>
		database = @getDatabase()
		result = database.findOne(fullPath: data.fullPath)
		unless result
			result = @createDocument(data,options)
			database.add(result)
		result

	# Ensure File or Document
	ensureFileOrDocument: (data={},options={}) =>
		docpad = @
		database = @getDatabase()
		fileFullPath = data.fullPath or null
		result = database.findOne(fullPath: fileFullPath)

		# Create result
		unless result
			# If we have a file path to compare
			if fileFullPath
				# Check if we have a document or layout
				for dirPath in docpad.config.documentsPaths.concat(docpad.config.layoutsPaths)
					if fileFullPath.indexOf(dirPath) is 0
						data.relativePath or= fileFullPath.replace(dirPath,'').replace(/^[\/\\]/,'')
						result = @createDocument(data,options)
						break

				# Check if we have a file
				unless result
					for dirPath in docpad.config.filesPaths
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
		docpad = @
		locale = @getLocale()

		# Extract
		{path,createFunction} = opts
		filesToLoad = new FilesCollection()

		# Check if the directory exists
		unless balUtil.existsSync(path)
			# Log
			docpad.log 'debug', util.format(locale.renderDirectoryNonexistant, path)

			# Forward
			return next()

		# Log
		docpad.log 'debug', util.format(locale.renderDirectoryParsing, path)

		# Files
		balUtil.scandir(
			# Path
			path: path

			# Ignore patterns
			ignorePatterns: docpad.config.ignorePatterns

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
				docpad.log 'debug', util.format(locale.renderDirectoryParsed, path)

				# Load the files
				docpad.loadFiles {collection:filesToLoad}, (err) ->
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
		locale = @getLocale()

		# Snore
		@slowPlugins = {}
		snore = @createSnore ->
			docpad.log 'notice', util.format(locale.pluginsSlow, _.keys(docpad.slowPlugins).join(', '))

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
		locale = @getLocale()
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

		# If we've already been loaded, then exit early as there is no use for us to load again
		if docpad.loadedPlugins[pluginName]?
			return _next()

		# Add to loading stores
		docpad.slowPlugins[pluginName] = true

		# Check
		unless enabled
			# Skip
			docpad.log 'debug', util.format(locale.pluginSkipped, pluginName)
			return next()
		else
			# Load
			docpad.log 'debug', util.format(locale.pluginLoading, pluginName)

			# Check existance
			loader.exists (err,exists) ->
				# Error or doesn't exist?
				return next(err)  if err or not exists

				# Check support
				loader.unsupported (err,unsupported) ->
					# Error?
					return next(err)  if err

					# Unsupported?
					if unsupported
						# Version?
						if unsupported is 'version' and  docpad.config.skipUnsupportedPlugins is false
							docpad.log 'warn', util.format(locale.pluginContinued, pluginName)
						else
							# Type?
							if unsupported is 'type'
								docpad.log 'debug', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)

							# Something else?
							else
								docpad.log 'warn', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)
							return next()

					# Load the class
					loader.load (err) ->
						return next(err)  if err

						# Create an instance
						loader.create {}, (err,pluginInstance) ->
							return next(err)  if err

							# Add to plugin stores
							docpad.loadedPlugins[loader.pluginName] = pluginInstance

							# Log completion
							docpad.log 'debug', util.format(locale.pluginLoaded, pluginName)

							# Forward
							return next()

		# Chain
		@

	# Load Plugins
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Load Plugins
		docpad.log 'debug', util.format(locale.pluginsLoadingFor, pluginsPath)
		balUtil.scandir(
			# Path
			path: pluginsPath

			# Ignore patterns
			ignorePatterns: docpad.config.ignorePatterns

			# Skip files
			fileAction: false

			# Handle directories
			dirAction: (fileFullPath,fileRelativePath,_nextFile) ->
				# Prepare
				pluginName = pathUtil.basename(fileFullPath)
				return _nextFile(null,false)  if fileFullPath is pluginsPath
				nextFile = (err,skip) ->
					if err
						docpad.warn(util.format(locale.pluginFailedToLoad, pluginName, fileFullPath)+'\n'+locale.errorFollows, err)
					return _nextFile(null,skip)

				# Forward
				docpad.loadPlugin fileFullPath, (err) ->
					return nextFile(err,true)

			# Next
			next: (err) ->
				docpad.log 'debug', util.format(locale.pluginsLoadedFor, pluginsPath)
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
			local: @packagePath
			remote: @config.latestPackageUrl
			newVersionCallback: (details) ->
				docpad.notify util.format(locale.upgradeNotification, details.local.name)
				docpad.log 'notice', util.format(locale.upgradeDetails, details.local.version, details.remote.version, details.remote.homepage)

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
		locale = @getLocale()
		database = @getDatabase()
		{collection} = opts

		# Log
		docpad.log 'debug', util.format(locale.loadingFiles, collection.length)

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'loadAfter', {collection}, (err) ->
				docpad.log 'debug', util.format(locale.loadedFiles, collection.length)
				next()

		# Fetch
		collection.forEach (file) -> tasks.push (complete) ->
			# Prepare
			fileRelativePath = file.get('relativePath')

			# Log
			docpad.log 'debug', util.format(locale.loadingFile, fileRelativePath)

			# Load the file
			file.load (err) ->
				# Check
				if err
					docpad.warn(util.format(locale.loadingFileFailed, fileRelativePath)+"\n"+locale.errorFollows, err)
					return complete()

				# Prepare
				fileIgnored = file.get('ignored')
				fileParse = file.get('parse')

				# Ignored?
				if fileIgnored or (fileParse? and !fileParse)
					docpad.log 'info', util.format(locale.loadingFileIgnored, fileRelativePath)
					collection.remove(file)
					return complete()
				else
					docpad.log 'debug', util.format(locale.loadedFile, fileRelativePath)

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
		locale = @getLocale()
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', util.format(locale.contextualizingFiles, collection.length)

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'contextualizeAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.contextualizedFiles, collection.length)
				return next()

		# Set progress indicator
		opts.setProgressIndicator? -> ['contextualizeFiles',tasks.completed,tasks.total]

		# Fetch
		collection.forEach (file,index) -> tasks.push (complete) ->
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
		locale = @getLocale()
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', util.format(locale.renderingFiles, collection.length)

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'renderAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.renderedFiles, collection.length)
				return next()

		# Set progress indicator
		opts.setProgressIndicator? -> ['renderFiles',tasks.completed,tasks.total]

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
		locale = @getLocale()
		{collection,templateData} = opts

		# Log
		docpad.log 'debug', util.format(locale.writingFiles, collection.length)

		# Async
		tasks = new balUtil.Group (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'writeAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.wroteFiles, collection.length)
				return next()

		# Set progress indicator
		opts.setProgressIndicator? -> ['writeFiles',tasks.completed,tasks.total]

		# Cycle
		collection.forEach (file,index) -> tasks.push (complete) ->
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
				complete(new Error(locale.unknownModelInCollection))

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
	action: (action,opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		runner = @getRunner()
		locale = @getLocale()

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
		@log 'debug', util.format(locale.actionStart, action)

		# Next
		next ?= (err) ->
			docpad.fatal(err)  if err
		forward = (args...) =>
			@log 'debug', util.format(locale.actionFinished, action)
			balUtil.wait 0, -> next(args...)

		# Wrap
		runner.pushAndRun (complete) ->
			# Forward
			fn = docpad[action] or docpad.run
			fn opts, (args...) ->
				forward(args...)
				complete()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Prepare
	# next(err)
	generatePrepare: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()

		# Log generating
		docpad.log 'info', locale.renderGenerating
		docpad.notify (new Date()).toLocaleTimeString(), title: locale.renderGeneratingNotification

		# Fire plugins
		docpad.emitSync 'generateBefore', server:docpad.getServer(), (err) ->
			# Forward
			return next(err)

		# Chain
		@

	# Generate Check
	# next(err)
	generateCheck: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()

		# Check plugin count
		unless docpad.hasPlugins()
			docpad.log 'warn', locale.renderNoPlugins

		# Check if the source directory exists
		balUtil.exists docpad.config.srcPath, (exists) ->
			# Check and forward
			if exists is false
				err = new Error(locale.renderNonexistant)
				return next(err)
			else
				return next()

		# Chain
		@

	# Generate Clean
	# next(err)
	generateClean: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @

		# Perform a complete clean of our collections
		docpad.resetCollections(next)

		# Chain
		@

	# Parse the files
	# next(err)
	generateParse: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		database = @getDatabase()
		config = docpad.config
		locale = @getLocale()

		# Before
		@emitSync 'parseBefore', {}, (err) ->
			return next(err)  if err

			# Log
			docpad.log 'debug', locale.renderParsing

			# Async
			tasks = new balUtil.Group (err) ->
				return next(err)  if err
				# After
				docpad.emitSync 'parseAfter', {}, (err) ->
					return next(err)  if err
					docpad.log 'debug', locale.renderParsed
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
	generateRender: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		templateData = opts.templateData or @getTemplateData()
		collection = opts.collection or @getDatabase()
		setProgressIndicator = opts.setProgressIndicator or null

		# Contextualize the datbaase, perform two render passes, and perform a write
		balUtil.flow(
			object: docpad
			action: 'contextualizeFiles renderFiles renderFiles writeFiles'
			args: [{collection,templateData,setProgressIndicator}]
			next: (err) ->
				return next(err)
		)

		# Chain
		@

	# Generate Postpare
	# next(err)
	generatePostpare: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()

		# Fire plugins
		docpad.emitSync 'generateAfter', server:docpad.getServer(), (err) ->
			return next(err)  if err

			# Log generated
			docpad.log 'info', util.format(locale.renderGenerated, (opts.count ? 'all'))
			docpad.notify (new Date()).toLocaleTimeString(), title: locale.renderGeneratedNotification

			# Completed
			return next()

		# Chain
		@

	# Date object of the last generate
	lastGenerate: null

	# Generate
	# next(err)
	generate: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		docpad.lastGenerate ?= new Date('1970')
		locale = @getLocale()

		# Progress
		progressIndicator = null
		opts.setProgressIndicator = (_progressIndicator) ->
			progressIndicator = _progressIndicator
		showProgress = ->
			progress = progressIndicator?()
			if progress
				[stage,completed,total] = progress
				percent = Math.floor((completed/total)*100)+'%'
				docpad.log 'info', util.format(locale.renderProgress, stage, percent)
		progressInterval = setInterval(showProgress,10000)

		# Finish
		finish = (err) ->
			clearInterval(progressInterval)
			progressInterval = null
			next(err)

		# Re-load and re-render only what is necessary
		if opts.reset? and opts.reset is false
			# Prepare
			docpad.generatePrepare (err) ->
				return finish(err)  if err
				database = docpad.getDatabase()

				# Create a colelction for the files to reload
				filesToReload = opts.filesToReload or new FilesCollection()
				# Add anything which was modified since our last generate
				filesToReload.add(database.findAll(mtime: $gte: docpad.lastGenerate).models)

				# Update our generate time
				docpad.lastGenerate = new Date()

				# Perform the reload of the selected files
				docpad.loadFiles {collection:filesToReload}, (err) ->
					return finish(err)  if err

					# Create a collection for the files to render
					filesToRender = opts.filesToRender or new FilesCollection()
					# For anything that gets added, if it is a layout, then add that layouts children too
					filesToRender.on 'add', (fileToRender) ->
						if fileToRender.get('isLayout')
							filesToRender.add(database.findAll(layout: fileToRender.id).models)
					# Add anything that references other documents (e.g. partials, listing, etc)
					# if our files to reload aren't all standalone files
					allStandalone = true
					filesToReload.forEach (fileToReload) ->
						if fileToReload.get('standalone') isnt true
							allStandalone = false
							return false
					if allStandalone is false
						filesToRender.add(database.findAll(referencesOthers: true).models)
					# Add anything that was re-loaded
					filesToRender.add(filesToReload.models)

					# Perform the re-render of the selected files
					docpad.generateRender {collection:filesToRender}, (err) ->
						return finish(err)  if err

						# Finish up
						docpad.generatePostpare {count:filesToRender.length}, (err) ->
							return finish(err)

		# Re-load and re-render everything
		else
			docpad.lastGenerate = new Date()
			balUtil.flow(
				object: docpad
				action: 'generatePrepare generateCheck generateClean generateParse generateRender generatePostpare'
				args: [opts]
				next: (err) ->
					return finish(err)
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
		attributes = balUtil.extend({
			fullPath: path
		},opts.attributes)
		document = @ensureDocument(attributes)
		@loadAndRenderDocument(document,opts,next)
		@

	# Render Data
	# next(err,result)
	renderData: (content,opts,next) ->
		attributes = balUtil.extend({
			filename: opts.filename
			data: content
		},opts.attributes)
		document = @createDocument(attributes)
		@loadAndRenderDocument(document,opts,next)
		@

	# Render Text
	# Doesn't extract meta information, or render layouts
	# next(err,result)
	renderText: (text,opts,next) ->
		attributes = balUtil.extend({
			filename: opts.filename
			data: text
			body: text
			content: text
		},opts.attributes)
		document = @createDocument(attributes)
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
	render: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		locale = @getLocale()

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
				err = new Error(locale.renderInvalidOptions)
				return next(err)

		# Chain
		@


	# ---------------------------------
	# Watch

	# Watch
	watch: (opts,next) =>
		# Require
		watchr = require('watchr')

		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		database = @getDatabase()
		watchrs = []
		ignorePatterns = @config.ignorePatterns
		ignorePatterns = balUtil.commonIgnorePatterns  if @config.ignorePatterns is true

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
					docpad.log 'info', util.format(locale.watchConfigChange, new Date().toLocaleTimeString())
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
				ignorePatterns: docpad.config.ignorePatterns
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
			docpad.log util.format(locale.watchRegenerating, new Date().toLocaleTimeString())
			# Afterwards, re-render anything that should always re-render
			docpad.action 'generate', opts, (err) ->
				docpad.error(err)  if err
				docpad.log util.format(locale.watchRegenerated, new Date().toLocaleTimeString())

		# Change event handler
		changeHandler = (eventName,filePath,fileCurrentStat,filePreviousStat) ->
			# Fetch the file
			docpad.log 'debug', util.format(locale.watchChange, new Date().toLocaleTimeString()), eventName, filePath

			# Check if we are a file we don't care about
			if ( ignorePatterns and ignorePatterns.test(pathUtil.basename(filePath)) )
				docpad.log 'debug', util.format(locale.watchIgnoredChange, new Date().toLocaleTimeString()), filePath
				return

			# Don't care if we are a directory
			if (fileCurrentStat or filePreviousStat).isDirectory()
				docpad.log 'debug', util.format(locale.watchDirectoryChange, new Date().toLocaleTimeString()), filePath
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
		docpad.log locale.watchStart
		resetWatchers (err) ->
			docpad.log locale.watchStarted
			return next(err)

		# Chain
		@


	# ---------------------------------
	# Run Action

	run: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		srcPath = @config.srcPath
		destinationPath = @config.rootPath
		locale = @getLocale()

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
					docpad.log 'warn', "\n#{locale.skeletonNonexistant}"
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
	skeleton: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		skeletonId = @config.skeleton
		srcPath = @config.srcPath
		destinationPath = @config.rootPath
		selectSkeletonCallback = opts.selectSkeletonCallback or null
		locale = @getLocale()

		# Use a Skeleton
		useSkeleton = (skeletonModel) ->
			# Log
			docpad.log 'info', util.format(locale.skeletonInstall, skeletonModel.get('name'), destinationPath)

			# Install Skeleton
			docpad.installSkeleton skeletonModel, destinationPath, (err) ->
				# Error?
				return next(err)  if err

				# Re-load configuration
				docpad.load (err) ->
					# Error?
					return next(err)  if err

					# Log
					docpad.log 'info', locale.skeletonInstalled

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
				docpad.log 'warn', locale.skeletonExists
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

	# Serve Document
	serveDocument: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		{document,err,req,res} = opts
		docpad = @

		# If no document, then exit early
		unless document
			if opts.statusCode?
				return res.send(opts.statusCode)
			else
				return next()

		# Content Type
		contentType = document.get('outContentType') or document.get('contentType')
		res.setHeader('Content-Type', contentType);

		# Send
		dynamic = document.get('dynamic')
		if dynamic
			templateData = balUtil.extend({}, req.templateData or {}, {req,err})
			templateData = docpad.getTemplateData(templateData)
			document.render {templateData}, (err) ->
				content = document.get('contentRendered') or document.get('content') or document.getData()
				if err
					docpad.error(err)
					return next(err)
				else
					if opts.statusCode?
						return res.send(opts.statusCode, content)
					else
						return res.send(content)
		else
			content = document.get('contentRendered') or document.get('content') or document.getData()
			if content
				if opts.statusCode?
					return res.send(opts.statusCode, content)
				else
					return res.send(content)
			else
				if opts.statusCode?
					return res.send(opts.statusCode)
				else
					return next()

		# Chain
		@

	# Server Middleware: Header
	serverMiddlewareHeader: (req,res,next) ->
		tools = res.get('X-Powered-By').split(/[,\s]+/g)
		tools.push 'DocPad'
		tools = tools.join(',')
		res.set('X-Powered-By',tools)
		next()

	# Server Middleware: Router
	serverMiddlewareRouter: (req,res,next) =>
		# Prepare
		docpad = @
		database = docpad.getDatabase()

		# Check
		return next()  unless database

		# Prepare
		pageUrl = req.url.replace(/\?.*/,'')
		document = database.findOne(urls: $has: pageUrl)
		return next()  unless document

		# Check if we are the desired url
		# if we aren't do a permanent redirect
		url = document.get('url')
		if url isnt pageUrl
			return res.redirect(301,url)

		# Serve the document to the user
		docpad.serveDocument({document,req,res,next})

	# Server Middleware: 404
	serverMiddleware404: (req,res,next) =>
		# Prepare
		docpad = @
		database = docpad.getDatabase()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '404.html'})
		docpad.serveDocument({document,req,res,next,statusCode:404})

	# Server Middleware: 500
	serverMiddleware500: (err,req,res,next) =>
		# Prepare
		docpad = @
		database = docpad.getDatabase()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '500.html'})
		docpad.serveDocument({document,err,req,res,next,statusCode:500})

	# Server
	server: (opts,next) =>
		# Requires
		http = null
		express = null

		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		config = @config
		locale = @getLocale()
		serverExpress = null
		serverHttp = null

		# Config
		opts.middlewareBodyParser ?= config.middlewareBodyParser ? config.middlewareStandard
		opts.middlewareMethodOverride ?= config.middlewareMethodOverride ? config.middlewareStandard
		opts.middlewareExpressRouter ?= config.middlewareExpressRouter ? config.middlewareStandard
		opts.middleware404 ?= config.middleware404
		opts.middleware500 ?= config.middleware500

		# Handlers
		complete = (err) ->
			return next(err)  if err
			# Plugins
			docpad.emitSync 'serverAfter', {server:serverExpress,serverExpress,serverHttp,express}, (err) ->
				return next(err)  if err
				# Complete
				docpad.log 'debug', 'Server setup'
				return next()
		startServer = ->
			# Start the server
			try
				serverHttp.listen(config.port)
				address = serverHttp.address()
				unless address?
					throw new Error(util.format(locale.serverInUse, config.port))
				serverHostname = if address.address is '0.0.0.0' then 'localhost' else address.address
				serverPort = address.port
				serverLocation = "http://#{serverHostname}:#{serverPort}/"
				serverDir = config.outPath
				docpad.log 'info', util.format(locale.serverStarted, serverLocation, serverDir)
			catch err
				return complete(err)
			finally
				return complete()

		# Plugins
		docpad.emitSync 'serverBefore', {}, (err) ->
			return complete(err)  if err

			# Server
			{serverExpress,serverHttp} = docpad.getServer(true)
			if !serverExpress and !serverHttp
				# Require
				http ?= require('http')
				express ?= require('express')

				# Create
				serverExpress = opts.serverExpress or express()
				serverHttp = opts.serverHttp or http.createServer(serverExpress)
				docpad.setServer({serverExpress,serverHttp})

			# Extend the server
			unless config.extendServer
				# Start the Server
				startServer()
			else
				# Require
				express ?= require('express')

				# POST Middleware
				serverExpress.use(express.bodyParser())  if opts.middlewareBodyParser isnt false
				serverExpress.use(express.methodOverride())  if opts.middlewareMethodOverride isnt false

				# Emit the serverExtend event
				# So plugins can define their routes earlier than the DocPad routes
				docpad.emitSync 'serverExtend', {server:serverExpress,serverExpress,serverHttp,express}, (err) ->
					return next(err)  if err

					# DocPad Header Middleware
					# Keep it before the serverExtend event
					serverExpress.use(docpad.serverMiddlewareHeader)

					# Router Middleware
					# Keep it before the serverExtend event
					serverExpress.use(serverExpress.router)  if opts.middlewareExpressRouter isnt false

					# DocPad Router Middleware
					# Keep it before the serverExtend event
					serverExpress.use(docpad.serverMiddlewareRouter)

					# Static
					# Keep it before the serverExtend event
					if config.maxAge
						serverExpress.use(express.static(config.outPath,{maxAge:config.maxAge}))
					else
						serverExpress.use(express.static(config.outPath))

					# DocPad 404 Middleware
					# Keep it before the serverExtend event
					serverExpress.use(docpad.serverMiddleware404)  if opts.middleware404 isnt false

					# DocPad 500 Middleware
					# Keep it before the serverExtend event
					serverExpress.error(docpad.serverMiddleware500)  if opts.middleware500 isnt false

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
