# =====================================
# This block *must* come first

# Profile
if ('--profile' in process.argv)
	# Debug
	debugger

	# Nodefly
	if process.env.NODEFLY_KEY
		console.log 'Loading profiling tool: nodefly'
		lazyRequire 'nodefly', {cwd:corePath}, (err,nodefly) ->
			return  if err
			nodefly.profile(process.env.NODEFLY_KEY, 'docpad')
			console.log('Profiling with nodefly')

	# Nodetime
	if process.env.NODETIME_KEY
		console.log 'Loading profiling tool: nodetime'
		lazyRequire 'nodetime', {cwd:corePath}, (err,nodetime) ->
			return  if err
			nodetime.profile({
				accountKey: process.env.NODETIME_KEY
				appName: 'DocPad'
			})
			console.log('Profiling with nodetime')

	# Webkit Devtools
	console.log 'Loading profiling tool: webkit-devtools-agent'
	lazyRequire 'webkit-devtools-agent', {cwd:corePath}, (err) ->
		return  if err
		console.log("Profiling with webkit-devtools-agent on process id:", process.pid)


# =====================================
# Requires

# Standard Library
pathUtil = require('path')
util     = require('util')

# External
{lazyRequire} = require('lazy-require')
_ = require('lodash')
CSON = require('cson')
balUtil = require('bal-util')
extendr = require('extendr')
eachr = require('eachr')
typeChecker = require('typechecker')
ambi = require('ambi')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
safeps = require('safeps')
ignorefs = require('ignorefs')
superAgent = require('superagent')
{extractOptsAndCallback} = require('extract-opts')
{EventEmitterGrouped} = require('event-emitter-grouped')

# Base
{queryEngine,Backbone,Events,Model,Collection,View,QueryCollection} = require('./base')

# Utils
docpadUtil = require('./util')

# Models
FileModel = require('./models/file')
DocumentModel = require('./models/document')

# Collections
FilesCollection = require('./collections/files')
ElementsCollection = require('./collections/elements')
MetaCollection = require('./collections/meta')
ScriptsCollection = require('./collections/scripts')
StylesCollection = require('./collections/styles')

# Plugins
PluginLoader = require('./plugin-loader')
BasePlugin = require('./plugin')


# ---------------------------------
# Helpers
corePath = pathUtil.resolve(__dirname, '..', '..')
setImmediate = global?.setImmediate or process.nextTick  # node 0.8 b/c

# =====================================
# DocPad

