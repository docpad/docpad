# =====================================
# Requires

# Necessary
pathUtil = require('path')
_ = require('lodash')
CSON = require('cson')
balUtil = require('bal-util')
extendr = require('extendr')
eachr = require('eachr')
typeChecker = require('typechecker')
ambi = require('ambi')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
util = require('util')
canihaz = null
{EventEmitterEnhanced} = balUtil

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
	# Instances

	# Growl
	growlInstance: null
	getGrowlInstance: ->
		# Create
		if @growlInstance? is false
			if @getConfig().growl
				try
					@growlInstance = require('growl')
				catch err
					@growlInstance = false
			else
				@growlInstance = false

		# Return
		return @growlInstance

	# MixPanel
	mixpanelInstance: null
	getMixpanelInstance: ->
		# Create
		if @mixpanelInstance? is false
			config = @getConfig()
			{reportStatistics,mixpanelToken} = config
			if reportStatistics? and mixpanelToken?
				if reportStatistics and mixpanelToken
					try
						@mixpanelInstance = require('mixpanel').init(mixpanelToken)
					catch err
						@mixpanelInstance = false
				else
					@mixpanelInstance = false
			else
				@mixpanelInstance = null

		# Return
		return @mixpanelInstance

	# Airbrake
	airbrakeInstance: null
	getAirbrakeInstance: ->
		# Create
		if @airbrakeInstance? is false
			config = @getConfig()
			{airbrakeToken,reportErrors} = config
			if reportErrors is true and /win/.test(process.platform) is false
				try
					@airbrakeInstance = require('airbrake').createClientairbrakeToken()
				catch err
					@airbrakeInstance = false
			else
				@airbrakeInstance = false

		# Return
		return @airbrakeInstance


	# ---------------------------------
	# DocPad

	# DocPad's version number
	version: null
	getVersion: -> @version

	# Process getters
	getProcessPlatform: -> process.platform
	getProcessVersion: -> process.version.replace(/^v/,'')

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
	loggerInstances: null
	getLogger: (all=false) ->
		if all
			@loggerInstances
		else
			@loggerInstances?.logger
	setLogger: (value,all=false) ->
		if all or value.logger?
			@loggerInstances = value
		else
			@loggerInstances ?= {}
			@loggerInstances.logger = value
		@

	# The action runner instance bound to docpad
	actionRunnerInstance: null
	getActionRunner: -> @actionRunnerInstance

	# The error runner instance bound to docpad
	errorRunnerInstance: null
	getErrorRunner: -> @errorRunnerInstance

	# The track runner instance bound to docpad
	trackRunnerInstance: null
	getTrackRunner: -> @trackRunnerInstance

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
	databaseCache: null
	getDatabase: -> @database
	getDatabaseCache: -> @databaseCache or @database

	# Files by URL
	# Used to speed up fetching
	filesByUrl: null

	# Files by Selector
	# Used to speed up fetching
	filesBySelector: null

	# Files by Out Path
	# Used to speed up conflict detection
	# Do not use for anything else
	filesByOutPath: null

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
		if @blocks[name]?
			@blocks[name].destroy()
			if value
				@blocks[name] = value
			else
				delete @blocks[name]
		else
			@blocks[name] = value
		@

	#  Get blocks
	getBlocks: (blocks) ->
		@blocks
		@

	#  Set blocks
	setBlocks: (blocks) ->
		for own name,value of blocks
			@setBlock(name,value)
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
		if @collections[name]?
			@collections[name].destroy()
			if value
				@collections[name] = value
			else
				delete @collections[name]
		else
			@collections[name] = value
		@

	# Get collections
	getCollections: ->
		return @collections

	# Set collections
	setCollections: (collections) ->
		for own name,value of collections
			@setCollection(name,value)
		@


	# ---------------------------------
	# Collection Helpers

	# Get Files (will use live collections)
	getFiles: (query,sorting,paging) ->
		key = JSON.stringify({query,sorting,paging})
		files = @getCollection(key)
		unless files
			files = @getDatabase().findAllLive(query,sorting,paging)
			@setCollection(key, files)
		return files

	# Get another file's model based on a relative path
	getFile: (query,sorting,paging) ->
		file = @getDatabase().findOne(query,sorting,paging)
		return file

	# Get Files At Path
	getFilesAtPath: (path,sorting,paging) ->
		query = $or: [{relativePath: $startsWith: path}, {fullPath: $startsWith: path}]
		files = @getFiles(query,sorting,paging)
		return files

	# Get another file's model based on a relative path
	getFileAtPath: (path,sorting,paging) ->
		file = @getDatabase().fuzzyFindOne(path,sorting,paging)
		return file

	# Get a file by its url
	getFileByUrl: (url,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(@filesByUrl[url])
		return file

	# Get a file by its selector
	getFileBySelector: (selector,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(@filesBySelector[selector])
		unless file
			file = opts.collection.fuzzyFindOne(selector)
			if file
				@filesBySelector[selector] = file.id
		return file


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

	# The DocPad locale path
	localePath: pathUtil.join(__dirname, '..', '..', 'locale')

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
		{renderPasses} = @config
		locale = @getLocale()

		# Set the initial docpad template data
		@initialTemplateData ?=
			# Site Properties
			site: {}

			# Environment
			getEnvironment: ->
				return docpad.getEnvironment()

			# Environments
			getEnvironments: ->
				return docpad.getEnvironments()

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
			include: (subRelativePath,strict=true) ->
				file = @getFileAtPath(subRelativePath)
				if file
					if strict and file.get('rendered') is false
						if renderPasses is 1
							docpad.warn util.format(locale.renderedEarlyViaInclude, subRelativePath)
						return null
					return file.getOutContent()
				else
					err = new Error(util.format(locale.includeFailed, subRelativePath))
					throw err

		# Fetch our result template data
		templateData = extendr.extend({}, @initialTemplateData, @pluginsTemplateData, @config.templateData, userTemplateData)

		# Add site data
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if typeChecker.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Return
		templateData


	# -----------------------------
	# Locales

	# All the locales we have
	locales:
		en: CSON.parseFileSync(pathUtil.join(__dirname, '..', '..', 'locale', 'en.cson'))

	# Determined locale
	locale: null

	# Determined locale code
	localeCode: null

	# Get Locale Code
	getLocaleCode: ->
		if @localeCode? is false
			localeCode = null
			localeCodes = [@getConfig().localeCode, balUtil.getLocaleCode(), 'en_AU']
			for localeCode in localeCodes
				if localeCode and @locales[localeCode]?
					break
			@localeCode = localeCode.toLowerCase()
		return @localeCode

	# Get Language Code
	getLanguageCode: ->
		if @languageCode? is false
			languageCode = balUtil.getLanguageCode(@getLocaleCode())
			@languageCode = languageCode.toLowerCase()
		return @languageCode

	# Get Country Code
	getCountryCode: ->
		if @countryCode? is false
			countryCode = balUtil.getCountryCode(@getLocaleCode())
			@countryCode = countryCode.toLowerCase()
		return @countryCode

	# Get Locale
	getLocale: ->
		if @locale? is false
			@locale = @locales[@getLocaleCode()] or @locales[@getLanguageCode()] or @locales['en']
		return @locale


	# -----------------------------
	# Environments

	# Get Environment
	getEnvironment: ->
		env = @getConfig().env or 'development'
		return env

	# Get Environments
	getEnvironments: ->
		env = @getEnvironment()
		envs = env.split(/[, ]+/)
		return envs


	# -----------------------------
	# Configuration

	# Website Package Configuration
	websitePackageConfig: null  # {}

	# Merged Configuration
	# Merged in the order of:
	# - initialConfig
	# - userConfig
	# - websiteConfig
	# - instanceConfig
	# - environmentConfig
	config: null  # {}

	# Instance Configuration
	instanceConfig: null  # {}

	# Website Configuration
	websiteConfig: null  # {}

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
		# Project Paths

		# The project directory
		rootPath: process.cwd()

		# The project's package.json path
		packagePath: 'package.json'

		# Where to get the latest package information from
		latestPackageUrl: 'https://docpad.org/latest.json'

		# The project's configuration paths
		# Reads only the first one that exists
		# If you want to read multiple configuration paths, then point it to a coffee|js file that requires
		# the other paths you want and exports the merged config
		configPaths: [
			'docpad.js'
			'docpad.coffee'
			'docpad.json'
			'docpad.cson'
		]

		# Plugin directories to load
		pluginPaths: []

		# The project's plugins directory
		pluginsPaths: [
			'node_modules'
			'plugins'
		]

		# Paths that we should watch for reload changes in
		reloadPaths: []

		# Paths that we should watch for regeneration changes in
		regeneratePaths: []

		# The time to wait after a source file has changed before using it to regenerate
		regenerateDelay: 100

		# The project's out directory
		outPath: 'out'

		# The project's src directory
		srcPath: 'src'

		# The project's documents directories
		# relative to the srcPath
		documentsPaths: [
			'documents'
		]

		# The project's files directories
		# relative to the srcPath
		filesPaths: [
			'files'
			'public'
		]

		# The project's layouts directory
		# relative to the srcPath
		layoutsPaths: [
			'layouts'
		]

		# Ignored file patterns during directory parsing
		ignorePaths: false
		ignoreHiddenFiles: false
		ignoreCommonPatterns: true
		ignoreCustomPatterns: false

		# Watch options
		watchOptions: null


		# -----------------------------
		# Server

		# Port
		# The port that the server should use
		# PORT - Heroku, Nodejitsu, Custom
		# VCAP_APP_PORT - AppFog
		# VMC_APP_PORT - CloudFoundry
		port: null

		# Max Age
		# The caching time limit that is sent to the client
		maxAge: 86400000

		# Server
		# The Express.js server that we want docpad to use
		serverExpress: null
		# The HTTP server that we want docpad to use
		serverHttp: null

		# Extend Server
		# Whether or not we should extend the server with extra middleware and routing
		extendServer: true

		# Which middlewares would you like us to activate
		# The standard middlewares (bodyParser, methodOverride, express router)
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
		# By default it is only enabled if we are not running inside a test
		reportErrors: process.argv.join('').indexOf('test') is -1

		# Report Statistics
		# Whether or not we should report statistics back to DocPad
		# By default it is only enabled if we are not running inside a test
		reportStatistics: process.argv.join('').indexOf('test') is -1

		# Hash Key
		# The key that we use to hash some data before sending it to our statistic server
		hashKey: '7>9}$3hP86o,4=@T'  # const

		# Airbrake Token
		airbrakeToken: 'e7374dd1c5a346efe3895b9b0c1c0325'

		# MixPanel Token
		mixpanelToken: 'd0f9b33c0ec921350b5419352028577e'


		# -----------------------------
		# Other

		# Detect Encoding
		# Should we attempt to auto detect the encoding of our files?
		# Useful when you are using foreign encoding (e.g. GBK) for your files
		# Only works on unix systems currently (limit of iconv module)
		detectEncoding: false

		# Render Single Extensions
		# Whether or not we should render single extensions by default
		renderSingleExtensions: false

		# Render Passes
		# How many times should we render documents that reference other documents?
		renderPasses: 1

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
		# Performs a regenerate every x milliseconds, useful for always having the latest data
		regenerateEvery: false


		# -----------------------------
		# Environment Configuration

		# Locale Code
		# The code we shall use for our locale (e.g. en, fr, etc)
		localeCode: null

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

	# Get the Configuration
	getConfig: ->
		return @config or {}

	# Get the Port
	getPort: ->
		return @getConfig().port ? process.env.PORT ? process.env.VCAP_APP_PORT ? process.env.VMC_APP_PORT ? 9778


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
		@getEvents().forEach (eventName) ->
			# Bind to the event
			docpad.on eventName, (opts,next) ->
				eventHandler = docpad.getConfig().events?[eventName]
				# Fire the config event handler for this event, if it exists
				if typeChecker.isFunction(eventHandler)
					args = [opts,next]
					ambi(eventHandler.bind(configEventContext), args...)
				# It doesn't exist, so lets continue
				else
					next()

		# Create our action runner
		@actionRunnerInstance = new TaskGroup().run().on 'complete', (err) ->
			docpad.error(err)  if err

		# Create our error runner
		@errorRunnerInstance = new TaskGroup().run().on 'complete', (err) ->
			if err and docpad.getDebugging()
				locale = docpad.getLocale()
				docpad.log('warn', locale.reportError+'\n'+locale.errorFollows, err)

		# Create our track runner
		@trackRunnerInstance = new TaskGroup().run().on 'complete', (err) ->
			if err and docpad.getDebugging()
				locale = docpad.getLocale()
				docpad.log('warn', locale.trackError+'\n'+locale.errorFollows, err)

		# Initialize the logger
		logger = new (require('caterpillar').Logger)()
		filter = new (require('caterpillar-filter').Filter)
		last = human = new (require('caterpillar-human').Human)
		logger.pipe(filter).pipe(human).pipe(process.stdout)
		@setLogger({logger,filter,human,last})
		@setLogLevel(6)

		# Log to bubbled events
		@on 'log', (args...) ->
			docpad.log.apply(@,args)

		# Require canihaz
		canihaz ?= require('canihaz')(
			installation: docpad.corePath
			location: docpad.packagePath
			key: 'lazyDependencies'
		)

		# Dereference and initialise advanced variables
		# we deliberately ommit initialTemplateData here, as it is setup in getTemplateData
		@slowPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@pluginsTemplateData = {}
		@instanceConfig = {}
		@collections = {}
		@blocks = {}
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}
		@database = new FilesCollection()
			.on('remove', (model,options) =>
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the urls
				for url in model.get('urls') or []
					delete docpad.filesByUrl[url]

				# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
				outPath = model.get('outPath')
				if outPath
					@database.findAll(outPath:outPath).each (model) ->
						model.set('mtime': new Date())
			)
			.on('change:urls', (model,urls=[],options) =>
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the old urls
				for url in model.previous('urls') or []
					delete docpad.filesByUrl[url]

				# Add the new urls
				for url in urls
					docpad.filesByUrl[url] = model.cid
			)
			.on('change:outPath', (model,outPath,options) =>
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Check if we have changed our outPath
				previousOutPath = model.previous('outPath')
				if previousOutPath
					# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
					previousModels = @database.findAll(outPath:previousOutPath)
					previousModels.each (model) ->
						model.set('mtime': new Date())

					# Update the cache entry with another file that has the same outPath or delete it if there aren't any others
					previousModelId = @filesByOutPath[previousOutPath]
					if previousModelId is model.id
						if previousModels.length
							@filesByOutPath[previousOutPath] = previousModelId
						else
							delete @filesByOutPath[previousOutPath]

				# Update the cache entry and fetch the latest if it was already set
				existingModelId = @filesByOutPath[outPath] ?= model.id
				if existingModelId isnt model.id
					# We have a conflict, let the user know
					modelPath = model.get('fullPath')
					existingModel = @database.get(existingModelId)
					existingModelPath = existingModel.get('fullPath')
					message =  util.format(docpad.getLocale().outPathConflict, outPath, modelPath, existingModelPath)
					docpad.warn(message)
			)
		@locales = extendr.dereference(@locales)
		@userConfig = extendr.dereference(@userConfig)
		@initialConfig = extendr.dereference(@initialConfig)

		# Extract action
		if instanceConfig.action?
			action = instanceConfig.action
		else
			action = 'load ready'

		# Check if we want to perform an action
		if action
			@action action, instanceConfig, (err) ->
				return docpad.fatal(err)  if err
				next?(null,docpad)
		else
			next?(null,docpad)

		# Chain
		@


	# =================================
	# Helpers

	# Is Ignored Path
	isIgnoredPath: (path,opts={}) ->
		opts = extendr.extend({
			ignorePaths: @config.ignorePaths
			ignoreHiddenFiles: @config.ignoreHiddenFiles
			ignoreCommonPatterns: @config.ignoreCommonPatterns
			ignoreCustomPatterns: @config.ignoreCustomPatterns
		},opts)
		return balUtil.isIgnoredPath(path,opts)

	# Scan Directory
	scandir: (opts={}) ->
		opts = extendr.extend({
			ignorePaths: @config.ignorePaths
			ignoreHiddenFiles: @config.ignoreHiddenFiles
			ignoreCommonPatterns: @config.ignoreCommonPatterns
			ignoreCustomPatterns: @config.ignoreCustomPatterns
		},opts)
		return balUtil.scandir(opts)

	# Watch Directory
	watchdir: (opts={}) ->
		opts = extendr.extend({
			ignorePaths: @config.ignorePaths
			ignoreHiddenFiles: @config.ignoreHiddenFiles
			ignoreCommonPatterns: @config.ignoreCommonPatterns
			ignoreCustomPatterns: @config.ignoreCustomPatterns
		},opts,@config.watchOptions)
		return require('watchr').watch(opts)


	# =================================
	# Setup and Loading

	# Ready
	# next(err,docpadInstance)
	ready: (opts,next) =>
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		mixpanelInstance = @getMixpanelInstance()

		# Render Single Extensions
		@DocumentModel::defaults.renderSingleExtensions = config.renderSingleExtensions

		# Version Check
		@compareVersion()

		# Welcome Prepare
		if @getDebugging()
			pluginsList = ("#{pluginName} v#{@loadedPlugins[pluginName].version}"  for pluginName in Object.keys(@loadedPlugins).sort()).join(', ')
		else
			pluginsList = Object.keys(@loadedPlugins).sort().join(', ')

		# Welcome Output
		@log 'info', util.format(locale.welcome, "v#{@getVersion()}")
		@log 'info', util.format(locale.welcomePlugins, pluginsList)
		@log 'info', util.format(locale.welcomeEnvironment, @getEnvironment())

		# Prepare
		tasks = new TaskGroup().once 'complete', (err) ->
			# Error?
			return docpad.error(err)  if err

			# All done, forward our DocPad instance onto our creator
			return next?(null,docpad)

		# Welcome Event
		tasks.addTask (complete) =>
			# No welcome
			return complete()  unless config.welcome

			# Welcome
			@emitSync('welcome', {docpad}, complete)

		# Anyomous
		# Ignore errors
		tasks.addTask (complete) =>
			# No statistics or username is already identified
			return complete()  if !mixpanelInstance or @userConfig.username

			# User is anonymous, set their username to the hashed and salted mac address
			require('getmac').getMac (err,macAddress) =>
				return complete()  if err or !macAddress

				# Hash with salt
				try
					macAddressHash = require('crypto').createHmac('sha1',config.hashKey).update(macAddress).digest('hex')
				catch err
					return complete()  if err

				# Apply
				if macAddressHash
					@userConfig.name ?= "MAC #{macAddressHash}"
					@userConfig.username ?= macAddressHash

				# Next
				return complete()

		# Track
		tasks.addTask =>
			# No stats or no username
			return  if !mixpanelInstance or !@userConfig.username

			# Prepare the latest user data
			lastLogin = new Date()
			userData =
				$email: @userConfig.email
				$name: @userConfig.name
				$last_login: lastLogin
				$country_code: balUtil.getCountryCode()
				languageCode: balUtil.getLanguageCode()
				version: @getVersion()
				platform: @getProcessPlatform()
				nodeVersion: @getProcessVersion()

			# Is this a new user?
			if @userConfig.identified isnt true
				# Identify the new user with mixpanel
				mixpanelInstance.people.set @userConfig.username, extendr.extend(userData, {
					$created: lastLogin
					$username: @userConfig.username
				})

				# Save the changes with these
				@updateUserConfig(identified:true)

			# Or an existing user?
			else
				# Update the existing user's information witht he latest
				mixpanelInstance.people.set(@userConfig.username, userData)

		# DocPad Ready
		tasks.addTask (complete) =>
			@emitSync('docpadReady', {docpad}, complete)

		# Run tasks
		tasks.run()

		# Chain
		@

	# Merge Configurations
	mergeConfigurations: (configPackages,configsToMerge) ->
		# Prepare
		envs = @getEnvironments()

		# Figure out merging
		for configPackage in configPackages
			continue  unless configPackage
			configsToMerge.push(configPackage)
			for env in envs
				envConfig = configPackage.environments?[env]
				configsToMerge.push(envConfig)  if envConfig

		# Merge
		extendr.safeDeepExtendPlainObjects(configsToMerge...)

		# Chain
		return @

	# Set Instance Configuration
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config
		@

	# Set Configuration
	# next(err,config)
	setConfig: (instanceConfig,next) =>
		# Prepare
		[instanceConfig,next] = balUtil.extractOptsAndCallback(instanceConfig,next)
		docpad = @

		# Apply the instance configuration, generally we won't have it at this level
		# as it would have been applied earlier the load step
		@setInstanceConfig(instanceConfig)  if instanceConfig

		# Apply the environment
		# websitePackageConfig.env is left out of the detection here as it is usually an object
		# that is already merged with our process.env by the environment runner
		# rather than a string which is the docpad convention
		@config.env = @instanceConfig.env or @websiteConfig.env or @initialConfig.env or process.env.NODE_ENV

		# Merge configurations
		configPackages = [@initialConfig, @userConfig, @websiteConfig, @instanceConfig]
		configsToMerge = [@config]
		docpad.mergeConfigurations(configPackages,configsToMerge)

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
		process.removeListener('uncaughtException', @error)
		if @config.catchExceptions
			process.setMaxListeners(0)
			process.on('uncaughtException', @error)

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
		postTasks = new TaskGroup().once 'complete', (err) =>
			return next(err,@config)

		# Lazy Dependencies: Iconv
		postTasks.addTask (complete) =>
			return complete()  unless @config.detectEncoding
			return canihaz('iconv',complete)

		# Plugins
		postTasks.addTask (complete) =>
			@loadPlugins(complete)

		# Extend collections
		postTasks.addTask (complete) =>
			@extendCollections(complete)

		# Fetch plugins templateData
		postTasks.addTask (complete) =>
			@emitSync('extendTemplateData', {templateData:@pluginsTemplateData}, complete)

		# Fire the docpadLoaded event
		postTasks.addTask (complete) =>
			@emitSync('docpadLoaded', {}, complete)

		# Fire post tasks
		postTasks.run()

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
		@setInstanceConfig(instanceConfig)

		# Prepare the Load Tasks
		preTasks = new TaskGroup().once 'complete', (err) =>
			return next(err)  if err
			return @setConfig(next)

		# Normalize the userConfigPath
		preTasks.addTask (complete) =>
			balUtil.getHomePath (err,homePath) =>
				return complete(err)  if err
				dropboxPath = pathUtil.join(homePath,'Dropbox')
				safefs.exists dropboxPath, (dropboxPathExists) =>
					userConfigDirPath = if dropboxPathExists then dropboxPath else homePath
					@userConfigPath = pathUtil.join(userConfigDirPath, @userConfigPath)
					return complete()

		# Load User's Configuration
		preTasks.addTask (complete) =>
			@loadConfigPath @userConfigPath, (err,data) =>
				return complete(err)  if err

				# Apply loaded data
				extendr.extend(@userConfig, data or {})

				# Done loading
				return complete()

		# Load DocPad's Package Configuration
		preTasks.addTask (complete) =>
			@loadConfigPath @packagePath, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Version
				@version = data.version
				@getAirbrakeInstance()?.appVersion = data.version

				# Done loading
				return complete()

		# Load Website's Package Configuration
		preTasks.addTask (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			websitePackagePath = pathUtil.resolve(rootPath, @instanceConfig.packagePath or @initialConfig.packagePath)
			@loadConfigPath websitePackagePath, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				@websitePackageConfig = data

				# Done loading
				return complete()

		# Read the .env file if it exists
		preTasks.addTask (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @websitePackageConfig.rootPath or @initialConfig.rootPath)
			envPath = pathUtil.join(rootPath, '.env')
			safefs.exists envPath, (exists) ->
				return complete()  unless exists
				safefs.readFile envPath, (err,data) ->
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
		preTasks.addTask (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			configPaths = @instanceConfig.configPaths or @initialConfig.configPaths
			for configPath, index in configPaths
				configPaths[index] = pathUtil.resolve(rootPath, configPath)
			@loadConfigPaths configPaths, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				extendr.extend(@websiteConfig, data)

				# Done loading
				return complete()

		# Run the load tasks synchronously
		preTasks.run()

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
	updateUserConfig: (data={},next) ->
		# Prepare
		[data,next] = balUtil.extractOptsAndCallback(data,next)
		docpad = @
		userConfigPath = @userConfigPath

		# Apply back to our loaded configuration
		# does not apply to @config as we would have to reparse everything
		# and that appears to be an imaginary problem
		extendr.extend(@userConfig,data)  if data

		# Write it with CSON
		CSON.stringify @userConfig, (err,userConfigString) ->
			# Check
			return next?(err)  if err

			# Write it
			safefs.writeFile userConfigPath, userConfigString, 'utf8', (err) ->
				# Forward
				return next?(err)

		# Chain
		@

	# Load a configuration url
	# next(err,parsedData)
	loadConfigUrl: (configUrl,next) ->
		# Prepare
		locale = @getLocale()

		# Log
		@log 'debug', util.format(locale.loadingConfigUrl, configUrl)

		# Read the URL
		balUtil.readPath configUrl, (err,body) ->
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
		safefs.exists configPath, (exists) ->
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
		result = null

		# Ensure array
		configPaths = [configPaths]  unless typeChecker.isArray(configPaths)

		# Group
		tasks = new TaskGroup().once 'complete', (err) ->
			return next(err,result)

		# Read our files
		# On the first file that returns a result, exit
		configPaths.forEach (configPath) ->
			tasks.addTask (complete) ->
				return complete()  if result
				docpad.loadConfigPath configPath, (err,config) ->
					return complete(err)  if err
					if config
						result = config
						tasks.clear(); complete()
					else
						complete()

		# Run them synchronously
		tasks.run()

		# Chain
		@

	# Extend Collecitons
	# next(err)
	extendCollections: (next) ->
		# Prepare
		docpad = @
		config = @config
		locale = @getLocale()
		database = @getDatabase()

		# Standard Collections
		@setCollections(
			# Standard Collections
			documents: database.createLiveChildCollection()
				.setQuery('isDocument', {
					$or:
						isDocument: true
						fullPath: $startsWith: config.documentsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingDocument, model.attributes.fullPath))
					model.setDefaults({
						isDocument: true
						render: true
						write: true
					})
				)
			files: database.createLiveChildCollection()
				.setQuery('isFile', {
					$or:
						isFile: true
						fullPath: $startsWith: config.filesPaths
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingFile, model.attributes.fullPath))
					model.setDefaults({
						isFile: true
						render: false
						write: true
					})
				)
			layouts: database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isLayout: true
						fullPath: $startsWith: config.layoutsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingLayout, model.attributes.fullPath))
					model.setDefaults({
						isLayout: true
						render: false
						write: false
					})
				)

			# Special Collections
			html: database.createLiveChildCollection()
				.setQuery('isHTML', {
					$or:
						isDocument: true
						isFile: true
					outExtension: 'html'
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingHtml, model.attributes.fullPath))
				)
			stylesheet: database.createLiveChildCollection()
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
					model.setDefaults({
						referencesOthers: true
					})
				)
		)

		# Blocks
		@setBlocks(
			meta: new MetaCollection()
			scripts: new ScriptsCollection()
			styles: new StylesCollection()
		)

		# Custom Collections Group
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
			docpad.error(err)  if err
			docpad.emitSync('extendCollections',{},next)

		# Cycle through Custom Collections
		eachr @config.collections or {}, (fn,name) ->
			tasks.addTask (complete) ->
				if fn.length is 2 # callback
					fn.call docpad, database, (err,collection) ->
						docpad.error(err)  if err
						# make it a live collection
						collection.live(true)  if collection
						# apply the collection
						docpad.setCollection(name,collection)
						complete()
				else
					collection = fn.call(docpad,database)
					# make it a live collection
					collection.live(true)  if collection
					# apply the collection
					docpad.setCollection(name,collection)
					complete()

		# Run Custom collections
		tasks.run()

		# Chain
		@

	# Reset Collections
	# next(err)
	resetCollections: (next) ->
		# Prepare
		database = @getDatabase()

		# Update the cached database
		@databaseCache = new FilesCollection(database.models)

		# Perform a complete clean of our collections
		database.reset([])
		@getBlock('meta').reset([]).add([
			'<meta http-equiv="X-Powered-By" content="DocPad"/>'
		])
		@getBlock('scripts').reset([])
		@getBlock('styles').reset([])

		# Reset caches
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}

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
		@getLogger().setConfig({level})
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
		config = @getConfig()
		return @  unless err
		@error err, 'err', ->
			if config.catchExceptions
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
		err = new Error(err)  unless err.message?
		err.logged = true
		docpad.log(type, locale.errorOccured, '\n'+(err.stack ? err.message))
		docpad.notify(err.message, title:locale.errorOccured)

		# Check
		airbrake = @getAirbrakeInstance()
		if airbrake
			# Prepare
			err.params =
				docpadVersion: @version
				docpadConfig: @config
			# Apply
			@getErrorRunner().addTask (complete) ->
				airbrake.notify err, (airbrakeErr,airbrakeUrl) ->
					if airbrakeErr
						complete(airbrakeErr)
					else
						console.log(util.format(locale.errorLoggedTo, airbrakeUrl))
						complete()
		else
			next?()

		# Chain
		@

	# Handle a warning
	warn: (message,err,next) =>
		# Prepare
		docpad = @
		locale = @getLocale()

		# Log
		docpad.log('warn', message)
		docpad.error(err, 'warn', next)  if err
		docpad.notify(message, title:locale.warnOccured)

		# Chain
		@

	# Perform a growl notification
	notify: (message,opts) =>
		# Prepare
		docpad = @

		# Check
		growl = @getGrowlInstance()
		if growl
			# Apply
			try
				growl(message,opts)
			catch err
				# ignore

		# Chain
		@

	# Track
	track: (name,data={},next) ->
		# Check
		mixpanelInstance = @getMixpanelInstance()
		if mixpanelInstance
			# Prepare
			if @userConfig?.username
				data.distinct_id = @userConfig.username
				data.username = @userConfig.username
			if @websitePackageConfig?.name
				data.websiteName = @websitePackageConfig.name
			data.version = @getVersion()
			data.platform = @getProcessPlatform()
			data.nodeVersion = @getProcessVersion()
			data.environment = @getEnvironment()
			eachr @loadedPlugins, (value,key) ->
				data['plugin-'+key] = value.version or true

			# Apply
			@getTrackRunner().addTask (complete) ->
				mixpanelInstance.track name, data, (err) ->
					next?()
					complete(err)
		@


	# =================================
	# Models and Collections

	# Instantiate a File
	createFile: (data={},options={}) =>
		# Prepare
		docpad = @
		options = extendr.extend({
			detectEncoding: @config.detectEncoding
			outDirPath: @config.outPath
		},options)

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
		options = extendr.extend({
			detectEncoding: @config.detectEncoding
			outDirPath: @config.outPath
		},options)

		# Create and return
		document = new DocumentModel(data,options)

		# Log
		document.on 'log', (args...) ->
			docpad.log(args...)

		# Fetch a layout
		document.on 'getLayout', (opts={},next) ->
			opts.collection = docpad.getCollection('layouts')
			layout = docpad.getFileBySelector(opts.selector,opts)
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
		config = @getConfig()
		database = @getDatabase()
		fileFullPath = data.fullPath or null
		result = database.findOne(fullPath: fileFullPath)

		# Create result
		unless result
			# If we have a file path to compare
			if fileFullPath
				# Check if we have a document or layout
				for dirPath in config.documentsPaths.concat(config.layoutsPaths)
					if fileFullPath.indexOf(dirPath) is 0
						data.relativePath or= fileFullPath.replace(dirPath,'').replace(/^[\/\\]/,'')
						result = @createDocument(data,options)
						break

				# Check if we have a file
				unless result
					for dirPath in config.filesPaths
						if fileFullPath.indexOf(dirPath) is 0
							data.relativePath or= fileFullPath.replace(dirPath,'').replace(/^[\/\\]/,'')
							result = @createFile(data,options)
							break

			# Otherwise, create a file anyway
			unless result
				result = @createDocument(data,options)

			# Add result to database
			database.add(result)

		# Return
		result

	# Parse a file directory
	# next(err)
	parseFileDirectory: (opts={},next) ->
		opts.createFunction ?= @createFile
		return @parseDirectory(opts,next)

	# Parse a document directory
	# next(err)
	parseDocumentDirectory: (opts={},next) ->
		opts.createFunction ?= @createDocument
		return @parseDirectory(opts,next)

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
		unless safefs.existsSync(path)
			# Log
			docpad.log 'debug', util.format(locale.renderDirectoryNonexistant, path)

			# Forward
			return next()

		# Log
		docpad.log 'debug', util.format(locale.renderDirectoryParsing, path)

		# Files
		@scandir(
			# Path
			path: path

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
		return typeChecker.isEmptyObject(@loadedPlugins) is false

	# Load Plugins
	loadPlugins: (next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Snore
		@slowPlugins = {}
		snore = balUtil.createSnore ->
			docpad.log 'notice', util.format(locale.pluginsSlow, Object.keys(docpad.slowPlugins).join(', '))

		# Async
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
			docpad.slowPlugins = {}
			snore.clear()
			return next(err)

		# Load website plugins
		(@config.pluginsPaths or []).forEach (pluginsPath) =>
			exists = safefs.existsSync(pluginsPath)
			if exists
				tasks.addTask (complete) =>
					@loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		(@config.pluginPaths or []).forEach (pluginPath) =>
			exists = safefs.existsSync(pluginPath)
			if exists
				tasks.addTask (complete) =>
					@loadPlugin(pluginPath, complete)

		# Execute the loading asynchronously
		tasks.run()

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
		config = @getConfig()
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
			# However we probably want to reload the configuration as perhaps the user or environment configuration has changed
			docpad.loadedPlugins[pluginName].setConfig()
			# Complete
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
						if unsupported is 'version' and config.skipUnsupportedPlugins is false
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
		@scandir(
			# Path
			path: pluginsPath

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

	# Compare current DocPad version to the latest
	compareVersion: ->
		return @  unless @config.checkVersion

		# Prepare
		docpad = @
		locale = @getLocale()

		# Check
		balUtil.packageCompare(
			local: @packagePath
			remote: @config.latestPackageUrl
			newVersionCallback: (details) ->
				docpad.notify locale.upgradeNotification
				docpad.log 'notice', util.format(locale.upgradeDetails, details.local.version, details.remote.version, details.local.upgradeUrl or details.remote.installUrl or details.remote.homepage)
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
		return next(null,@exchange)  unless typeChecker.isEmptyObject(@exchange)

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
		safefs.ensurePath destinationPath, (err) ->
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
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'loadAfter', {collection}, (err) ->
				docpad.log 'debug', util.format(locale.loadedFiles, collection.length)
				next()

		# Fetch
		collection.forEach (file) ->  tasks.addTask (complete) ->
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
		docpad.emitSync 'loadBefore', {collection}, (err) ->
			return next(err)  if err
			tasks.run()

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
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'contextualizeAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.contextualizedFiles, collection.length)
				return next()

		# Fetch
		opts.progress?.step('contextualizeFiles').total(collection.length)
		collection.forEach (file,index) ->  tasks.addTask (complete) ->
			file.contextualize (err) ->
				opts.progress?.tick()
				return complete(err)

		# Start contextualizing
		docpad.emitSync 'contextualizeBefore', {collection,templateData}, (err) ->
			return next(err)  if err
			tasks.run()

		# Chain
		@

	# Render files
	# next(err)
	renderFiles: (opts={},next) ->
		# Prepare
		docpad = @
		locale = @getLocale()
		{collection,templateData,renderPasses} = opts

		# Log
		docpad.log 'debug', util.format(locale.renderingFiles, collection.length)

		# Async
		tasks = new TaskGroup().once 'complete', (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'renderAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.renderedFiles, collection.length)
				return next()

		# Render File
		renderFile = (fileToRender,next) ->
			# Skip?
			dynamic = fileToRender.get('dynamic')
			render = fileToRender.get('render')
			relativePath = fileToRender.get('relativePath')

			# Render
			if dynamic or (render? and !render) or !relativePath or fileToRender.render? is false
				next()
			else
				fileToRender.render({templateData},next)
			return fileToRender

		# Render Collection
		renderCollection = (collectionToRender,{renderPass},next) ->
			# Prepare
			subTasks = new TaskGroup().setConfig(concurrency:0).once('complete',next)

			# Cycle
			step = "renderFiles (pass #{renderPass})"
			opts.progress?.step(step).total(collectionToRender.length)
			collectionToRender.forEach (file) -> subTasks.addTask (complete) ->
				renderFile file, (err) ->
					opts.progress?.tick()
					return complete(err)

			# Fire
			subTasks.run()
			return collectionToRender

		# Queue the initial render
		initialCollection = collection.findAll('referencesOthers':false)
		subsequentCollection = null
		tasks.addTask (complete) ->
			renderCollection initialCollection, {renderPass:1}, (err) ->
				return complete(err)  if err
				subsequentCollection = collection.findAll('referencesOthers':true)
				renderCollection(subsequentCollection, {renderPass:2}, complete)

		# Queue the subsequent renders
		if renderPasses > 1
			[3..renderPasses].forEach (renderPass) ->  tasks.addTask (complete) ->
				renderCollection(subsequentCollection, {renderPass}, complete)

		# Fire the queue
		docpad.emitSync 'renderBefore', {collection,templateData}, (err) =>
			return next(err)  if err
			tasks.run()

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
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
			return next(err)  if err
			# After
			docpad.emitSync 'writeAfter', {collection}, (err) ->
				return next(err)  if err
				docpad.log 'debug', util.format(locale.wroteFiles, collection.length)
				return next()

		# Cycle
		opts.progress?.step('writeFiles').total(collection.length)
		collection.forEach (file,index) -> tasks.addTask (complete) ->
			# Skip
			dynamic = file.get('dynamic')
			write = file.get('write')
			relativePath = file.get('relativePath')
			finish = (err) ->
				opts.progress?.tick()
				return complete(err)

			# Write
			if dynamic or (write? and !write) or !relativePath
				finish()
			else if file.writeRendered?
				file.writeRendered(finish)
			else if file.write?
				file.write(finish)
			else
				err = new Error(locale.unknownModelInCollection)
				finish(err)

		#  Start writing
		docpad.emitSync 'writeBefore', {collection,templateData}, (err) =>
			return next(err)  if err
			tasks.run()

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
		runner = @getActionRunner()
		locale = @getLocale()

		# Array?
		if typeChecker.isArray(action)
			actions = action
		else
			actions = action.split(/[,\s]+/g)

		# Clean actions
		actions = _.uniq _.compact actions

		# Multiple actions?
		if actions.length is 1
			action = actions[0]
		else
			tasks = new TaskGroup().once 'complete', (err) ->
				return next(err)
			actions.forEach (action) -> tasks.addTask (complete) ->
				docpad.action(action,opts,complete)
			tasks.run()
			return docpad

		# Log
		@log 'debug', util.format(locale.actionStart, action)

		# Next
		next ?= (err) ->
			docpad.fatal(err)  if err
		forward = (args...) =>
			@log 'debug', util.format(locale.actionFinished, action)
			process.nextTick -> next(args...)  # not sure why we do this, but we do

		# Wrap
		runner.addTask (complete) ->
			# Fetch
			fn = docpad[action]
			# Check
			return complete(new Error(util.format(locale.actionNonexistant, action)))  unless fn
			# Track
			docpad.track(action)
			# Forward
			fn opts, (args...) ->
				forward(args...)
				complete()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Prepare
	# opts = {reset}
	# next(err)
	generatePrepare: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Update generating flag
		docpad.generating = true

		# Log generating
		docpad.log 'info', locale.renderGenerating
		docpad.notify (new Date()).toLocaleTimeString(), title: locale.renderGeneratingNotification

		# Tasks
		tasks = new TaskGroup().once('complete',next)

		# Perform a complete clean of our collections if we want to
		if opts.reset is true
			# Check plugin count
			unless docpad.hasPlugins()
				docpad.log('warn', locale.renderNoPlugins)

			# Check if the source directory exists
			tasks.addTask (complete) ->
				safefs.exists config.srcPath, (exists) ->
					# Check and forward
					if exists is false
						err = new Error(locale.renderNonexistant)
						return complete(err)
					else
						return complete()

			# Clean our collections
			tasks.addTask (complete) ->
				docpad.resetCollections(complete)

		# Fire plugins
		tasks.addTask (complete) ->
			docpad.emitSync('generateBefore', {reset:opts.reset, server:docpad.getServer()}, complete)

		# Run
		tasks.run()

		# Chain
		@

	# Parse the files
	# opts = {}
	# next(err)
	generateParse: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		database = @getDatabase()
		config = @getConfig()
		locale = @getLocale()

		# Before
		@emitSync 'parseBefore', {}, (err) ->
			return next(err)  if err

			# Log
			docpad.log 'debug', locale.renderParsing

			# Async
			tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) ->
				return next(err)  if err
				# After
				docpad.emitSync 'parseAfter', {}, (err) ->
					return next(err)  if err
					docpad.log 'debug', locale.renderParsed
					return next(err)

			# Documents
			config.documentsPaths.forEach (documentsPath) -> tasks.addTask (complete) ->
				docpad.parseDocumentDirectory({
					path: documentsPath
					collection: database
				},complete)

			# Files
			config.filesPaths.forEach (filesPath) -> tasks.addTask (complete) ->
				docpad.parseFileDirectory({
					path: filesPath
					collection: database
				},complete)

			# Layouts
			config.layoutsPaths.forEach (layoutsPath) -> tasks.addTask (complete) ->
				docpad.parseDocumentDirectory({
					path: layoutsPath
					collection: database
				},complete)

			# Async
			tasks.run()

		# Chain
		@

	# Generate Render
	# opts = {templateData,collection,setProgressIndicator}
	# next(err)
	generateRender: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		opts.templateData or= @getTemplateData()
		opts.collection or= @getDatabase()
		opts.renderPasses or= @getConfig().renderPasses

		# Contextualize the datbaase, perform two render passes, and perform a write
		balUtil.flow(
			object: docpad
			action: 'contextualizeFiles renderFiles writeFiles'
			args: [opts]
			next: (err) ->
				return next(err)
		)

		# Chain
		@

	# Generate Postpare
	# opts = {collection}
	# next(err)
	generatePostpare: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		database = @getDatabase()
		collection = opts.collection or database

		# Update generating flag
		docpad.generating = false
		docpad.generateEnded = new Date()

		# Update caches
		docpad.databaseCache = null

		# Fire plugins
		docpad.emitSync 'generateAfter', server:docpad.getServer(), (err) ->
			return next(err)  if err

			# Log generated
			seconds = (docpad.generateEnded - docpad.generateStarted) / 1000
			howMany =
				if collection is database
					"all #{collection.length}"
				else
					collection.length
			opts.progress?.finish()
			docpad.log 'info', util.format(locale.renderGenerated, howMany, seconds)
			docpad.notify (new Date()).toLocaleTimeString(), title: locale.renderGeneratedNotification

			# Completed
			return next()

		# Chain
		@

	# Generate Helpers
	generateStarted: null
	generateEnded: null
	generating: false

	# Generate
	# next(err)
	generate: (opts,next) =>
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		opts.reset ?= true

		# Check
		return next()  if opts.collection?.length is 0

		# Progress
		if @getLogLevel() is 6 and 'development' in @getEnvironments()
			opts.progress ?= require('progressbar').create()
			docpad.getLogger(true).last.unpipe(process.stdout)
		finish = (err) ->
			opts.progress?.finish()
			opts.progress = null
			docpad.getLogger(true).last.pipe(process.stdout)
			return next(err)

		# Re-load and re-render only what is necessary
		if opts.collection? is false and opts.reset is false
			# Prepare
			docpad.generatePrepare opts, (err) ->
				return finish(err)  if err
				database = docpad.getDatabase()

				# Create a colelction for the files to reload
				filesToReload = opts.filesToReload or new FilesCollection()
				# Add anything which was modified since our last generate
				filesToReload.add(database.findAll(mtime: $gte: docpad.generateStarted).models)

				# Update our generate time
				docpad.generateStarted = new Date()

				# Perform the reload of the selected files
				docpad.loadFiles {collection:filesToReload}, (err) ->
					return finish(err)  if err

					# Create a collection for the files to render
					filesToRender = opts.filesToRender or new FilesCollection()
					# For anything that gets added, if it is a layout, then add that layouts children too
					filesToRender.on 'add', (fileToRender) ->
						if fileToRender.get('isLayout')
							filesToRender.add(database.findAll(layoutId: fileToRender.id).models)
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
						docpad.generatePostpare {collection:filesToRender}, (err) ->
							return finish(err)

		# Re-load and re-render everything
		else
			# Prepare
			docpad.generateStarted = new Date()
			balUtil.flow(
				object: docpad
				action: 'generatePrepare generateParse generateRender generatePostpare'
				args: [opts]
				next: (err) ->
					return finish(err)
			)

		# Chain
		@


	# ---------------------------------
	# Render

	# Flow through a Document
	# next(err,document)
	flowDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)

		# Flow
		balUtil.flow(
			object: document
			action: opts.action
			args: [opts]
			next: (err) ->
				return next?(err,document)
		)

		# Chain
		@

	# Load a Document
	# next(err,document)
	loadDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		opts.action or= 'load contextualize'

		# Flow
		@flowDocument(document, opts, next)

		# Chain
		@

	# Load and Render a Document
	# next(err,document)
	loadAndRenderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		opts.action or= 'load contextualize render'

		# Flow
		@flowDocument document, opts, (err) ->
			result = document.getOutContent()
			return next?(err,result,document)

		# Chain
		@

	# Render Document
	# next(err,result)
	renderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)

		# Render
		document.render(opts,next)

		# Chain
		@

	# Render Path
	# next(err,result)
	renderPath: (path,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			fullPath: path
		},opts.attributes)

		# Handle
		document = @ensureDocument(attributes)
		@loadAndRenderDocument(document,opts,next)

		# Chain
		@

	# Render Data
	# next(err,result)
	renderData: (content,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			filename: opts.filename
			data: content
		},opts.attributes)

		# Handle
		document = @createDocument(attributes)
		@loadAndRenderDocument(document,opts,next)

		# Chain
		@

	# Render Text
	# Doesn't extract meta information, or render layouts
	# next(err,result)
	renderText: (text,opts,next) ->
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		opts.actions ?= ['renderExtensions','renderDocument']
		attributes = extendr.extend({
			filename: opts.filename
			data: text
			body: text
			content: text
		},opts.attributes)

		# Handle
		document = @createDocument(attributes)

		# Flow
		balUtil.flow(
			object: document
			action: 'normalize contextualize render'
			args: [opts]
			next: (err) ->
				result = document.getOutContent()
				return next(err,result,document)
		)

		# Chain
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
		# Prepare
		[opts,next] = balUtil.extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		database = @getDatabase()
		watchers = []

		# Close our watchers
		closeWatchers = ->
			for watcher in watchers
				watcher.close()
				watcher = null
			watchers = []

		# Restart our watchers
		resetWatchers = (next) ->
			# Close our watchers
			closeWatchers()

			# Start a group
			tasks = new TaskGroup().setConfig(concurrency:0).once('complete',next)

			# Watch reload paths
			reloadPaths = _.union(config.reloadPaths, config.configPaths)
			tasks.addTask (complete) -> docpad.watchdir(
				paths: reloadPaths
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': ->
						docpad.log 'info', util.format(locale.watchReloadChange, new Date().toLocaleTimeString())
						docpad.action 'load', (err) ->
							return docpad.fatal(err)  if err
							performGenerate(reset:true)
				next: (err,_watchers) ->
					if err
						docpad.log('warn', "Watching the reload paths has failed:", reloadPaths, err)
						return complete()
					for watcher in _watchers
						watchers.push(watcher)
					return complete()
			)

			# Watch regenerate paths
			regeneratePaths = config.regeneratePaths
			tasks.addTask (complete) -> docpad.watchdir(
				paths: regeneratePaths
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': -> performGenerate(reset:true)
				next: (err,_watchers) ->
					if err
						docpad.log('warn', "Watching the regenerate paths has failed:", regeneratePaths, err)
						return complete()
					for watcher in _watchers
						watchers.push(watcher)
					return complete()
			)

			# Watch the source
			srcPath = config.srcPath
			tasks.addTask (complete) -> docpad.watchdir(
				path: srcPath
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': changeHandler
				next: (err,watcher) ->
					if err
						docpad.log('warn', "Watching the src path has failed:", srcPath, err)
						return complete()
					watchers.push(watcher)
					return complete()
			)

			# Run
			tasks.run()

		# Timer
		regenerateTimer = null
		queueRegeneration = ->
			# Reset the wait
			if regenerateTimer
				clearTimeout(regenerateTimer)
				regenerateTimer = null
			# Regenerat after a while
			regenerateTimer = setTimeout(performGenerate, config.regenerateDelay)
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
		changeHandler = (changeType,filePath,fileCurrentStat,filePreviousStat) ->
			# Fetch the file
			docpad.log 'debug', util.format(locale.watchChange, new Date().toLocaleTimeString()), changeType, filePath

			# Check if we are a file we don't care about
			# This check should not be needed with v2.3.3 of watchr
			# however we've still got it here as it may still be an issue
			isIgnored = docpad.isIgnoredPath(filePath)
			if isIgnored
				docpad.log 'debug', util.format(locale.watchIgnoredChange, new Date().toLocaleTimeString()), filePath
				return

			# Don't care if we are a directory
			isDirectory = (fileCurrentStat or filePreviousStat).isDirectory()
			if isDirectory
				docpad.log 'debug', util.format(locale.watchDirectoryChange, new Date().toLocaleTimeString()), filePath
				return

			# Override the stat's mtime to now
			# This is because renames will not update the mtime
			fileCurrentStat?.mtime = new Date()

			# Create the file object
			file = docpad.ensureFileOrDocument({fullPath:filePath},{stat:fileCurrentStat})
			file.setStat(fileCurrentStat)  if changeType is 'update'

			# File was deleted, delete the rendered file, and remove it from the database
			if changeType is 'delete'
				database.remove(file)
				file.delete (err) ->
					return docpad.error(err)  if err
					queueRegeneration()

			# File is new or was changed, update it's mtime by setting the stat
			else if changeType in ['create','update']
				queueRegeneration()

		# Watch
		docpad.log(locale.watchStart)
		resetWatchers (err) ->
			return next(err)  if err
			docpad.log(locale.watchStarted)
			return next()

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
				action: 'server generate watch'
				args: [opts]
				next: (err) ->
					return next(err)
			)

		# Check if we have the docpad structure
		if safefs.existsSync(srcPath)
			# We have the correct structure, so let's proceed with DocPad
			runDocpad()
		else
			# We don't have the correct structure
			# Check if we are running on an empty directory
			safefs.readdir destinationPath, (err,files) ->
				return next(err)  if err

				# Check if our directory is empty
				if files.length
					# It isn't empty, display a warning
					docpad.log('warn', "\n"+util.format(locale.skeletonNonexistant, destinationPath))
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
		config = @getConfig()
		skeletonId = config.skeleton
		srcPath = config.srcPath
		destinationPath = config.rootPath
		selectSkeletonCallback = opts.selectSkeletonCallback or null
		locale = @getLocale()

		# Use a Skeleton
		useSkeleton = (skeletonModel) ->
			# Track
			docpad.track('skeleton-use',{skeletonId:skeletonModel.id})

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
			# Track
			docpad.track('skeleton-use',{skeletonId:'none'})

			# Create the paths
			safefs.ensurePath srcPath, (err) ->
				# Error?
				return next(err)  if err

				# Group
				tasks = new TaskGroup().setConfig(concurrency:0).once('complete',next)

				# Node Modules
				tasks.addTask (complete) ->
					safefs.ensurePath(pathUtil.join(config.rootPath,'node_modules'), complete)

				# Package
				tasks.addTask (complete) ->
					data = JSON.stringify({
						name: 'no-skeleton.docpad'
						version: '0.1.0'
						description: 'New DocPad project without using a skeleton'
						engines:
							node: '0.10'
							npm: '1.2'
						dependencies:
							docpad: '6.x'
						main: 'node_modules/docpad/bin/docpad-server'
					},null,'\t')
					safefs.writeFile(pathUtil.join(config.rootPath,'package.json'), data, complete)

				# Config
				tasks.addTask (complete) ->
					data = """
						# DocPad Configuration File
						# http://docpad.org/docs/config

						# Define the DocPad Configuration
						docpadConfig = {
							# ...
						}

						# Export the DocPad Configuration
						module.exports = docpadConfig
						"""
					safefs.writeFile(pathUtil.join(config.rootPath,'docpad.coffee'), data, complete)

				# Documents
				tasks.addTask (complete) ->
					safefs.ensurePath(config.documentsPaths[0], complete)

				# Layouts
				tasks.addTask (complete) ->
					safefs.ensurePath(config.layoutsPaths[0], complete)

				# Files
				tasks.addTask (complete) ->
					safefs.ensurePath(config.filesPaths[0], complete)

				# Run
				tasks.run()

		# Check if already exists
		safefs.exists srcPath, (exists) ->
			# Check
			if exists
				docpad.log('warn', locale.skeletonExists)
				return next()

			# Track
			docpad.track('skeleton-ask')

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
			templateData = extendr.extend({}, req.templateData or {}, {req,err})
			templateData = docpad.getTemplateData(templateData)
			document.render {templateData}, (err) ->
				content = document.getOutContent()
				if err
					docpad.error(err)
					return next(err)
				else
					if opts.statusCode?
						return res.send(opts.statusCode, content)
					else
						return res.send(content)
		else
			content = document.getOutContent()
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

		# Chain
		return @

	# Server Middleware: Router
	serverMiddlewareRouter: (req,res,next) =>
		# Prepare
		docpad = @

		# If we have not performed a generation yet then wait until the initial generation has completed
		if docpad.generateEnded is null # or docpad.generating is true
			docpad.once 'generateAfter', ->
				return docpad.serverMiddlewareRouter(req,res,next)
			return @

		# Prepare
		database = docpad.getDatabaseCache()
		cleanUrl = req.url.replace(/\?.*/,'')
		file = docpad.getFileByUrl(req.url,{collection:database}) or docpad.getFileByUrl(cleanUrl,{collection:database})
		return next()  if file? is false

		# Check if we are the desired url
		# if we aren't do a permanent redirect
		url = file.get('url')
		if (url isnt cleanUrl) and (url isnt req.url)
			return res.redirect(301,url)

		# Serve the file to the user
		docpad.serveDocument({document:file,req,res,next})

		# Chain
		return @

	# Server Middleware: 404
	serverMiddleware404: (req,res,next) =>
		# Prepare
		docpad = @
		database = docpad.getDatabaseCache()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '404.html'})
		docpad.serveDocument({document,req,res,next,statusCode:404})

		# Chain
		return @

	# Server Middleware: 500
	serverMiddleware500: (err,req,res,next) =>
		# Prepare
		docpad = @
		database = docpad.getDatabaseCache()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '500.html'})
		docpad.serveDocument({document,err,req,res,next,statusCode:500})

		# Chain
		return @

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
		port = @getPort()
		serverExpress = null
		serverHttp = null

		# Config
		opts.middlewareBodyParser ?= config.middlewareBodyParser ? config.middlewareStandard
		opts.middlewareMethodOverride ?= config.middlewareMethodOverride ? config.middlewareStandard
		opts.middlewareExpressRouter ?= config.middlewareExpressRouter ? config.middlewareStandard
		opts.middleware404 ?= config.middleware404
		opts.middleware500 ?= config.middleware500

		# Finish
		finish = (err) ->
			return next(err)  if err

			# Plugins
			docpad.emitSync 'serverAfter', {server:serverExpress,serverExpress,serverHttp,express}, (err) ->
				return next(err)  if err

				# Done
				return next()

		# Start Server
		startServer = (next) ->
			# Catch
			serverHttp.once 'error', (err) ->
				# Friendlify the error message if it is what we suspect it is
				if err.message.indexOf('EADDRINUSE') isnt -1
					err = new Error(util.format(locale.serverInUse, port))

				# Done
				return next(err)

			# Listen
			docpad.log 'debug', util.format(locale.serverStart, port, config.outPath)
			serverHttp.listen port,  ->
				# Log
				address = serverHttp.address()
				serverHostname = if address.address is '0.0.0.0' then 'localhost' else address.address
				serverPort = address.port
				serverLocation = "http://#{serverHostname}:#{serverPort}/"
				docpad.log 'info', util.format(locale.serverStarted, serverLocation, config.outPath)

				# Done
				return next()

		# Start
		docpad.emitSync 'serverBefore', {}, (err) ->
			return finish(err)  if err

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
				startServer(finish)
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
					# Keep it after the serverExtend event
					serverExpress.use(docpad.serverMiddlewareHeader)

					# Router Middleware
					# Keep it after the serverExtend event
					serverExpress.use(serverExpress.router)  if opts.middlewareExpressRouter isnt false

					# DocPad Router Middleware
					# Keep it after the serverExtend event
					serverExpress.use(docpad.serverMiddlewareRouter)

					# Static
					# Keep it after the serverExtend event
					if config.maxAge
						serverExpress.use(express.static(config.outPath,{maxAge:config.maxAge}))
					else
						serverExpress.use(express.static(config.outPath))

					# DocPad 404 Middleware
					# Keep it after the serverExtend event
					serverExpress.use(docpad.serverMiddleware404)  if opts.middleware404 isnt false

					# DocPad 500 Middleware
					# Keep it after the serverExtend event
					serverExpress.error(docpad.serverMiddleware500)  if opts.middleware500 isnt false

				# Start the Server
				startServer(finish)


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