# The DocPad Class
# Extends https://github.com/bevry/event-emitter-grouped
class DocPad extends EventEmitterGrouped

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
		@version ?= require(@packagePath).version
		return @version

	getVersionString: ->
		if docpadUtil.isLocalDocPadExecutable()
			return util.format(@getLocale().versionLocal, @getVersion(), @corePath)
		else
			return util.format(@getLocale().versionGlobal, @getVersion(), @corePath)

	# Plugin version requirements
	pluginVersion: '2'

	# Process getters
	getProcessPlatform: -> process.platform
	getProcessVersion: -> process.version.replace(/^v/,'')

	# The express and http server instances bound to docpad
	serverExpress: null
	serverHttp: null
	getServer: (both=false) ->
		{serverExpress,serverHttp} = @
		if both
			return {serverExpress, serverHttp}
		else
			return serverExpress
	setServer: (servers) ->
		# Apply
		if servers.serverExpress and servers.serverHttp
			@serverExpress = servers.serverExpress
			@serverHttp = servers.serverHttp

		# Cleanup
		delete @config.serverHttp
		delete @config.serverExpress
		delete @config.server
	destroyServer: ->
		@serverHttp?.close()
		@serverHttp = null
		# @TODO figure out how to destroy the express server

	# The caterpillar instances bound to docpad
	loggerInstances: null
	getLogger: -> @loggerInstances?.logger
	getLoggers: -> @loggerInstances
	setLoggers: (loggers) ->
		if @loggerInstances
			@warn('Loggers have already been set')
		else
			@loggerInstances = loggers
			@loggerInstances.logger.setConfig(dry:true)
			@loggerInstances.console.setConfig(dry:false).pipe(process.stdout)
		return loggers
	destroyLoggers: ->
		if @loggerInstances
			for own key,value of @loggerInstances
				value.end()
		@

	# The action runner instance bound to docpad
	actionRunnerInstance: null
	getActionRunner: -> @actionRunnerInstance
	action: (args...) => docpadUtil.action.apply(@, args)

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
		'extendTemplateData'           # fired each load
		'extendCollections'            # fired each load
		'docpadLoaded'                 # fired multiple times, first time command line configuration hasn't been applied yet
		'docpadReady'                  # fired only once
		'docpadDestroy'                # fired once on shutdown
		'consoleSetup'                 # fired once
		'generateBefore'
		'populateCollectionsBefore'
		'populateCollections'
		'contextualizeBefore'
		'contextualizeAfter'
		'renderBefore'
		'renderCollectionBefore'
		'render'                       # fired for each extension conversion
		'renderDocument'               # fired for each document render, including layouts and render passes
		'renderCollectionAfter'
		'renderAfter'
		'writeBefore'
		'writeAfter'
		'generateAfter'
		'generated'
		'serverBefore'
		'serverExtend'
		'serverAfter'
		'notify'
	]
	getEvents: ->
		@events


	# ---------------------------------
	# Collections

	# Database collection
	database: null  # QueryEngine Collection
	databaseTempCache: null
	getDatabase: -> @database
	getDatabaseSafe: -> @databaseTempCache or @database
	destroyDatabase: ->
		if @database?
			@database.destroy()
			@database = null
		if @databaseTempCache?
			@databaseTempCache.destroy()
			@databaseTempCache = null
		@

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
	getBlocks: -> @blocks

	#  Set blocks
	setBlocks: (blocks) ->
		for own name,value of blocks
			@setBlock(name,value)
		@

	# Each block
	eachBlock: (fn) ->
		eachr(@blocks, fn)
		@

	# Destroy Blocks
	destroyBlocks: ->
		if @blocks
			for own name,block of @blocks
				block.destroy()
				@blocks[name] = null
		@

	# Collections
	collections: null

	# Get a collection
	getCollection: (value) ->
		if value
			if typeof value is 'string'
				if value is 'database'
					return @getDatabase()

				else
					for collection in @collections
						if value in [collection.options.name, collection.options.key]
							return collection

			else
				for collection in @collections
					if value is collection
						return collection

		return null

	# Get a collection
	destroyCollection: (value) ->
		if value
			if typeof value is 'string' and value isnt 'database'
				@collections = @collections.filter (collection) ->
					if value in [collection.options.name, collection.options.key]
						collection?.destroy()
						return false
					else
						return true

			else if value isnt @getDatabase()
				@collections = @collections.filter (collection) ->
					if value is collection
						collection?.destroy()
						return false
					else
						return true

		return null

	# Add a collection
	addCollection: (collection) ->
		if collection and collection not in [@getDatabase(), @getCollection(collection)]
			@collections.push(collection)
		@

	# Set a collection
	# A collection can have multiple names
	setCollection: (name, collection) ->
		if collection
			if name
				collection.options.name = name
				if @getCollection(name) isnt collection
					@destroyCollection(name)
			@addCollection(collection)
		else
			@destroyCollection(name)

	# Get collections
	getCollections: ->
		return @collections

	# Set collections
	setCollections: (collections) ->
		if Array.isArray(collections)
			for value in collections
				@addCollection(value)
		else
			for own name,value of collections
				@setCollection(name, value)
		@

	# Each collection
	eachCollection: (fn) ->
		fn(@getDatabase(), 'database')
		for collection,index in @collections
			fn(collection, collection.options.name or collection.options.key or index)
		@

	# Destroy Collections
	destroyCollections: ->
		if @collections
			for collection in @collections
				collection.destroy()
			@collections = []
		@


	# ---------------------------------
	# Collection Helpers

	# Get files (will use live collections)
	getFiles: (query,sorting,paging) ->
		key = JSON.stringify({query, sorting, paging})
		collection = @getCollection(key)
		unless collection
			collection = @getDatabase().findAllLive(query, sorting, paging)
			collection.options.key = key
			@addCollection(collection)
		return collection

	# Get a single file based on a query
	getFile: (query,sorting,paging) ->
		file = @getDatabase().findOne(query, sorting, paging)
		return file

	# Get files at a path
	getFilesAtPath: (path,sorting,paging) ->
		query = $or: [{relativePath: $startsWith: path}, {fullPath: $startsWith: path}]
		files = @getFiles(query, sorting, paging)
		return files

	# Get a file at a relative or absolute path or url
	getFileAtPath: (path,sorting,paging) ->
		file = @getDatabase().fuzzyFindOne(path, sorting, paging)
		return file

	# Get a file by its url
	# TODO: Does this still work???
	getFileByUrl: (url,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(@filesByUrl[url])
		return file

	# Get a file by its id
	getFileById: (id,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(id)
		return file

	# Remove the query string from a url
	# Pathname convention taken from document.location.pathname
	getUrlPathname: (url) ->
		 return url.replace(/\?.*/,'')

	# Get a file by its route
	# next(err,file)
	getFileByRoute: (url,next) ->
		# Prepare
		docpad = @

		# If we have not performed a generation yet then wait until the initial generation has completed
		if docpad.generated is false
			# Wait until generation has completed and recall ourselves
			docpad.once 'generated', ->
				return docpad.getFileByRoute(url, next)

			# hain
			return @

		# @TODO the above causes a signifcant delay when importing external documents (like tumblr data) into the database
		# we need to figure out a better way of doing this
		# perhaps it is via `writeSource: once` for imported documents
		# or providing an option to disable this so it forward onto the static handler instead

		# Prepare
		database = docpad.getDatabaseSafe()

		# Fetch
		cleanUrl = docpad.getUrlPathname(url)
		file = docpad.getFileByUrl(url, {collection:database}) or docpad.getFileByUrl(cleanUrl, {collection:database})

		# Forward
		next(null, file)

		# Chain
		@

	# Get a file by its selector
	# TODO: What on earth is a selector?
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
			# Check
			return next(err)  if err

			# Prepare
			index = 0

			# If we have the exchange data, then add the skeletons from it
			if exchange
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
				position: index
			))

			# Return Collection
			return next(null, docpad.skeletonsCollection)
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
	corePath: corePath

	# The DocPad library directory
	libPath: __dirname

	# The main DocPad file
	mainPath: pathUtil.resolve(__dirname, 'docpad')

	# The DocPad package.json path
	packagePath: pathUtil.resolve(__dirname, '..', '..', 'package.json')

	# The DocPad locale path
	localePath: pathUtil.resolve(__dirname, '..', '..', 'locale')

	# The DocPad debug log path
	debugLogPath: pathUtil.join(process.cwd(), 'docpad-debug.log')

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
				path = document.getPath(path, parentPath)
				return path

			# Get Files
			getFiles: (query,sorting,paging) ->
				@referencesOthers()
				result = docpad.getFiles(query, sorting, paging)
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
				result = docpad.getFilesAtPath(path, sorting, paging)
				return result

			# Get another file's model based on a relative path
			getFileAtPath: (relativePath) ->
				@referencesOthers()
				path = @getPath(relativePath)
				result = docpad.getFileAtPath(path)
				return result

			# Get a specific file by its id
			getFileById: (id) ->
				@referencesOthers()
				result = docpad.getFileById(id)
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
						if docpad.getConfig().renderPasses is 1
							docpad.warn util.format(locale.renderedEarlyViaInclude, subRelativePath)
						return null
					return file.getOutContent()
				else
					err = new Error(util.format(locale.includeFailed, subRelativePath))
					throw err

		# Fetch our result template data
		templateData = extendr.extend({}, @initialTemplateData, @pluginsTemplateData, @getConfig().templateData, userTemplateData)

		# Add site data
		templateData.site.url or= 'http://'+(docpad.getHostname() or 'localhost')+':'+(docpad.getPort())
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if typeChecker.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Return
		templateData


	# -----------------------------
	# Locales

	# Determined locale
	locale: null

	# Get Locale
	getLocale: ->
		if @locale? is false
			config = @getConfig()
			codes = _.uniq [
				'en'
				safeps.getLanguageCode config.localeCode
				safeps.getLanguageCode safeps.getLocaleCode()
				safeps.getLocaleCode   config.localeCode
				safeps.getLocaleCode   safeps.getLocaleCode()
			]
			locales = (@loadLocale(code)  for code in codes)
			@locale = extendr.extend(locales...)

		return @locale

	# Load Locale
	loadLocale: (code) ->
		localePath = pathUtil.join(@localePath, "#{code}.cson")
		return null  unless safefs.existsSync(localePath)
		locale = CSON.parseFileSync(localePath)
		return locale


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

	# Hash Key
	# The key that we use to hash some data before sending it to our statistic server
	hashKey: '7>9}$3hP86o,4=@T'  # const

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

		# Terms of Service
		tos: null

		# Identified
		identified: null

	# Initial Configuration
	initialConfig:

		# -----------------------------
		# Plugins

		# Force re-install of all plugin dependencies
		force: false

		# Whether or not we should use the global docpad instance
		global: false

		# Whether or not we should enable plugins that have not been listed or not
		enableUnlistedPlugins: true

		# Plugins which should be enabled or not pluginName: pluginEnabled
		enabledPlugins: {}

		# Whether or not we should skip unsupported plugins
		skipUnsupportedPlugins: true

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: {}

		# Where to fetch the exchange information from
		exchangeUrl: 'http://docpad.org/exchange.json'


		# -----------------------------
		# Project Paths

		# The project directory
		rootPath: process.cwd()

		# The project's database cache path
		databaseCachePath: '.docpad.db'

		# The project's package.json path
		packagePath: 'package.json'

		# Where to get the latest package information from
		latestPackageUrl: 'http://docpad.org/latest.json'

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

		# The time to wait before outputting the files we are waiting on
		slowFilesDelay: 20*1000

		# The project's out directory
		outPath: 'out'

		# The project's src directory
		srcPath: 'src'

		# The project's documents directories
		# relative to the srcPath
		documentsPaths: [
			'documents'
			'render'
		]

		# The project's files directories
		# relative to the srcPath
		filesPaths: [
			'files'
			'static'
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
		# Defaults to these environment variables:
		# - PORT — Heroku, Nodejitsu, Custom
		# - VCAP_APP_PORT — AppFog
		# - VMC_APP_PORT — CloudFoundry
		port: null

		# Hostname
		# The hostname we wish to listen to
		# Defaults to these environment variables:
		# HOSTNAME — Generic
		# Do not set to "localhost" it does not work on heroku
		hostname: null

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


		# -----------------------------
		# Other

		# Utilise the database cache
		databaseCache: false  # [false, true, 'write']

		# Detect Encoding
		# Should we attempt to auto detect the encoding of our files?
		# Useful when you are using foreign encoding (e.g. GBK) for your files
		detectEncoding: false

		# Render Single Extensions
		# Whether or not we should render single extensions by default
		renderSingleExtensions: false

		# Render Passes
		# How many times should we render documents that reference other documents?
		renderPasses: 1

		# Offline
		# Whether or not we should run in offline mode
		# Offline will disable the following:
		# - checkVersion
		# - reportErrors
		# - reportStatistics
		offline: false

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: false

		# Welcome
		# Whether or not we should display any custom welcome callbacks
		welcome: false

		# Prompts
		# Whether or not we should display any prompts
		prompts: false

		# Powered By DocPad
		# Whether or not we should include DocPad in the Powered-By meta header
		# Please leave this enabled as it is a standard practice and promotes DocPad in the web eco-system
		poweredByDocPad: true

		# Helper Url
		# Used for subscribing to newsletter, account information, and statistics etc
		# Helper's source-code can be found at: https://github.com/bevry/docpad-helper
		helperUrl: if true then 'http://docpad-helper.herokuapp.com/' else 'http://localhost:8000/'

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

		# Regerenate Every Options
		# The generate options to use on the regenerate every call
		regenerateEveryOptions:
			populate: true
			partial:  false


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
				checkVersion: /docpad$/.test(process.argv[1] or '')
				welcome: /docpad$/.test(process.argv[1] or '')
				prompts: /docpad$/.test(process.argv[1] or '')


	# Regenerate Timer
	# When config.regenerateEvery is set to a value, we create a timer here
	regenerateTimer: null

	# Get the Configuration
	getConfig: ->
		return @config or {}

	# Get the Port
	getPort: ->
		return @getConfig().port ? process.env.PORT ? process.env.VCAP_APP_PORT ? process.env.VMC_APP_PORT ? 9778

	# Get the Hostname
	getHostname: ->
		return @getConfig().hostname ? process.env.HOSTNAME ? null


	# =================================
	# Initialization Functions

	# Construct DocPad
	# next(err)
	constructor: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig, next)
		docpad = @

		# Binders
		# Using this over coffescript's => on class methods, ensures that the method length is kept
		for methodName in 'log error warn trackError checkRequest subscribe track identify serverMiddlewareRouter serverMiddlewareHeader serverMiddleware404 serverMiddleware500'.split(/\s+/)
			@[methodName] = @[methodName].bind(@)

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
		@actionRunnerInstance = TaskGroup.create('action runner').whenDone (err) ->
			docpad.error(err)  if err

		# Create our error runner
		@errorRunnerInstance = TaskGroup.create('error runner').whenDone (err) ->
			if err and docpad.getDebugging()
				locale = docpad.getLocale()
				docpad.log('warn', locale.reportError+' '+locale.errorFollows+' '+(err.stack ? err.message).toString())

		# Create our track runner
		@trackRunnerInstance = TaskGroup.create('track runner').whenDone (err) ->
			if err and docpad.getDebugging()
				locale = docpad.getLocale()
				docpad.log('warn', locale.trackError+' '+locale.errorFollows+' '+(err.stack ? err.message).toString())

		# Initialize the loggers
		if (loggers = instanceConfig.loggers)
			delete instanceConfig.loggers
		else
			# Create
			logger = new (require('caterpillar').Logger)(lineOffset: 2)

			# console
			loggerConsole = logger
				.pipe(
					new (require('caterpillar-filter').Filter)
				)
				.pipe(
					new (require('caterpillar-human').Human)
				)

			# Apply
			loggers = {logger, console:loggerConsole}

		# Apply the loggers
		safefs.unlink(@debugLogPath, ->)  # Remove the old debug log file
		@setLoggers(loggers)  # Apply the logger streams
		@setLogLevel(@initialConfig.logLevel)  # Set the default log level

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
		@collections = []
		@blocks = {}
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}
		@database = new FilesCollection(null, {name:'database'})
			.on('remove', (model,options) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the urls
				for url in model.get('urls') or []
					delete docpad.filesByUrl[url]

				# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
				outPath = model.get('outPath')
				if outPath
					updatedModels = docpad.database.findAll({outPath})
					updatedModels.remove(model)
					updatedModels.each (model) ->
						model.set('mtime': new Date())

					# Log
					docpad.log('debug', 'Updated mtime for these models due to remove of a similar one', updatedModels.pluck('relativePath'))

				# Return safely
				return true
			)
			.on('add change:urls', (model) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the old urls
				for url in model.previous('urls') or []
					delete docpad.filesByUrl[url]

				# Add the new urls
				for url in model.get('urls')
					docpad.filesByUrl[url] = model.cid

				# Return safely
				return true
			)
			.on('add change:outPath', (model) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Check if we have changed our outPath
				previousOutPath = model.previous('outPath')
				if previousOutPath
					# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
					previousModels = docpad.database.findAll(outPath:previousOutPath)
					previousModels.remove(model)
					previousModels.each (model) ->
						model.set('mtime': new Date())

					# Log
					docpad.log('debug', 'Updated mtime for these models due to addition of a similar one', previousModels.pluck('relativePath'))

					# Update the cache entry with another file that has the same outPath or delete it if there aren't any others
					previousModelId = docpad.filesByOutPath[previousOutPath]
					if previousModelId is model.id
						if previousModels.length
							docpad.filesByOutPath[previousOutPath] = previousModelId
						else
							delete docpad.filesByOutPath[previousOutPath]

				# Update the cache entry and fetch the latest if it was already set
				if (outPath = model.get('outPath'))
					existingModelId = docpad.filesByOutPath[outPath] ?= model.id
					if existingModelId isnt model.id
						existingModel = docpad.database.get(existingModelId)
						if existingModel
							# We have a conflict, let the user know
							modelPath = model.get('fullPath') or (model.get('relativePath')+':'+model.id)
							existingModelPath = existingModel.get('fullPath') or (existingModel.get('relativePath')+':'+existingModel.id)
							message =  util.format(docpad.getLocale().outPathConflict, outPath, modelPath, existingModelPath)
							docpad.warn(message)
						else
							# There reference was old, update it with our new one
							docpad.filesByOutPath[outPath] = model.id

				# Return safely
				return true
			)
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
				next?(null, docpad)
		else
			next?(null, docpad)

		# Chain
		@

	# Destroy
	# This is an action, and should be called as such
	# E.g. docpad.action('destroy', next)
	destroy: (opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @

		# Destroy Regenerate Timer
		docpad.destroyRegenerateTimer()

		# Destroy Plugins
		docpad.emitSerial 'docpadDestroy', (err) ->
			# Check
			return next?(err)  if err

			# Destroy Plugins
			docpad.destroyPlugins()

			# Destroy Server
			docpad.destroyServer()

			# Destroy Watchers
			docpad.destroyWatchers()

			# Destroy Blocks
			docpad.destroyBlocks()

			# Destroy Collections
			docpad.destroyCollections()

			# Destroy Database
			docpad.destroyDatabase()

			# Destroy Logging
			docpad.destroyLoggers()

			# Destroy Process Listners
			process.removeListener('uncaughtException', docpad.error)

			# Destroy DocPad Listeners
			docpad.removeAllListeners()

			# Forward
			return next?()

		# Chain
		@

	# Emit Serial
	emitSerial: (eventName, opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = docpad.getLocale()

		# Log
		docpad.log 'debug', util.format(locale.emittingEvent, eventName)

		# Emit
		super eventName, opts, (err) ->
			# Check
			return next(err)  if err

			# Log
			docpad.log 'debug', util.format(locale.emittedEvent, eventName)

			# Forward
			return next(err)

		# Chain
		@

	# Emit Parallel
	emitParallel: (eventName, opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = docpad.getLocale()

		# Log
		docpad.log 'debug', util.format(locale.emittingEvent, eventName)

		# Emit
		super eventName, opts, (err) ->
			# Check
			return next(err)  if err

			# Log
			docpad.log 'debug', util.format(locale.emittedEvent, eventName)

			# Forward
			return next(err)

		# Chain
		@


	# =================================
	# Helpers

	getIgnoreOpts: ->
		return _.pick(@config, 'ignorePaths', 'ignoreHiddenFiles', 'ignoreCommonPatterns', 'ignoreCustomPatterns')

	# Is Ignored Path
	isIgnoredPath: (path,opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts)
		return ignorefs.isIgnoredPath(path, opts)

	# Scan Directory
	scandir: (opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts)
		return balUtil.scandir(opts)

	# Watch Directory
	watchdir: (opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts, @config.watchOptions)
		return require('watchr').watch(opts)


	# =================================
	# Setup and Loading

	# Ready
	# next(err,docpadInstance)
	ready: (opts,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()

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
		docpad.log 'info', util.format(locale.welcome, @getVersionString())
		docpad.log 'notice', locale.welcomeDonate
		docpad.log 'info', locale.welcomeContribute
		docpad.log 'info', util.format(locale.welcomePlugins, pluginsList)
		docpad.log 'info', util.format(locale.welcomeEnvironment, @getEnvironment())

		# Prepare
		tasks = new TaskGroup 'ready tasks', next:(err) ->
			# Error?
			return docpad.error(err)  if err

			# All done, forward our DocPad instance onto our creator
			return next?(null,docpad)

		tasks.addTask 'welcome event', (complete) ->
			# No welcome
			return complete()  unless config.welcome

			# Welcome
			docpad.emitSerial('welcome', {docpad}, complete)

		tasks.addTask 'track', (complete) ->
			# Identify
			return docpad.identify(complete)

		tasks.addTask 'emit docpadReady', (complete) ->
			docpad.emitSerial('docpadReady', {docpad}, complete)

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
		@

	# Set Instance Configuration
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config
		@

	# Set Configuration
	# next(err,config)
	setConfig: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()

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
		docpad.mergeConfigurations(configPackages, configsToMerge)

		# Extract and apply the server
		@setServer extendr.safeShallowExtendPlainObjects({
			serverHttp: @config.serverHttp
			serverExpress: @config.serverExpress
		},  @config.server)

		# Extract and apply the logger
		@setLogLevel(@config.logLevel)

		# Resolve any paths
		@config.rootPath = pathUtil.resolve(@config.rootPath)
		@config.outPath = pathUtil.resolve(@config.rootPath, @config.outPath)
		@config.srcPath = pathUtil.resolve(@config.rootPath, @config.srcPath)
		@config.databaseCachePath = pathUtil.resolve(@config.rootPath, @config.databaseCachePath)
		@config.packagePath = pathUtil.resolve(@config.rootPath, @config.packagePath)

		# Resolve Documents, Files, Layouts paths
		for type in ['documents','files','layouts']
			typePaths = @config[type+'Paths']
			for typePath,key in typePaths
				typePaths[key] = pathUtil.resolve(@config.srcPath, typePath)

		# Resolve Plugins paths
		for type in ['plugins']
			typePaths = @config[type+'Paths']
			for typePath,key in typePaths
				typePaths[key] = pathUtil.resolve(@config.rootPath, typePath)

		# Bind the error handler, so we don't crash on errors
		process.removeListener('uncaughtException', @error)
		@removeListener('error', @error)
		if @config.catchExceptions
			process.setMaxListeners(0)
			process.on('uncaughtException', @error)
			@on('error', @error)

		# Prepare the Post Tasks
		postTasks = new TaskGroup 'setConfig post tasks', next:(err) ->
			return next(err, docpad.config)

		###
		postTasks.addTask 'lazy depedencnies: encoding', (complete) =>
			return complete()  unless @config.detectEncoding
			return lazyRequire 'encoding', {cwd:corePath, stdio:'inherit'}, (err) ->
				docpad.warn(locale.encodingLoadFailed)  if err
				return complete()
		###

		postTasks.addTask 'load plugins', (complete) ->
			docpad.loadPlugins(complete)

		postTasks.addTask 'extend collections', (complete) ->
			docpad.extendCollections(complete)

		postTasks.addTask 'fetch plugins templateData', (complete) ->
			docpad.emitSerial('extendTemplateData', {templateData:docpad.pluginsTemplateData}, complete)

		postTasks.addTask 'fire the docpadLoaded event', (complete) ->
			docpad.emitSerial('docpadLoaded', complete)

		# Fire post tasks
		postTasks.run()

		# Chain
		@


	# Load Configuration
	# next(err,config)
	load: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
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
		preTasks = new TaskGroup 'load tasks', next:(err) =>
			return next(err)  if err
			return @setConfig(next)

		preTasks.addTask 'normalize the userConfigPath', (complete) =>
			safeps.getHomePath (err,homePath) =>
				return complete(err)  if err
				dropboxPath = pathUtil.resolve(homePath, 'Dropbox')
				safefs.exists dropboxPath, (dropboxPathExists) =>
					# @TODO: Implement checks here for
					# https://github.com/bevry/docpad/issues/799
					userConfigDirPath = if dropboxPathExists then dropboxPath else homePath
					@userConfigPath = pathUtil.resolve(userConfigDirPath, @userConfigPath)
					return complete()

		preTasks.addTask "load the user's configuration", (complete) =>
			configPath = @userConfigPath
			docpad.log 'debug', util.format(locale.loadingUserConfig, configPath)
			@loadConfigPath {configPath}, (err,data) =>
				return complete(err)  if err

				# Apply loaded data
				extendr.extend(@userConfig, data or {})

				# Done
				docpad.log 'debug', util.format(locale.loadingUserConfig, configPath)
				return complete()

		preTasks.addTask "load the anonymous user's configuration", (complete) =>
			# Ignore if username is already identified
			return complete()  if @userConfig.username

			# User is anonymous, set their username to the hashed and salted mac address
			require('getmac').getMac (err,macAddress) =>
				if err or !macAddress
					return docpad.trackError(err or new Error('no mac address'), complete)

				# Hash with salt
				try
					macAddressHash = require('crypto').createHmac('sha1', docpad.hashKey).update(macAddress).digest('hex')
				catch err
					return complete()  if err

				# Apply
				if macAddressHash
					@userConfig.name ?= "MAC #{macAddressHash}"
					@userConfig.username ?= macAddressHash

				# Next
				return complete()

		preTasks.addTask "load the website's package data", (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			configPath = pathUtil.resolve(rootPath, @instanceConfig.packagePath or @initialConfig.packagePath)
			docpad.log 'debug', util.format(locale.loadingWebsitePackageConfig, configPath)
			@loadConfigPath {configPath}, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				@websitePackageConfig = data

				# Done
				docpad.log 'debug', util.format(locale.loadedWebsitePackageConfig, configPath)
				return complete()

		preTasks.addTask "read the .env file if it exists", (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @websitePackageConfig.rootPath or @initialConfig.rootPath)
			configPath = pathUtil.resolve(rootPath, '.env')
			docpad.log 'debug', util.format(locale.loadingEnvConfig, configPath)
			safefs.exists configPath, (exists) ->
				return complete()  unless exists
				require('envfile').parseFile configPath, (err,data) ->
					return complete(err)  if err
					for own key,value of data
						process.env[key] = value
					docpad.log 'debug', util.format(locale.loadingEnvConfig, configPath)
					return complete()

		preTasks.addTask "load the website's configuration", (complete) =>
			docpad.log 'debug', util.format(locale.loadingWebsiteConfig)
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			configPaths = @instanceConfig.configPaths or @initialConfig.configPaths
			for configPath, index in configPaths
				configPaths[index] = pathUtil.resolve(rootPath, configPath)
			@loadConfigPath {configPaths}, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				extendr.extend(@websiteConfig, data)

				# Done
				docpad.log 'debug', util.format(locale.loadedWebsiteConfig)
				return complete()

		# Run the load tasks synchronously
		preTasks.run()

		# Chain
		@


	# =================================
	# Configuration

	# Update User Configuration
	updateUserConfig: (data={},next) ->
		# Prepare
		[data,next] = extractOptsAndCallback(data,next)
		docpad = @
		userConfigPath = @userConfigPath

		# Apply back to our loaded configuration
		# does not apply to @config as we would have to reparse everything
		# and that appears to be an imaginary problem
		extendr.extend(@userConfig, data)  if data

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
		docpad = @
		locale = @getLocale()

		# Log
		docpad.log 'debug', util.format(locale.loadingConfigUrl, configUrl)

		# Read the URL
		superAgent
			.get(configUrl)
			.timeout(30*1000)
			.end (err,res) ->
				# Check
				return next(err)  if err

				# Read the string using CSON
				CSON.parse(res.text, next)

		# Chain
		@

	# Load the configuration path
	# next(err,parsedData)
	loadConfigPath: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()

		# Prepare
		load = (configPath) ->
			# Check
			return next()  unless configPath

			# Log
			docpad.log 'debug', util.format(locale.loadingConfigPath, configPath)

			# Check that it exists
			safefs.exists configPath, (exists) ->
				return next()  unless exists

				# Read the path using CSON
				CSON.parseFile configPath, (err,result) ->
					if err
						docpad.log 'error', util.format(locale.loadingConfigPathFailed, configPath)
					return next(err, result)

		# Check
		if opts.configPath
			load(opts.configPath)
		else
			@getConfigPath opts, (err,configPath) ->
				load(configPath)

		# Chain
		@

	# Get Config Path
	# next(err,path)
	getConfigPath: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()
		result = null

		# Ensure array
		opts.configPaths ?= config.configPaths
		opts.configPaths = [opts.configPaths]  unless typeChecker.isArray(opts.configPaths)

		tasks = new TaskGroup 'getConfigPath tasks', next:(err) ->
			return next(err, result)

		# Determine our configuration path
		opts.configPaths.forEach (configPath) ->
			tasks.addTask "Checking if [#{configPath}] exists", (complete) ->
				return complete()  if result
				safefs.exists configPath, (exists) ->
					if exists
						result = configPath
						tasks.clear()
						complete()
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
		docpadConfig = @getConfig()
		locale = @getLocale()
		database = @getDatabase()

		# Standard Collections
		@setCollections({
			# Standard Collections
			documents: database.createLiveChildCollection()
				.setQuery('isDocument', {
					render: true
					write: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingDocument, model.getFilePath()))
				)
			files: database.createLiveChildCollection()
				.setQuery('isFile', {
					render: false
					write: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingFile, model.getFilePath()))
				)
			layouts: database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isLayout: true
						fullPath: $startsWith: docpadConfig.layoutsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingLayout, model.getFilePath()))
					model.setDefaults({
						isLayout: true
						render: false
						write: false
					})
				)

			# Special Collections
			generate: database.createLiveChildCollection()
				.setQuery('generate', {
					dynamic: false
					ignored: false
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingGenerate, model.getFilePath()))
				)
			referencesOthers: database.createLiveChildCollection()
				.setQuery('referencesOthers', {
					dynamic: false
					ignored: false
					referencesOthers: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingReferencesOthers, model.getFilePath()))
				)
			hasLayout: database.createLiveChildCollection()
				.setQuery('hasLayout', {
					dynamic: false
					ignored: false
					layout: $exists: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingHasLayout, model.getFilePath()))
				)
			html: database.createLiveChildCollection()
				.setQuery('isHTML', {
					write: true
					outExtension: 'html'
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingHtml, model.getFilePath()))
				)
			stylesheet: database.createLiveChildCollection()
				.setQuery('isStylesheet', {
					write: true
					outExtension: 'css'
				})
		})

		# Blocks
		@setBlocks({
			meta: new MetaCollection()
			scripts: new ScriptsCollection()
			styles: new StylesCollection()
		})

		# Custom Collections Group
		tasks = new TaskGroup "extendCollections tasks", concurrency:0, next:(err) ->
			docpad.error(err)  if err
			docpad.emitSerial('extendCollections', next)

		# Cycle through Custom Collections
		eachr docpadConfig.collections or {}, (fn,name) ->
			tasks.addTask "creating the custom collection: #{name}", (complete) ->
				# Init
				ambi [fn.bind(docpad), fn], database, (err, collection) ->
					# Check for error
					if err
						docpad.error(err)
						return complete()

					# Check the type of the collection
					else unless collection instanceof QueryCollection
						docpad.log 'warn', util.format(locale.errorInvalidCollection, name)
						return complete()

					# Make it a live collection
					collection.live(true)  if collection

					# Apply the collection
					docpad.setCollection(name, collection)
					return complete()

		# Run Custom collections
		tasks.run()

		# Chain
		@

	# Reset Collections
	# next(err)
	resetCollections: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		database = docpad.getDatabase()

		# Make it as if we have never generated before
		docpad.generated = false

		# Perform a complete clean of our collections
		database.reset([])
		meta = @getBlock('meta').reset([])
		scripts = @getBlock('scripts').reset([])
		styles = @getBlock('styles').reset([])
		# ^ Backbone.js v1.1 changes the return values of these, however we change that in our Element class
		# because if we didn't, all our skeletons would fail

		# Add default block entries
		meta.add("""<meta name="generator" content="DocPad v#{docpad.getVersion()}" />""")  if docpad.getConfig().poweredByDocPad isnt false

		# Reset caches
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}

		# Chain
		next()
		@

	# Init Git Repo
	# next(err,results)
	initGitRepo: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= @getDebugging()

		# Forward
		safeps.initGitRepo(opts, next)

		# Chain
		@

	# Init Node Modules
	# next(err,results)
	initNodeModules: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= docpad.getDebugging()
		opts.force ?= if config.offline then false else true
		# ^ @todo this line causes --force to be added, when it shouldn't be
		opts.args ?= []
		opts.args.push('--force')  if config.force
		opts.args.push('--no-registry')  if config.offline

		# Log
		docpad.log('info', 'npm install')  if opts.output

		# Forward
		safeps.initNodeModules(opts, next)

		# Chain
		@

	# Fix Node Package Versions
	# Combat to https://github.com/npm/npm/issues/4587#issuecomment-35370453
	# next(err)
	fixNodePackageVersions: (opts) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.packagePath ?= config.packagePath

		# Read and replace
		safefs.readFile opts.packagePath, (err,buffer) ->
			data = buffer.toString()
			data = data.replace(/("docpad(?:.*?)": ")\^/g, '$1~')
			safefs.writeFile opts.packagePath, data, (err) ->
				return next(err)

		# Chain
		@

	# Install Node Module
	# next(err,result)
	installNodeModule: (names,opts) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= docpad.getDebugging()
		opts.args ?= []

		opts.global ?= false
		opts.global = ['--global']             if opts.global is true
		opts.global = [opts.global]            if opts.global and Array.isArray(opts.global) is false

		opts.save ?= !opts.global
		opts.save = ['--save']                 if opts.save is true
		opts.save = [opts.save]                if opts.save and Array.isArray(opts.save) is false

		# Command
		command = ['npm', 'install']

		# Names
		names = names.split(/[,\s]+/)  unless typeChecker.isArray(names)
		names.forEach (name) ->
			# Check
			return  unless name

			# Ensure latest if version isn't specfied
			name += '@latest'  if name.indexOf('@') is -1

			# Push the name to the commands
			command.push(name)

		# Arguments
		command.push(opts.args...)
		command.push('--force')           if config.force
		command.push('--no-registry')     if config.offline
		command.push(opts.save...)        if opts.save
		command.push(opts.global...)      if opts.global

		# Log
		docpad.log('info', command.join(' '))  if opts.output

		# Forward
		safeps.spawn(command, opts, next)

		# Chain
		@

	# Uninstall Node Module
	# next(err,result)
	uninstallNodeModule: (names,opts) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= docpad.getDebugging()
		opts.args ?= []

		opts.global ?= false
		opts.global = ['--global']             if opts.global is true
		opts.global = [opts.global]            if opts.global and Array.isArray(opts.global) is false

		opts.save ?= !opts.global
		opts.save = ['--save', '--save-dev']   if opts.save is true
		opts.save = [opts.save]                if opts.save and Array.isArray(opts.save) is false

		# Command
		command = ['npm', 'uninstall']

		# Names
		names = names.split(/[,\s]+/)  unless typeChecker.isArray(names)
		command.push(names...)

		# Arguments
		command.push(opts.args...)
		command.push(opts.save...)        if opts.save
		command.push(opts.global...)      if opts.global

		# Log
		docpad.log('info', command.join(' '))  if opts.output

		# Forward
		safeps.spawn(command, opts, next)

		# Chain
		@



	# =================================
	# Logging

	# Set Log Level
	setLogLevel: (level) ->
		@getLogger().setConfig({level})
		if level is 7
			loggers = @getLoggers()
			if loggers.debug? is false
				try require('longjohn')  # better error stack traces
				loggers.debug = loggers.logger
					.pipe(
						new (require('caterpillar-human').Human)(color:false)
					)
					.pipe(
						require('fs').createWriteStream(@debugLogPath)
					)
		@

	# Are we debugging?
	getLogLevel: ->
		return @getConfig().logLevel

	# Are we debugging?
	getDebugging: ->
		return @getLogLevel() is 7

	# Handle a fatal error
	fatal: (err) =>
		docpad = @
		config = @getConfig()

		# Check
		return @  unless err

		# Handle
		@error err, 'err', ->
			process.stderr.write require('util').inspect(err.stack or err.message)
			docpad.destroy()

		# Chain
		@

	# Log
	log: (args...) =>
		# Log
		logger = @getLogger() or console
		logger.log.apply(logger, args)

		# Chain
		@

	# Handle an error
	error: (err,type='err',next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Check if we have already logged this error
		if !err or err.logged
			next?()
		else
			# Log the error only if it hasn't been logged already
			err.logged = true
			err = new Error(err)  unless err.message?
			err.logged = true
			message = (err.stack ? err.message).toString().trim()
			docpad.log(type, locale.errorOccured, '\n'+message)
			docpad.log('error', locale.errorSubmission)
			docpad.notify(err.message, title:locale.errorOccured)

			# Track
			@trackError(err, next)

		# Chain
		@

	# Track error
	trackError: (err,next) ->
		# PRepare
		docpad = @
		config = @getConfig()

		# Track
		if config.offline is false and config.reportErrors
			data = {}
			data.message = err.message
			data.stack = err.stack.toString()  if err.stack
			data.config = config
			data.env = process.env
			docpad.track('error', data, next)
		else
			setImmediate ->  # avoid zalgo
				next?()

		# Chain
		@

	# Handle a warning
	warn: (message,err,next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Log
		docpad.log('warn', message)
		docpad.error(err, 'warn', next)  if err
		docpad.notify(message, title:locale.warnOccured)

		# Chain
		@

	# Send a notify event to plugins (like growl)
	notify: (message,options={}) =>
		# Prepare
		docpad = @

		# Emit
		docpad.emitSerial 'notify', {message,options}, (err) ->
			docpad.error(err)  if err

		# Chain
		@

	# Check Request
	checkRequest: (next) ->
		next ?= @error.bind(@)
		return (err,res) ->
			# Check
			return next(err, res)  if err

			# Check
			if res.body?.success is false or res.body?.error
				err = new Error(res.body.error or 'unknown request error')
				return next(err, res)

			# Success
			return next(null, res)

	# Subscribe
	# next(err)
	subscribe: (next) ->
		# Prepare
		config = @getConfig()

		# Check
		if config.offline is false
			if @userConfig?.email
				# Data
				data = {}
				data.email = @userConfig.email  # required
				data.name = @userConfig.name or null
				data.username = @userConfig.username or null

				# Apply
				superAgent
					.post(config.helperUrl)
					.type('json').set('Accept', 'application/json')
					.query(
						method: 'add-subscriber'
					)
					.send(data)
					.timeout(30*1000)
					.end @checkRequest next
			else
				err = new Error('Email not provided')
				next?(err)
		else
			next?()

		# Chain
		@

	# Track
	# next(err)
	track: (name,things={},next) ->
		# Prepare
		docpad = @
		config = @getConfig()

		# Check
		if config.offline is false and config.reportStatistics
			# Data
			data = {}
			data.userId = @userConfig.username or null
			data.event = name
			data.properties = things

			# Things
			things.websiteName = @websitePackageConfig.name  if @websitePackageConfig?.name
			things.platform = @getProcessPlatform()
			things.environment = @getEnvironment()
			things.version = @getVersion()
			things.nodeVersion = @getProcessVersion()

			# Plugins
			eachr docpad.loadedPlugins, (value,key) ->
				things['plugin-'+key] = value.version or true

			# Apply
			trackRunner = docpad.getTrackRunner()
			trackRunner.addTask 'track task', (complete) ->
				superAgent
					.post(config.helperUrl)
					.type('json').set('Accept', 'application/json')
					.query(
						method: 'analytics'
						action: 'track'
					)
					.send(data)
					.timeout(30*1000)
					.end docpad.checkRequest (err) ->
						next?(err)
						complete(err)  # we pass the error here, as if we error, we want to stop all tracking

			# Execute the tracker tasks 
			trackRunner.run()
		else
			next?()

		# Chain
		@

	# Identify
	# next(err)
	identify: (next) ->
		# Prepare
		docpad = @
		config = @getConfig()

		# Check
		if config.offline is false and config.reportStatistics and @userConfig?.username
			# Data
			data = {}
			data.userId = @userConfig.username  # required
			data.traits = things = {}

			# Things
			now = new Date()
			things.username = @userConfig.username  # required
			things.email = @userConfig.email or null
			things.name = @userConfig.name or null
			things.lastLogin = now.toISOString()
			things.lastSeen = now.toISOString()
			things.countryCode = safeps.getCountryCode()
			things.languageCode = safeps.getLanguageCode()
			things.platform = @getProcessPlatform()
			things.version = @getVersion()
			things.nodeVersion = @getProcessVersion()

			# Is this a new user?
			if docpad.userConfig.identified isnt true
				# Update
				things.created = now.toISOString()

				# Create the new user
				docpad.getTrackRunner().addTask 'create new user', (complete) ->
					superAgent
						.post(config.helperUrl)
						.type('json').set('Accept', 'application/json')
						.query(
							method: 'analytics'
							action: 'identify'
						)
						.send(data)
						.timeout(30*1000)
						.end docpad.checkRequest (err) =>
							# Save the changes with these
							docpad.updateUserConfig(identified:true)

							# Complete
							return complete(err)

			# Or an existing user?
			else
				# Update the existing user's information witht he latest
				docpad.getTrackRunner().addTask 'update user', (complete) =>
					superAgent
						.post(config.helperUrl)
						.type('json').set('Accept', 'application/json')
						.query(
							method: 'analytics'
							action: 'identify'
						)
						.send(data)
						.timeout(30*1000)
						.end docpad.checkRequest complete

		# Chain
		next?()
		@


	# =================================
	# Models and Collections

	# ---------------------------------
	# b/c compat functions

	# Create File
	createFile: (attrs={},opts={}) ->
		opts.modelType = 'file'
		return @createModel(attrs, opts)

	# Create Document
	createDocument: (attrs={},opts={}) ->
		opts.modelType = 'document'
		return @createModel(attrs, opts)

	# Parse File Directory
	parseFileDirectory: (opts={},next) ->
		opts.modelType ?= 'file'
		opts.collection ?= @getDatabase()
		return @parseDirectory(opts, next)

	# Parse Document Directory
	parseDocumentDirectory: (opts={},next) ->
		opts.modelType ?= 'document'
		opts.collection ?= @getDatabase()
		return @parseDirectory(opts, next)


	# ---------------------------------
	# Standard functions

	# Attach Model Events
	attachModelEvents: (model) ->
		# Prepare
		docpad = @

		# Only attach events if we haven't already done so
		if model.attachedDocumentEvents isnt true
			model.attachedDocumentEvents = true

			# Attach document events
			if model.type is 'document'
				# Clone
				model.on 'clone', (clonedModel) ->
					docpad.attachModelEvents(clonedModel)

				# Render
				model.on 'render', (args...) ->
					docpad.emitSerial('render', args...)

				# Render document
				model.on 'renderDocument', (args...) ->
					docpad.emitSerial('renderDocument', args...)

				# Fetch a layout
				model.on 'getLayout', (opts={},next) ->
					opts.collection = docpad.getCollection('layouts')
					layout = docpad.getFileBySelector(opts.selector, opts)
					next(null, {layout})

			# Remove
			#model.on 'remove', (file) ->
			#	docpad.getDatabase().remove(file)
			# ^ Commented out as for some reason this stops layouts from working

			# Error
			model.on 'error', (args...) ->
				docpad.error(args...)

			# Log
			model.on 'log', (args...) ->
				docpad.log(args...)

		# Chain
		@

	# Add Model
	addModel: (model, opts) ->
		model = @createModel(model, opts)
		@getDatabase().add(model)
		return model

	# Add Models
	addModels: (models, opts) ->
		models = @createModels(models, opts)
		@getDatabase().add(models)
		return models

	# Create Models
	createModels: (models, opts) ->
		for model in models
			@createModel(model, opts)
		# return the for loop results

	# Create Model
	createModel: (attrs={},opts={}) ->
		# Check
		if attrs instanceof FileModel
			return attrs

		# Prepare
		docpad = @
		config = @getConfig()
		database = @getDatabase()
		fileFullPath = attrs.fullPath or null


		# Find or create
		# This functionality use to be inside ensureModel
		# But that caused duplicates in some instances
		# So now we will always check
		if attrs.fullPath
			result = database.findOne(fullPath: attrs.fullPath)
			if result
				return result


		# -----------------------------
		# Try and determine the model type

		# If the type hasn't been specified try and detemrine it based on the full path
		if fileFullPath
			# Check if we have a document or layout
			unless opts.modelType
				for dirPath in config.documentsPaths.concat(config.layoutsPaths)
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'document'
						break

			# Check if we have a file
			unless opts.modelType
				for dirPath in config.filesPaths
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'file'
						break

		# -----------------------------
		# Create the appropriate emodel

		# Extend the opts with things we need
		opts = extendr.extend({
			detectEncoding: config.detectEncoding
			rootOutDirPath: config.outPath
			locale: @getLocale()
		}, opts)

		if opts.modelType is 'file'
			# Create a file model
			model = new FileModel(attrs, opts)
		else
			# Create document model
			model = new DocumentModel(attrs, opts)

		# -----------------------------
		# Finish up

		# Attach Events
		@attachModelEvents(model)

		# Return
		return model

	# Parse a directory
	# next(err, files)
	parseDirectory: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()

		# Extract
		{path,createFunction} = opts
		createFunction ?= @createModel
		files = opts.collection or new FilesCollection()

		# Check if the directory exists
		safefs.exists path, (exists) ->
			# Check
			unless exists
				# Log
				docpad.log 'debug', util.format(locale.renderDirectoryNonexistant, path)

				# Forward
				return next()

			# Log
			docpad.log 'debug', util.format(locale.renderDirectoryParsing, path)

			# Files
			docpad.scandir(
				# Path
				path: path

				# File Action
				fileAction: (fileFullPath,fileRelativePath,nextFile,fileStat) ->
					# Prepare
					data =
						fullPath: fileFullPath
						relativePath: fileRelativePath
						stat: fileStat

					# Create file
					file = createFunction.call(docpad, data, opts)

					# Update the file's stat
					# To ensure changes files are handled correctly in generation
					file.action 'load', (err) ->
						# Error?
						return nextFile(err)  if err

						# Add the file to the collection
						files.add(file)

						# Next
						nextFile()

				# Next
				next: (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.renderDirectoryParsed, path)

					# Forward
					return next(null, files)
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

	# Destroy plugins
	destroyPlugins: ->
		for own name,plugin of @loadedPlugins
			plugin.destroy()
			@loadedPlugins[name] = null
		@

	# Load Plugins
	# next(err)
	loadPlugins: (next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Snore
		@slowPlugins = {}
		snore = balUtil.createSnore ->
			docpad.log 'notice', util.format(locale.pluginsSlow, Object.keys(docpad.slowPlugins).join(', '))

		# Async
		tasks = new TaskGroup "loadPlugins tasks", concurrency:0, next:(err) ->
			docpad.slowPlugins = {}
			snore.clear()
			return next(err)

		# Load website plugins
		(@config.pluginsPaths or []).forEach (pluginsPath) ->
			tasks.addTask "load the website's plugins at: #{pluginsPath}", (complete) ->
				safefs.exists pluginsPath, (exists) ->
					return complete()  unless exists
					docpad.loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		(@config.pluginPaths or []).forEach (pluginPath) ->
			tasks.addTask "load custom plugins at: #{pluginPath}", (complete) ->
				safefs.exists pluginPath, (exists) ->
					return complete()  unless exists
					docpad.loadPlugin(pluginPath, complete)

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
						if unsupported in ['version-docpad','version-plugin'] and config.skipUnsupportedPlugins is false
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
	# next(err)
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
				return _nextFile(null, false)  if fileFullPath is pluginsPath
				nextFile = (err,skip) ->
					if err
						message = util.format(locale.pluginFailedToLoad, pluginName, fileFullPath)+' '+locale.errorFollows
						docpad.warn(message, err)
					return _nextFile(null, skip)

				# Forward
				docpad.loadPlugin fileFullPath, (err) ->
					return nextFile(err, true)

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
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Check
		return @  if config.offline or !config.checkVersion

		# Check
		balUtil.packageCompare(
			local: @packagePath
			remote: config.latestPackageUrl
			newVersionCallback: (details) ->
				isLocalInstallation = docpadUtil.isLocalDocPadExecutable()
				message = (if isLocalInstallation then locale.versionOutdatedLocal else locale.versionOutdatedGlobal)
				currentVersion = 'v'+details.local.version
				latestVersion = 'v'+details.remote.version
				upgradeUrl = details.local.upgradeUrl or details.remote.installUrl or details.remote.homepage
				messageFilled = util.format(message, currentVersion, latestVersion, upgradeUrl)
				docpad.notify(latestVersion, title:locale.versionOutdatedNotification)
				docpad.log('notice', messageFilled)
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
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Check if it is stored locally
		return next(null, docpad.exchange)  if typeChecker.isEmptyObject(docpad.exchange) is false

		# Offline?
		return next(null, null)  if config.offline

		# Log
		docpad.log('info', locale.exchangeUpdate+' '+locale.pleaseWait)

		# Otherwise fetch it from the exchangeUrl
		exchangeUrl = config.exchangeUrl+'?version='+@version
		docpad.loadConfigUrl exchangeUrl, (err,parsedData) ->
			# Check
			if err
				locale = docpad.getLocale()
				docpad.log('notice', locale.exchangeError+' '+locale.errgdorFollows, err)
				return next()

			# Log
			docpad.log('info', locale.exchangeUpdated)

			# Success
			docpad.exchange = parsedData
			return next(null, parsedData)

		# Chain
		@


	# ---------------------------------
	# Utilities: Files

	# Contextualize files
	# next(err)
	contextualizeFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("contextualizeFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.contextualizingFiles, collection.length)

		# Start contextualizing
		docpad.emitSerial 'contextualizeBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = new TaskGroup "contextualizeFiles tasks", concurrency:0, next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("contextualizeFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'contextualizeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.contextualizedFiles, collection.length)

					# Forward
					return next()

			# Add contextualize tasks
			opts.progress?.step('contextualizeFiles').total(collection.length).setTick(0)
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				slowFilesObject[file.id] = file.get('relativePath') or file.id
				tasks.addTask "conextualizing: #{filePath}", (complete) ->
					file.action 'contextualize', (err) ->
						delete slowFilesObject[file.id]
						opts.progress?.tick()
						return complete(err)

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'contextualizeFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@

	# Render files
	# next(err)
	renderFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData,renderPasses} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("renderFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.renderingFiles, collection.length)

		# Render File
		# next(null, outContent, file)
		renderFile = (file,next) ->
			# Render
			if file.get('render') is false or !file.get('relativePath')
				file.attributes.rtime = new Date()
				next(null, file.getOutContent(), file)
			else
				file.action('render', {templateData}, next)

			# Return
			return file

		# Render Collection
		renderCollection = (collectionToRender,{renderPass},next) ->
			# Plugin Event
			docpad.emitSerial 'renderCollectionBefore', {collection:collectionToRender,renderPass}, (err) =>
				# Prepare
				return next(err)  if err

				subTasks = new TaskGroup "renderCollection: #{collectionToRender.options.name}", concurrency:0, next:(err) ->
					# Prepare
					return next(err)  if err

					# Plugin Event
					docpad.emitSerial('renderCollectionAfter', {collection:collectionToRender,renderPass}, next)

				# Cycle
				opts.progress?.step("renderFiles (pass #{renderPass})").total(collectionToRender.length).setTick(0)
				collectionToRender.forEach (file) ->
					filePath = file.getFilePath()
					slowFilesObject[file.id] = file.get('relativePath')
					subTasks.addTask "rendering: #{filePath}", (complete) ->
						renderFile file, (err) ->
							delete slowFilesObject[file.id] or file.id
							opts.progress?.tick()
							return complete(err)

				# Return
				subTasks.run()
				return collectionToRender

		# Plugin Event
		docpad.emitSerial 'renderBefore', {collection,templateData}, (err) =>
			# Prepare
			return next(err)  if err

			# Async
			tasks = new TaskGroup "renderCollection: renderBefore tasks", next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("renderFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'renderAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.renderedFiles, collection.length)

					# Forward
					return next()

			# Queue the initial render
			initialCollection = collection.findAll('referencesOthers':false)
			subsequentCollection = null
			tasks.addTask "rendering the initial collection", (complete) ->
				renderCollection initialCollection, {renderPass:1}, (err) ->
					return complete(err)  if err
					subsequentCollection = collection.findAll('referencesOthers':true)
					renderCollection(subsequentCollection, {renderPass:2}, complete)

			# Queue the subsequent renders
			if renderPasses > 1
				[3..renderPasses].forEach (renderPass) ->  tasks.addTask "rendering the subsequent collection index #{renderPass}", (complete) ->
					renderCollection(subsequentCollection, {renderPass}, complete)

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'renderFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@

	# Write files
	# next(err)
	writeFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("writeFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.writingFiles, collection.length)

		# Plugin Event
		docpad.emitSerial 'writeBefore', {collection,templateData}, (err) =>
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = new TaskGroup "writeFiles tasks", concurrency:0, next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("writeFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'writeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# docpad.log 'debug', util.format(locale.wroteFiles, collection.length)
					return next()

			# Add write tasks
			opts.progress?.step('writeFiles').total(collection.length).setTick(0)
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				tasks.addTask "writing the file: #{filePath}", (complete) ->
					# Prepare
					slowFilesObject[file.id] = file.get('relativePath')

					# Create sub tasks
					fileTasks = new TaskGroup "tasks for file write: #{filePath}", concurrency:0, next:(err) ->
						delete slowFilesObject[file.id]
						opts.progress?.tick()
						return complete(err)

					# Write out
					if file.get('write') isnt false and file.get('dynamic') isnt true and file.get('outPath')
						fileTasks.addTask "write out", (complete) ->
							file.action('write', complete)

					# Write source
					if file.get('writeSource') is true and file.get('fullPath')
						fileTasks.addTask "write source", (complete) ->
							file.action('writeSource', complete)

					# Run sub tasks
					fileTasks.run()

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'writeFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Helpers
	generateStarted: null
	generateEnded: null
	generating: false
	generated: false  # true once the first generation has occured

	# Create Progress Bar
	createProgress: ->
		# Prepare
		docpad = @
		config = docpad.getConfig()

		# Only show progress if
		# - prompts are supported (so no servers)
		# - and we are log level 6 (the default level)
		progress = null
		if config.prompts and @getLogLevel() is 6
			progress = require('progressbar').create()
			@getLoggers().console.unpipe(process.stdout)
			@getLogger().once 'log', progress.logListener ?= (data) ->
				if data.levelNumber <= 5  # notice or higher
					docpad.destroyProgress(progress)

		# Return
		return progress

	# Destroy Progress Bar
	destroyProgress: (progress) ->
		# Fetch
		if progress
			progress.finish()
			@getLoggers().console.unpipe(process.stdout).pipe(process.stdout)

		# Return
		return progress

	# Destroy Regenerate Timer
	destroyRegenerateTimer: ->
		# Prepare
		docpad = @

		# Clear Regenerate Timer
		if docpad.regenerateTimer
			clearInterval(docpad.regenerateTimer)
			docpad.regenerateTimer = null

		# Chain
		@

	# Create Regenerate Timer
	createRegenerateTimer: ->
		# Prepare
		docpad = @
		locale = docpad.getLocale()
		config = docpad.getConfig()

		# Create Regenerate Timer
		if config.regenerateEvery
			docpad.regenerateTimer = setTimeout(
				->
					docpad.log('info', locale.renderInterval)
					docpad.action('generate', config.regenerateEveryOptions)
				config.regenerateEvery
			)

		# Chain
		@

	# Generate
	# next(err)
	generate: (opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = docpad.getConfig()
		locale = docpad.getLocale()
		database = docpad.getDatabase()

		# Check
		return next()  if opts.collection?.length is 0


		# Update generating flag
		lastGenerateStarted = docpad.generateStarted
		docpad.generateStarted = new Date()
		docpad.generateEnded = null
		docpad.generating = true

		# Update the cached database
		docpad.databaseTempCache = new FilesCollection(database.models)  if database.models.length

		# Create Progress
		# Can be over-written by API calls
		opts.progress ?= docpad.createProgress()

		# Grab the template data we will use for rendering
		opts.templateData = docpad.getTemplateData(opts.templateData or {})

		# How many render passes will we require?
		# Can be over-written by API calls
		opts.renderPasses or= config.renderPasses


		# Destroy Regenerate Timer
		docpad.destroyRegenerateTimer()

		# Check plugin count
		docpad.log('notice', locale.renderNoPlugins)  unless docpad.hasPlugins()

		# Log
		docpad.log('info', locale.renderGenerating)
		docpad.notify (new Date()).toLocaleTimeString(), title: locale.renderGeneratingNotification


		# Tasks
		tasks = new TaskGroup("generate tasks")

			.on('item.run', (item) ->
				totals = tasks.getTotals()
				opts.progress?.step("generate: #{item.getConfig().name}").total(totals.total).setTick(totals.completed)
			)

			.done((err) ->
				# Update generating flag
				docpad.generating = false
				docpad.generateEnded = new Date()

				# Update caches
				docpad.databaseTempCache = null

				# Create Regenerate Timer
				docpad.createRegenerateTimer()

				# Clear Progress
				if opts.progress
					docpad.destroyProgress(opts.progress)
					opts.progress = null

				# Error?
				return next(err)  if err

				# Log success message
				seconds = (docpad.generateEnded - docpad.generateStarted) / 1000
				howMany = "#{opts.collection?.length or 0}/#{database.length}"
				docpad.log 'info', util.format(locale.renderGenerated, howMany, seconds)
				docpad.notify (new Date()).toLocaleTimeString(), {title: locale.renderGeneratedNotification}

				# Generated
				if opts.initial is true
					docpad.generated = true
					return docpad.emitSerial('generated', opts, next)

				# Safety check if generated is false but initial was false too
				# https://github.com/bevry/docpad/issues/811
				else if docpad.generated is false
					return next(
						new Error('DocPad is in an invalid state, please report this on the github issue tracker. Reference 3360')
					)

				else
					return next()
			)

		# Extract functions from tasks for simplicity
		# when dealing with nested tasks/groups
		addGroup = tasks.addGroup.bind(tasks)
		addTask = tasks.addTask.bind(tasks)


		# Setup a clean database
		addTask 'Reset our collections', (complete) ->
			# Skip if we are not a reset generation, or an initial generation (generated is false)
			return complete()  unless opts.reset is true or docpad.generated is false
			return docpad.resetCollections(opts, complete)


		# Figure out the options
		# This is here as resetCollections could change our state
		# https://github.com/bevry/docpad/issues/811
		addTask 'Figure out options', ->
			# Mode: Cache
			# Shall we write to the database cache?
			# Set to true if the configuration option says we can, and we are the initial generation
			opts.cache     ?= config.databaseCache

			# Mode: Initial
			# Shall we do some basic initial checks
			# Set to the opts.reset value if specified, or whether are the initial generation
			opts.initial   ?= !(docpad.generated)

			# Mode: Reset
			# Shall we reset the database
			# Set to true if we are the initial generation
			opts.reset     ?= opts.initial

			# Mode: Populate
			# Shall we fetch in new data?
			# Set to the opts.reset value if specified, or the opts.initial value
			opts.populate  ?= opts.reset

			# Mode: Reload
			# Shall we rescan the file system for changes?
			# Set to the opts.reset value if specified, or the opts.initial value
			opts.reload    ?= opts.reset

			# Mode: Partial
			# Shall we perform a partial generation (false) or a completion generation (true)?
			# Set to false if we are the initial generation
			opts.partial   ?= !(opts.reset)

			# Log our opts
			docpad.log('debug', 'Generate options:', _.pick(opts, 'cache', 'initial', 'reset', 'populate', 'reload', 'partial', 'renderPasses'))


		# Check directory structure
		addTask 'check source directory exists', (complete) ->
			# Skip if we are not the initial generation
			return complete()  unless opts.initial is true

			# Continue if we are the initial generation
			safefs.exists config.srcPath, (exists) ->
				# Check
				unless exists
					err = new Error(locale.renderNonexistant)
					return complete(err)

				# Forward
				return complete()


		addGroup 'fetch data to render', (addGroup, addTask) ->
			# Fetch new data
			# If we are a populate generation (by default an initial generation)
			if opts.populate is true
				# This will pull in new data from plugins
				addTask 'populateCollectionsBefore', (complete) ->
					docpad.emitSerial('populateCollectionsBefore', opts, complete)

				# Import the cached data
				# If we are the initial generation, and we have caching enabled
				if opts.initial is true and opts.cache in [true, 'read']
					addTask 'import data from cache', (complete) ->
						# Check if we do have a databae cache
						safefs.exists config.databaseCachePath, (exists) ->
							return complete()  if exists is false

							# Read the database cache if it exists
							safefs.readFile config.databaseCachePath, (err, data) ->
								return complete(err)  if err

								# Parse it and apply the data values
								databaseData = JSON.parse data.toString()
								opts.cache     = true
								opts.initial   = true
								opts.reset     = false
								opts.populate  = true
								opts.reload    = true
								opts.partial   = true

								lastGenerateStarted = new Date(databaseData.generateStarted)
								addedModels = docpad.addModels(databaseData.models)
								docpad.log 'info', util.format(locale.databaseCacheRead, database.length, databaseData.models.length)

								# @TODO we need a way of detecting deleted files between generations

								return complete()

				# Rescan the file system
				# If we are a reload generation (by default an initial generation)
				# This is useful when the database is out of sync with the source files
				# For instance, someone shut down docpad, and made some changes, then ran docpad again
				# See https://github.com/bevry/docpad/issues/705#issuecomment-29243666 for details
				if opts.reload is true
					addGroup 'import data from file system', (addGroup, addTask) ->
						# Documents
						config.documentsPaths.forEach (documentsPath) ->
							addTask 'import documents', (complete) ->
								docpad.parseDirectory({
									modelType: 'document'
									collection: database
									path: documentsPath
									next: complete
								})

						# Files
						config.filesPaths.forEach (filesPath) ->
							addTask 'import files', (complete) ->
								docpad.parseDirectory({
									modelType: 'file'
									collection: database
									path: filesPath
									next: complete
								})

						# Layouts
						config.layoutsPaths.forEach (layoutsPath) ->
							addTask 'import layouts', (complete) ->
								docpad.parseDirectory({
									modelType: 'document'
									collection: database
									path: layoutsPath
									next: complete
								})

				# This will pull in new data from plugins
				addTask 'populateCollections', (complete) ->
					docpad.emitSerial('populateCollections', opts, complete)


		addGroup 'determine files to render', (addGroup, addTask) ->
			# Perform a complete regeneration
			# If we are a reset generation (by default an initial non-cached generation)
			if opts.partial is false
				# Use Entire Collection
				addTask 'Add all database models to render queue', ->
					opts.collection ?= new FilesCollection().add(docpad.getCollection('generate').models)

			# Perform a partial regeneration
			# If we are not a reset generation (by default any non-initial generation)
			else
				# Use Partial Collection
				addTask 'Add only changed models to render queue', ->
					changedQuery =
						$or:
							# Get changed files
							mtime: $gte: lastGenerateStarted

							# Get new files
							$and:
								wtime: null
								write: true
					opts.collection ?= new FilesCollection().add(docpad.getCollection('generate').findAll(changedQuery).models)


		addTask 'generateBefore', (complete) ->
			# If we have nothing to generate
			if opts.collection.length is 0
				# then there is no need to execute further tasks
				tasks.clear()
				complete()

			# Otherwise continue down the task loop
			else
				docpad.emitSerial('generateBefore', opts, complete)


		addTask 'prepare files', (complete) ->
			# Log the files to generate if we are in debug mode
			docpad.log 'debug', 'Files to generate at', (lastGenerateStarted), '\n', (
				{
					id: model.id
					path: model.getFilePath()
					mtime: model.get('mtime')
					wtime: model.get('wtime')
					dynamic: model.get('dynamic')
					ignored: model.get('ignored')
					write: model.get('write')
				}  for model in opts.collection.models
			)

			# Add anything that references other documents (e.g. partials, listing, etc)
			# This could eventually be way better
			standalones = opts.collection.pluck('standalone')
			allStandalone = standalones.indexOf(false) is -1
			if allStandalone is false
				opts.collection.add(docpad.getCollection('referencesOthers').models)

			# Deeply/recursively add the layout children
			addLayoutChildren = (collection) ->
				collection.forEach (file) ->
					if file.get('isLayout') is true
						# Find
						layoutChildrenQuery =
							layoutRelativePath: file.get('relativePath')
						layoutChildrenCollection = docpad.getCollection('hasLayout').findAll(layoutChildrenQuery)

						# Log the files to generate if we are in debug mode
						docpad.log 'debug', 'Layout children to generate at', (lastGenerateStarted), '\n', (
							{
								id: model.id
								path: model.getFilePath()
								mtime: model.get('mtime')
								wtime: model.get('wtime')
								write: model.get('write')
							}  for model in layoutChildrenCollection.models
						), '\n', layoutChildrenQuery

						# Recurse
						addLayoutChildren(layoutChildrenCollection)

						# Add
						opts.collection.add(layoutChildrenCollection.models)
			addLayoutChildren(opts.collection)

			# Filter out ignored, and no-render no-write files
			opts.collection.reset opts.collection.reject (file) ->
				return (file.get('render') is false and file.get('write') is false)

			# Log the files to generate if we are in debug mode
			docpad.log 'debug', 'Files to generate at', (lastGenerateStarted), '\n', (
				{
					id: model.id
					path: model.getFilePath()
					mtime: model.get('mtime')
					wtime: model.get('wtime')
					dynamic: model.get('dynamic')
					ignored: model.get('ignored')
					write: model.get('write')
				}  for model in opts.collection.models
			)

			# Forward
			return complete()


		addGroup 'process file', (addGroup, addTask) ->
			addTask 'contextualizeFiles', {args:[opts]}, docpad.contextualizeFiles.bind(docpad)
			addTask 'renderFiles', {args:[opts]}, docpad.renderFiles.bind(docpad)
			addTask 'writeFiles', {args:[opts]}, docpad.writeFiles.bind(docpad)


		addTask 'generateAfter', (complete) ->
			docpad.emitSerial('generateAfter', opts, complete)


		# Write the cache file
		addTask 'Write the database cache', (complete) ->
			# Skip if we do not care for writing the cache
			return complete()  unless opts.cache in [true, 'write']

			# Write the cache
			databaseData =
				generateStarted: docpad.generateStarted
				generateEnded: docpad.generateEnded
				models: (model.getAttributes()  for model in database.models)
			databaseDataDump = JSON.stringify(databaseData, null, '  ')
			docpad.log 'info', util.format(locale.databaseCacheWrite, databaseData.models.length)
			return safefs.writeFile(config.databaseCachePath, databaseDataDump, complete)


		# Run
		tasks.run()

		# Chain
		@


	# ---------------------------------
	# Render

	# Load a Document
	# next(err,document)
	loadDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Load
		# @TODO: don't load if already loaded
		document.action('load contextualize', opts, next)

		# Chain
		@

	# Load and Render a Document
	# next(err,document)
	loadAndRenderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @

		# Load
		docpad.loadDocument document, opts, (err) ->
			return next(err)  if err

			# Render
			docpad.renderDocument(document, opts, next)

		# Chain
		@

	# Render Document
	# next(err,result)
	renderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Render
		clone = document.clone().action 'render', opts, (err) ->
			result = clone.getOutContent()
			return next(err, result, document)

		# Chain
		@

	# Render Path
	# next(err,result)
	renderPath: (path,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			fullPath: path
		},opts.attributes)

		# Handle
		document = @createDocument(attributes)
		@loadAndRenderDocument(document, opts, next)

		# Chain
		@

	# Render Data
	# next(err,result)
	renderData: (content,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			filename: opts.filename
			data: content
		}, opts.attributes)

		# Handle
		document = @createDocument(attributes)
		@loadAndRenderDocument(document, opts, next)

		# Chain
		@

	# Render Text
	# Doesn't extract meta information, or render layouts
	# TODO: Why not? Why not just have renderData?
	# next(err,result)
	renderText: (text,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		opts.actions ?= ['renderExtensions', 'renderDocument']
		attributes = extendr.extend({
			filename: opts.filename
			data: text
			body: text
			content: text
		}, opts.attributes)

		# Handle
		document = @createDocument(attributes)

		# Render
		clone = document.clone().action 'normalize contextualize render', opts, (err) ->
			result = clone.getOutContent()
			return next(err, result, document)

		# Chain
		@

	# Render Action
	# next(err,document,result)
	render: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
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

	# Watchers
	watchers: null

	# Destroy Watchers
	destroyWatchers: =>
		# Prepare
		docpad = @

		# Check
		if docpad.watchers
			# Close each of them
			for watcher in docpad.watchers
				watcher.close()

			# Reset the array
			docpad.watchers = []

		# Chain
		@

	# Watch
	watch: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		database = @getDatabase()
		@watchers ?= []

		# Restart our watchers
		restartWatchers = (next) ->
			# Close our watchers
			docpad.destroyWatchers()

			# Start a group
			tasks = new TaskGroup("watch tasks", {concurrency:0, next})

			# Watch reload paths
			reloadPaths = _.union(config.reloadPaths, config.configPaths)
			tasks.addTask "watch reload paths", (complete) -> docpad.watchdir(
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
						docpad.watchers.push(watcher)
					return complete()
			)

			# Watch regenerate paths
			regeneratePaths = config.regeneratePaths
			tasks.addTask "watch regenerate paths", (complete) -> docpad.watchdir(
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
						docpad.watchers.push(watcher)
					return complete()
			)

			# Watch the source
			srcPath = config.srcPath
			tasks.addTask "watch the source path", (complete) -> docpad.watchdir(
				path: srcPath
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': changeHandler
				next: (err,watcher) ->
					if err
						docpad.log('warn', "Watching the src path has failed:", srcPath, err)
						return complete()
					docpad.watchers.push(watcher)
					return complete()
			)

			# Run
			tasks.run()

			# Chain
			@

		# Timer
		regenerateTimer = null
		queueRegeneration = ->
			# Reset the wait
			if regenerateTimer
				clearTimeout(regenerateTimer)
				regenerateTimer = null

			# Regenerat after a while
			regenerateTimer = setTimeout(performGenerate, config.regenerateDelay)

		performGenerate = (opts={}) ->
			# Q: Should we also pass over the collection?
			# A: No, doing the mtime query in generate is more robust

			# Log
			docpad.log util.format(locale.watchRegenerating, new Date().toLocaleTimeString())

			# Afterwards, re-render anything that should always re-render
			docpad.action 'generate', opts, (err) ->
				docpad.error(err)  if err
				docpad.log util.format(locale.watchRegenerated, new Date().toLocaleTimeString())

		# Change event handler
		changeHandler = (changeType,filePath,fileCurrentStat,filePreviousStat) ->
			# Prepare
			fileEitherStat = (fileCurrentStat or filePreviousStat)

			# For some reason neither of the stats may exist, this will cause errors as this is an invalid state
			# as we depend on at least one stat existing, otherwise, what on earth is going on?
			# Whatever the case, this should be fixed within watchr, not docpad
			# as watchr should not be giving us invalid data
			# https://github.com/bevry/docpad/issues/792
			unless fileEitherStat
				err = new Error("""
						DocPad has encountered an invalid state while detecting changes for your files.
						So the DocPad team can fix this right away, please provide any information you can to:
						https://github.com/bevry/docpad/issues/792
						""")
				return docpad.error(err)

			# Log the change
			docpad.log 'info', util.format(locale.watchChange, new Date().toLocaleTimeString()), changeType, filePath

			# Check if we are a file we don't care about
			# This check should not be needed with v2.3.3 of watchr
			# however we've still got it here as it may still be an issue
			isIgnored = docpad.isIgnoredPath(filePath)
			if isIgnored
				docpad.log 'debug', util.format(locale.watchIgnoredChange, new Date().toLocaleTimeString()), filePath
				return

			# Don't care if we are a directory
			isDirectory = fileEitherStat.isDirectory()
			if isDirectory
				docpad.log 'debug', util.format(locale.watchDirectoryChange, new Date().toLocaleTimeString()), filePath
				return

			# Override the stat's mtime to now
			# This is because renames will not update the mtime
			fileCurrentStat?.mtime = new Date()

			# Create the file object
			file = docpad.addModel({fullPath:filePath, stat:fileCurrentStat})
			file.setStat(fileCurrentStat)  if changeType is 'update'

			# File was deleted, delete the rendered file, and remove it from the database
			if changeType is 'delete'
				database.remove(file)
				file.action 'delete', (err) ->
					return docpad.error(err)  if err
					queueRegeneration()

			# File is new or was changed, update it's mtime by setting the stat
			else if changeType in ['create', 'update']
				file.action 'load', (err) ->
					return docpad.error(err)  if err
					queueRegeneration()

		# Watch
		docpad.log(locale.watchStart)
		restartWatchers (err) ->
			return next(err)  if err
			docpad.log(locale.watchStarted)
			return next()

		# Chain
		@


	# ---------------------------------
	# Run Action

	run: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()
		config = @getConfig()
		{srcPath, rootPath} = config

		# Prepare
		run = (complete) ->
			balUtil.flow(
				object: docpad
				action: 'server generate watch'
				args: [opts]
				next: complete
			)

		# Check if we have the docpad structure
		safefs.exists srcPath, (exists) ->
			# Check if have the correct structure, if so let's proceed with DocPad
			return run(next)  if exists

			# We don't have the correct structure
			# Check if we are running on an empty directory
			safefs.readdir rootPath, (err,files) ->
				return next(err)  if err

				# Check if our directory is empty
				if files.length
					# It isn't empty, display a warning
					docpad.log('warn', "\n"+util.format(locale.skeletonNonexistant, rootPath))
					return next()
				else
					docpad.skeleton opts, (err) ->
						# Check
						return next(err)  if err

						# Keep in global?
						return run(next)  if opts.global is true or docpad.getConfig().global is true

						# Log
						docpad.log('notice', locale.startLocal)

						# Destroy our DocPad instance so we can boot the local one
						docpad.destroy (err) ->
							# Check
							return next(err)  if err

							# Forward onto the local DocPad Instance now that it has been installed
							return docpadUtil.startLocalDocPadExecutable(next)

		# Chain
		@


	# ---------------------------------
	# Skeleton

	# Init Install
	# next(err)
	initInstall: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new TaskGroup("initInstall tasks", {concurrency:0, next})

		tasks.addTask "node modules", (complete) ->
			path = pathUtil.join(config.rootPath, 'node_modules')
			safefs.ensurePath(path, complete)

		tasks.addTask "package", (complete) ->
			# Exists?
			path = pathUtil.join(config.rootPath, 'package.json')
			safefs.exists path, (exists) ->
				# Check
				return complete()  if exists

				# Write
				data = JSON.stringify({
					name: 'no-skeleton.docpad'
					version: '0.1.0'
					description: 'New DocPad project without using a skeleton'
					engines:
						node: '0.10'
						npm: '1.3'
					dependencies:
						docpad: '~'+docpad.getVersion()
					main: 'node_modules/docpad/bin/docpad-server'
					scripts:
						start: 'node_modules/docpad/bin/docpad-server'
				}, null, '  ')
				safefs.writeFile(path, data, complete)

		# Run
		tasks.run()

		# Chain
		@

	# Uninstall
	# next(err)
	uninstall: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new TaskGroup("uninstall tasks", {next})

		# Uninstall a plugin
		if opts.plugin
			tasks.addTask "uninstall the plugin: #{opts.plugin}", (complete) ->
				plugins =
					for plugin in opts.plugin.split(/[,\s]+/)
						plugin = "docpad-plugin-#{plugin}"  if plugin.indexOf('docpad-plugin-') isnt 0
						plugin
				docpad.uninstallNodeModule(plugins, {
					output: true
					next: complete
				})

		# Re-load configuration
		tasks.addTask "re-load configuration", (complete) ->
			docpad.load(complete)

		# Run
		tasks.run()

		# Chain
		@

	# Install
	# next(err)
	install: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new TaskGroup("install tasks", {next})

		tasks.addTask "init the installation", (complete) ->
			docpad.initInstall(opts, complete)

		# Install a plugin
		if opts.plugin
			tasks.addTask "install the plugin: #{opts.plugin}", (complete) ->
				plugins =
					for plugin in opts.plugin.split(/[,\s]+/)
						plugin = "docpad-plugin-#{plugin}"  if plugin.indexOf('docpad-plugin-') isnt 0
						plugin += '@'+docpad.pluginVersion  if plugin.indexOf('@') is -1
						plugin
				docpad.installNodeModule(plugins, {
					output: true
					next: complete
				})

		tasks.addTask "re-initialize the website's modules", (complete) ->
			docpad.initNodeModules({
				output: true
				next: complete
			})

		tasks.addTask "fix node package versions", (complete) ->
			docpad.fixNodePackageVersions(complete)

		tasks.addTask "re-load the configuration", (complete) ->
			docpad.load(complete)

		# Run
		tasks.run()

		# Chain
		@

	# Upgrade
	# next(err)
	upgrade: (opts,next) ->
		# Update Global NPM and DocPad
		@installNodeModule('npm docpad@6', {
			global: true
			output: true
			next: next
		})

		# Chain
		@

	# Update
	# next(err)
	update: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new TaskGroup("update tasks", {next})

		tasks.addTask "init the install", (complete) ->
			docpad.initInstall(opts, complete)

		# Update the local docpad and plugin dependencies
		# Grouped together to avoid npm dependency shortcuts that can cause missing dependencies
		# But don't update git/http/https dependencies, those are special for some reason
		# > https://github.com/bevry/docpad/pull/701
		dependencies = []
		eachr docpad.websitePackageConfig.dependencies, (version,name) ->
			return  if /^docpad-plugin-/.test(name) is false or /// :// ///.test(version) is true
			dependencies.push(name+'@'+docpad.pluginVersion)
		if dependencies.length isnt 0
			tasks.addTask "update plugins that are dependencies", (complete) ->
				docpad.installNodeModule('docpad@6 '+dependencies, {
					output: true
					next: complete
				})

		# Update the plugin dev dependencies
		devDependencies = []
		eachr docpad.websitePackageConfig.devDependencies, (version,name) ->
			return  if /^docpad-plugin-/.test(name) is false
			devDependencies.push(name+'@'+docpad.pluginVersion)
		if devDependencies.length isnt 0
			tasks.addTask "update plugins that are dev dependencies", (complete) ->
				docpad.installNodeModule(devDependencies, {
					save: '--save-dev'
					output: true
					next: complete
				})

		tasks.addTask "fix node package versions", (complete) ->
			docpad.fixNodePackageVersions(complete)

		tasks.addTask "re-initialize the rest of the website's modules", (complete) ->
			docpad.initNodeModules({
				output: true
				next: complete
			})

		# Run
		tasks.run()

		# Chain
		@

	# Clean
	# next(err)
	clean: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = docpad.getConfig()
		locale = @getLocale()

		# Log
		docpad.log('info', locale.renderCleaning)

		# Tasks
		tasks = new TaskGroup "clean tasks", {concurrency:0}, next:(err) ->
			# Error?
			return next(err)  if err

			# Log
			docpad.log('info', locale.renderCleaned)

			# Forward
			return next()

		tasks.addTask 'reset the collecitons', (complete) ->
			docpad.resetCollections(opts, complete)

		# Delete out path
		# but only if our outPath is not a parent of our rootPath
		tasks.addTask 'delete out path', (complete) ->
			# Check if our outPath is higher than our root path, so do not remove files
			return complete()  if config.rootPath.indexOf(config.outPath) isnt -1

			# Our outPath is not related or lower than our root path, so do remove it
			balUtil.rmdirDeep(config.outPath, complete)

		# Delete database cache
		tasks.addTask 'delete database cache file', (complete) ->
			safefs.unlink(config.databaseCachePath, complete)

		# Run tasks
		tasks.run()

		# Chain
		@

	# Initialize a Skeleton into to a Directory
	# next(err)
	initSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Defaults
		opts.destinationPath ?= config.rootPath

		# Tasks
		tasks = new TaskGroup("initSkeleton tasks", {next})

		tasks.addTask "ensure the path we are writing to exists", (complete) ->
			safefs.ensurePath(opts.destinationPath, complete)

		# Clone out the repository if applicable
		if skeletonModel? and skeletonModel.id isnt 'none'
			tasks.addTask "clone out the git repo", (complete) ->
				docpad.initGitRepo({
					path: opts.destinationPath
					url: skeletonModel.get('repo')
					branch: skeletonModel.get('branch')
					remote: 'skeleton'
					output: true
					next: complete
				})
		else
			tasks.addTask "ensure src path exists", (complete) ->
				safefs.ensurePath(config.srcPath, complete)

			tasks.addGroup "initialize the website directory files", ->
				@setConfig(concurrency:0)

				# README
				@addTask "README.md", (complete) ->
					# Exists?
					path = pathUtil.join(config.rootPath, 'README.md')
					safefs.exists path, (exists) ->
						# Check
						return complete()  if exists

						# Write
						data = """
							# Your [DocPad](http://docpad.org) Project

							## License
							Copyright &copy; #{(new Date()).getFullYear()}+ All rights reserved.
							"""
						safefs.writeFile(path, data, complete)

				# Config
				@addTask "docpad.coffee configuration file", (complete) ->
					# Exists?
					docpad.getConfigPath (err,path) ->
						# Check
						return complete(err)  if err or path
						path = pathUtil.join(config.rootPath, 'docpad.coffee')

						# Write
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
						safefs.writeFile(path, data, complete)

				# Documents
				@addTask "documents directory", (complete) ->
					safefs.ensurePath(config.documentsPaths[0], complete)

				# Layouts
				@addTask "layouts directory", (complete) ->
					safefs.ensurePath(config.layoutsPaths[0], complete)

				# Files
				@addTask "files directory", (complete) ->
					safefs.ensurePath(config.filesPaths[0], complete)

		# Run
		tasks.run()

		# Chain
		@

	# Install a Skeleton into a Directory
	# next(err)
	installSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @

		# Defaults
		opts.destinationPath ?= @getConfig().rootPath

		# Initialize and install the skeleton
		docpad.initSkeleton skeletonModel, opts, (err) ->
			# Check
			return next(err)  if err

			# Forward
			docpad.install(opts, next)

		# Chain
		@

	# Use a Skeleton
	# next(err)
	useSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()

		# Defaults
		opts.destinationPath ?= @getConfig().rootPath

		# Extract
		skeletonId = skeletonModel?.id or 'none'
		skeletonName = skeletonModel?.get('name') or locale.skeletonNoneName

		# Track
		docpad.track('skeleton-use', {skeletonId})

		# Log
		docpad.log('info', util.format(locale.skeletonInstall, skeletonName, opts.destinationPath)+' '+locale.pleaseWait)

		# Install Skeleton
		docpad.installSkeleton skeletonModel, opts, (err) ->
			# Error?
			return next(err)  if err

			# Log
			docpad.log('info', locale.skeletonInstalled)

			# Forward
			return next(err)

		# Chain
		@

	# Select a Skeleton
	# next(err,skeletonModel)
	selectSkeleton: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		opts.selectSkeletonCallback ?= null

		# Track
		docpad.track('skeleton-ask')

		# Get the available skeletons
		docpad.getSkeletons (err,skeletonsCollection) ->
			# Check
			return next(err)  if err

			# Provide selection to the interface
			opts.selectSkeletonCallback(skeletonsCollection, next)

		# Chain
		@

	# Skeleton
	skeleton: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()
		opts.selectSkeletonCallback ?= null

		# Don't do anything if the src path exists
		safefs.exists config.srcPath, (exists) ->
			# Check
			if exists
				err = new Error(locale.skeletonExists)
				return next(err)

			# Select Skeleton
			docpad.selectSkeleton opts, (err,skeletonModel) ->
				# Check
				return next(err)  if err

				# Use Skeleton
				docpad.useSkeleton(skeletonModel, next)

		# Chain
		@

	# Init
	init: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		config = @getConfig()

		# Don't do anything if the src path exists
		safefs.exists config.srcPath, (exists) ->
			# Check
			if exists
				err = new Error(locale.skeletonExists)
				return next(err)

			# No Skeleton
			docpad.useSkeleton(null, next)

		# Chain
		@


	# ---------------------------------
	# Server

	# Serve Document
	serveDocument: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{document,err,req,res} = opts
		docpad = @
		config = @getConfig()

		# If no document, then exit early
		unless document
			if opts.statusCode?
				return res.send(opts.statusCode)
			else
				return next()

		# Prepare
		res.setHeaderIfMissing ?= (name, value) ->
			res.setHeader(name, value)  unless res.getHeader(name)

		# Content Type + Encoding/Charset
		encoding = document.get('encoding')
		charset = 'utf-8'  if encoding in ['utf8', 'utf-8']
		contentType = document.get('outContentType') or document.get('contentType')
		res.setHeaderIfMissing('Content-Type', contentType + (if charset then "; charset=#{charset}" else ''))

		# Cache-Control (max-age)
		res.setHeaderIfMissing('Cache-Control', "public, max-age=#{config.maxAge}")  if config.maxAge

		# Send
		dynamic = document.get('dynamic')
		if dynamic
			# If you are debugging why a dynamic document isn't rendering
			# it could be that you don't have cleanurls installed
			# e.g. if index.html is dynamic, and you are accessing it via /
			# then this code will not be reached, as we don't register that url
			# where if we have the cleanurls plugin installed, then do register that url
			# against the document, so this is reached
			collection = new FilesCollection([document], {name:'dynamic collection'})
			templateData = extendr.extend({}, req.templateData or {}, {req,err})
			docpad.action 'generate', {collection, templateData}, (err) ->
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
			# ETag: `"<size>-<mtime>"`
			ctime = document.get('date')    # use the date or mtime, it should always exist
			mtime = document.get('wtime')   # use the last generate time, it may not exist though
			stat = document.getStat()
			etag = stat.size + '-' + Number(mtime)   if mtime and stat
			res.setHeaderIfMissing('ETag', '"' + etag + '"')  if etag

			# Date
			res.setHeaderIfMissing('Date', ctime.toUTCString())  if ctime?.toUTCString?
			res.setHeaderIfMissing('Last-Modified', mtime.toUTCString())  if mtime?.toUTCString?
			# @TODO:
			# The above .toUTCString? check is a workaround because sometimes the date object
			# isn't really a date object, this needs to be fixed properly
			# https://github.com/bevry/docpad/pull/781

			# Send
			if etag and etag is (req.get('If-None-Match') or '').replace(/^"|"$/g, '')
				res.send(304)  # not modified
			else
				content = document.getOutContent()
				if content
					if opts.statusCode?
						res.send(opts.statusCode, content)
					else
						res.send(content)
				else
					if opts.statusCode?
						res.send(opts.statusCode)
					else
						next()

		# Chain
		@

	# Server Middleware: Header
	serverMiddlewareHeader: (req,res,next) ->
		# Prepare
		docpad = @

		# Handle
		# Always enable this until we get a complaint about not having it
		# For instance, Express.js also forces this
		tools = res.get('X-Powered-By').split(/[,\s]+/g)
		tools.push("DocPad v#{docpad.getVersion()}")
		tools = tools.join(', ')
		res.set('X-Powered-By', tools)

		# Forward
		next()

		# Chain
		@

	# Server Middleware: Router
	serverMiddlewareRouter: (req,res,next) ->
		# Prepare
		docpad = @

		# Get the file
		docpad.getFileByRoute req.url, (err,file) ->
			# Check
			return next(err)  if err or file? is false

			# Check if we are the desired url
			# if we aren't do a permanent redirect
			url = file.get('url')
			cleanUrl = docpad.getUrlPathname(url)
			if (url isnt cleanUrl) and (url isnt req.url)
				return res.redirect(301, url)

			# Serve the file to the user
			docpad.serveDocument({document:file, req, res, next})

		# Chain
		@

	# Server Middleware: 404
	serverMiddleware404: (req,res,next) ->
		# Prepare
		docpad = @
		database = docpad.getDatabaseSafe()

		# Notify the user of a 404
		docpad.log('notice', "404 Not Found:", req.url)

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '404.html'})
		docpad.serveDocument({document, req, res, next, statusCode:404})

		# Chain
		@

	# Server Middleware: 500
	serverMiddleware500: (err,req,res,next) ->
		# Prepare
		docpad = @
		database = docpad.getDatabaseSafe()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '500.html'})
		docpad.serveDocument({document,err,req,res,next,statusCode:500})

		# Chain
		@

	# Server
	server: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @config
		locale = @getLocale()
		port = @getPort()
		hostname = @getHostname()

		# Require
		http = require('http')
		express = require('express')

		# Config
		servers = @getServer(true)
		opts.serverExpress ?= servers.serverExpress
		opts.serverHttp ?= servers.serverHttp
		opts.middlewareBodyParser ?= config.middlewareBodyParser ? config.middlewareStandard
		opts.middlewareMethodOverride ?= config.middlewareMethodOverride ? config.middlewareStandard
		opts.middlewareExpressRouter ?= config.middlewareExpressRouter ? config.middlewareStandard
		opts.middleware404 ?= config.middleware404
		opts.middleware500 ?= config.middleware500
		# @TODO: Why do we do opts here instead of config???

		# Tasks
		tasks = new TaskGroup("server tasks", {next})

		# Before Plugin Event
		tasks.addTask "emit serverBefore", (complete) ->
			docpad.emitSerial('serverBefore', complete)

		# Create server when none is defined
		if !opts.serverExpress or !opts.serverHttp
			tasks.addTask "create server", ->
				opts.serverExpress or= express()
				opts.serverHttp or= http.createServer(opts.serverExpress)
				docpad.setServer(opts)

		# Extend the server with our middlewares
		if config.extendServer is true
			tasks.addTask "extend the server", (complete) ->
				# Parse url-encoded and json encoded form data
				if opts.middlewareBodyParser isnt false
					opts.serverExpress.use(express.urlencoded())
					opts.serverExpress.use(express.json())

				# Allow over-riding of the request type (e.g. GET, POST, PUT, DELETE)
				if opts.middlewareMethodOverride isnt false
					opts.serverExpress.use(express.methodOverride())

				# Emit the serverExtend event
				# So plugins can define their routes earlier than the DocPad routes
				docpad.emitSerial 'serverExtend', {
					server: opts.serverExpress # b/c
					express: opts.serverExpress # b/c
					serverHttp: opts.serverHttp
					serverExpress: opts.serverExpress
				}, (err) ->
					return next(err)  if err

					# DocPad Header Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddlewareHeader)

					# Router Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(opts.serverExpress.router)  if opts.middlewareExpressRouter isnt false

					# DocPad Router Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddlewareRouter)

					# Static
					# Keep it after the serverExtend event
					if config.maxAge
						opts.serverExpress.use(express.static(config.outPath, {maxAge:config.maxAge}))
					else
						opts.serverExpress.use(express.static(config.outPath))

					# DocPad 404 Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddleware404)  if opts.middleware404 isnt false

					# DocPad 500 Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddleware500)  if opts.middleware500 isnt false

					# Done
					return complete()

		# Start Server
		tasks.addTask "start the server", (complete) ->
			# Catch
			opts.serverHttp.once 'error', (err) ->
				# Friendlify the error message if it is what we suspect it is
				if err.message.indexOf('EADDRINUSE') isnt -1
					err = new Error(util.format(locale.serverInUse, port))

				# Done
				return complete(err)

			# Listen
			docpad.log 'debug', util.format(locale.serverStart, hostname, port, config.outPath)
			opts.serverHttp.listen port, hostname,  ->
				# Log
				address = opts.serverHttp.address()
				serverHostname = address.address
				serverPort = address.port
				serverLocation = "http://#{serverHostname}:#{serverPort}/"
				docpad.log 'info', util.format(locale.serverStarted, serverLocation, config.outPath)

				# Done
				return complete()

		# After Plugin Event
		tasks.addTask "emit serverAfter", (complete) ->
			docpad.emitSerial('serverAfter', {
				server: opts.serverExpress # b/c
				express: opts.serverExpress # b/c
				serverHttp: opts.serverHttp
				serverExpress: opts.serverExpress
			}, complete)

		# Run the tasks
		tasks.run()

		# Chain
		@


# ---------------------------------
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
