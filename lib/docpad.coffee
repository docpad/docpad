# =====================================
# Requires

# System
fs = require('fs')
path = require('path')

# Necessary
_ = require('underscore')
caterpillar = require('caterpillar')
queryEngine = require('query-engine')
CSON = require('cson')
balUtil = require('bal-util')
EventSystem = balUtil.EventSystem
airbrake = null

# Local
PluginLoader = require(path.join __dirname, 'plugin-loader.coffee')
BasePlugin = require(path.join __dirname, 'plugin.coffee')
require(path.join __dirname, 'prototypes.coffee')


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
	# DocPad

	# DocPad's version number
	version: null

	# The express server instance bound to docpad
	server: null

	# The caterpillar instance bound to docpad
	logger: null


	# ---------------------------------
	# Models

	# File Model
	FileModel: require(path.join __dirname, 'models', 'file.coffee')

	# Document Model
	DocumentModel: require(path.join __dirname, 'models', 'document.coffee')


	# ---------------------------------
	# Collections

	# Collections
	collections: null ### {
		# Documents collection
		documents: null  # QueryEngine Collection

		# Files collection
		files: null  # QueryEngine Collection

		# Layouts collection
		layouts: null  # QueryEngine Collection
	} ###

	# Database collection
	database: null  # QueryEngine Collection


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
	corePath: path.join(__dirname, '..')

	# The DocPad library directory
	libPath: __dirname

	# The main DocPad file
	mainPath: path.join(__dirname, 'docpad.coffee')

	# The DocPad package.json path
	packagePath: path.join(__dirname, '..', 'package.json')


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

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: null  # {}

		# Plugin directories to load
		pluginPaths: null  # []

		# The website's plugins directory
		pluginsPaths: null  # ['node_modules','plugins']

		# Where to fetch the exchange information from
		exchangeUrl: 'https://raw.github.com/bevry/docpad-extras/docpad-6.x/exchange.cson'


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

		# The website's documents directory
		documentsPath: path.join('src', 'documents')

		# The website's files directory
		filesPath: path.join('src', 'files')

		# The website's layouts directory
		layoutsPath: path.join('src', 'layouts')


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
		logLevel: (if process.argv.has('-d') then 7 else 6)

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
		templateData: null

		# Report Errors
		# Whether or not we should report our errors back to DocPad
		reportErrors: true

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: true


	# =================================
	# Initialization Functions

	# Construct DocPad
	# next(err)
	constructor: (config={},next) ->
		# Prepare
		docpad = @

		# Allow DocPad to have unlimited event listeners
		@setMaxListeners(0)

		# Initialize a default logger
		@logger = new caterpillar.Logger
			transports:
				formatter: module: module
		@setLogLevel(7)

		# Bind the error handler, so we don't crash on errors
		process.setMaxListeners(0)
		process.on 'uncaughtException', (err) ->
			docpad.error(err)

		# Initialize advanced variables
		@slowPlugins = {}
		@foundPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@collections = {}

		# Initialize the collections
		@database = queryEngine.createCollection()
		@collections.documents = @database.createLiveChildCollection().setQuery(type: 'document').sortBy(date:-1)
		@collections.files = @database.createLiveChildCollection().setQuery(type: 'file')
		@collections.layouts = @database.createLiveChildCollection().setQuery(type: 'layout')

		# Apply configuration
		@loadConfiguration config, {}, (err) ->
			# Error?
			return docpad.error(err)  if err

			# Load Airbrake if we want to reportErrors
			if docpad.config.reportErrors and /win/.test(process.platform) is false
				airbrake = require('airbrake').createClient('e7374dd1c5a346efe3895b9b0c1c0325')

			# Version Check
			docpad.compareVersion()

			# Log
			docpad.logger.log 'debug', 'DocPad loaded succesfully'
			docpad.logger.log 'debug', 'Loaded the following plugins:', _.keys(docpad.loadedPlugins).sort().join(', ')

			# Next
			return next?()

	# Set Log Level
	setLogLevel: (level) ->
		@logger.setLevel(level)
		@

	# Are we debugging?
	getLogLevel: ->
		return @config.logLevel

	# Are we debugging?
	getDebugging: ->
		return @getLogLevel() is 7

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

	# Load a configuration url
	# next(err,parsedData)
	loadConfigUrl: (jsonUrl,next) ->
		# Read the url using balUtil
		balUtil.readPath jsonUrl, (err,data) ->
			return next(err)  if err
			# Read the string using CSON
			CSON.parse(data.toString(),next)

		# Chain
		@

	# Load a configuration file
	# CSON supports CSON and JSON
	# next(err,parsedData)
	loadConfigPath: (configPath,next) ->
		# Check that it exists
		path.exists configPath, (exists) ->
			return next?(null,null)  unless exists
			# Read the path using CSON
			CSON.parseFile(configPath, next)

		# Chain
		@

	# Load Configuration
	loadConfiguration: (instanceConfig={},options={},next) ->
		# Prepare
		docpad = @
		logger = @logger

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
				websiteConfigPath = path.resolve(instanceConfig.rootPath, instanceConfig.configPath)
				websiteConfig = {}

				# Async
				tasks = new balUtil.Group (err) =>
					return fatal(err)  if err

					# Merge Configuration (not deep!)
					config = _.extend(
						{}
						@config
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

					# Ensure advanced variables
					config.plugins or= {}
					config.pluginPaths or= []
					config.pluginsPaths or= ['node_modules','plugins']

					# Apply merged configuration
					@config = config

					# Options
					@server = @config.server  if @config.server

					# Noramlize and resolve the configuration paths
					@config.rootPath = path.normalize(@config.rootPath or process.cwd())
					@config.outPath = path.resolve @config.rootPath, @config.outPath
					@config.srcPath = path.resolve @config.rootPath, @config.srcPath
					@config.layoutsPath = path.resolve @config.rootPath, @config.layoutsPath
					@config.publicPath = path.resolve @config.rootPath, @config.publicPath
					for pluginsPath,index in @config.pluginsPaths
						@config.pluginsPaths[index] = path.resolve(@config.rootPath, pluginsPath)

					# Other
					@config.templateData or= {}

					# Logger
					@logger = @config.logger  if @config.logger
					@setLogLevel(@config.logLevel)

					# Initialize
					@loadPlugins(complete)

				# Prepare configuration loading
				tasks.total = 2

				# Load DocPad Configuration
				@loadConfigPath docpadPackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}

					# Version
					docpad.version = data.version
					airbrake.appVersion = docpad.version  if airbrake

					# Compelte the loading
					tasks.complete()

				# Load Website Configuration
				@loadConfigPath websiteConfigPath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}
					console.log(websiteConfigPath,data)

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
	# with cross platform support
	# supports linux, heroku, osx, windows
	# next(err,results)
	initNodeModules: (dirPath,next) ->
		# Prepare
		docpad = @
		logger = @logger
		packageJsonPath = path.join(dirPath,'package.json')
		nodeModulesPath = path.join(dirPath,'node_modules')

		# Check if node modules already exists
		if path.existsSync(nodeModulesPath) and docpad.config.force is false
			return next()

		# If there is no package.json file, then we can't do anything
		unless path.existsSync(packageJsonPath)
			return next()

		# Use the local npm installation
		npmPath = path.resolve(docpad.corePath, 'node_modules', 'npm', 'bin', 'npm-cli.js')
		command =
			command: docpad.config.nodePath
			args: [npmPath, 'install']

		# Execute npm install inside the pugin directory
		logger.log 'debug', "Initializing node modules\non:   #{dirPath}\nwith:",command
		balUtil.spawn command, {cwd: dirPath}, (err,results) ->
			logger.log 'debug', "Initialized node modules\non:   #{dirPath}\nwith:",command
			return next(err)

		# Chain
		@


	# Install a Skeleton to a Directory
	# next(err)
	installSkeleton: (skeletonId,destinationPath,next) ->
		# Prepare
		docpad = @
		logger = @logger
		debugging = @getDebugging()
		packagePath = path.join(destinationPath, 'package.json')

		# Grab the skeletonDetails
		@getSkeleton skeletonId, (err,skeletonDetails) ->
			# Check
			return next(err)  if err

			# Initialize a Git Repository
			# Requires internet access
			# next(err)
			initGitRepo = (next) ->
				commands = [
					command: docpad.config.gitPath
					args: ['init']
				,
					command: docpad.config.gitPath
					args: ['remote','add','skeleton',skeletonDetails.repo]
				,
					command: docpad.config.gitPath
					args: ['fetch','skeleton']
				,
					command: docpad.config.gitPath
					args: ['pull','skeleton',skeletonDetails.branch]
				,
					command:docpad.config.gitPath
					args: ['submodule','init']
				,
					command: docpad.config.gitPath
					args: ['submodule','update','--recursive']
				]
				logger.log 'debug', "Initializing git pull for the skeleton #{skeletonId}"
				balUtil.spawn commands, {cwd:destinationPath,output:debugging}, (err,results) ->
					# Check
					if err
						logger.log 'debug', results
						return next(err)

					# Complete
					logger.log 'debug', "Initialized git pull for the skeleton #{skeletonId}"
					return next()

			# Log
			logger.log 'info', "Initializing the skeleton #{skeletonId} to #{destinationPath}"

			# Check if the skeleton path already exists
			balUtil.ensurePath destinationPath, (err) ->
				# Check
				return tasks.exit(err)  if err
				# Initalize the git repository
				initGitRepo (err) ->
					# Forward
					return next(err)

		# Chain
		@



	# ---------------------------------
	# Utilities

	# Create snore
	createSnore: (message) ->
		# Prepare
		logger = @logger

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
						logger.log 'notice', message
				5000
			)
			clear: ->
				if snore.timer
					clearTimeout(snore.timer)
					snore.timer = false


	# Compare current DocPad version to the latest
	compareVersion: ->
		return @  unless @config.checkVersion

		# Prepare
		docpad = @
		notify = @notify
		logger = @logger

		# Check
		balUtil.packageCompare
			local: path.join(docpad.corePath, 'package.json')
			remote: 'https://raw.github.com/bevry/docpad/master/package.json'
			newVersionCallback: (details) ->
				docpad.notify "There is a new version of #{details.local.name} available"
				docpad.logger.log 'notice', """
					There is a new version of #{details.local.name} available, you should probably upgrade...
					current version:  #{details.local.version}
					new version:      #{details.remote.version}
					grab it here:     #{details.remote.homepage}
					"""
		@


	# Handle a fatal error
	fatal: (err) ->
		return @  unless err
		@error err, 'err', ->
			process.exit(-1)


	# Handle an error
	error: (err,type='err',next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Check
		if !err or err.logged
			next?()
			return @

		# Log the error only if it hasn't been logged already
		err.logged = true
		err = new Error(err)  unless err instanceof Error
		err.logged = true
		logger.log type, 'An error occured:', err.message, err.stack

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
		logger = @logger

		# Log
		logger.log('warn', message)
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


	# ---------------------------------
	# Models

	# Instantiate a File
	createFile: (data={},options={}) ->
		# Prepare
		docpad = @
		options = _.extend(
			layouts: @layouts
			logger: @logger
			outDirPath: @config.outPath
		,options)

		# Create and return
		file = new @FileModel(data,options)

		# Return
		return file

	# Instantiate a Document
	createDocument: (data={},options={}) ->
		# Prepare
		docpad = @
		options = _.extend(
			layouts: @layouts
			logger: @logger
			outDirPath: @config.outPath
		,options)

		# Create and return
		document = new @DocumentModel(data,options)

		# Bubble
		document.on 'render', (args...) ->
			docpad.emitSync 'render', args...
		document.on 'renderDocument', (args...) ->
			docpad.emitSync 'renderDocument', args...

		# Return
		return document


	# Get Template Data
	getTemplateData: (userData) ->
		# Prepare
		userData or= {}

		# Initial merge
		templateData = _.extend({
			require: require
			docpad: @
			database: @database
			collections: @collections
			document: null
			site: {}
			blocks: {}
		}, @config.templateData, userData)

		# Add site data
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if _.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Add block data
		templateData.blocks.scripts or= []
		templateData.blocks.styles or= []
		templateData.blocks.meta or= []
		templateData.blocks.meta.push(
			'<meta http-equiv="X-Powered-By" content="DocPad"/>'
		)

		# Return
		return templateData

	# Render a document
	# next(err,document)
	render: (document,templateData,next) ->
		templateData = _.extend({},templateData)
		templateData.document = document.toJSON()
		templateData.documentModel = document
		document.render templateData, (err) =>
			@error(err)  if err
			return next?(err,document)

		# Chain
		@

	# Render a document
	# next(err,document)
	prepareAndRender: (document,templateData,next) ->
		# Prepare
		docpad = @

		# Normalize the document
		document.normalize (err) ->
			return next?(err)  if err
			# Load the document
			document.load (err) ->
				return next?(err)  if err
				# Contextualize the document
				document.contextualize (err) ->
					return next?(err) if err
					# Render the document
					docpad.render document, templateData, (err) ->
						return next?(err,document)

		# Chain
		@


	# ---------------------------------
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
		logger = @logger
		@slowPlugins = {}
		snore = @createSnore ->
			logger.log 'notice', "We're preparing your plugins, this may take a while the first time. Waiting on the plugins: #{_.keys(docpad.slowPlugins).join(', ')}"

		# Async
		tasks = new balUtil.Group (err) ->
			docpad.slowPlugins = {}
			snore.clear()
			return next?(err)

		# Load website plugins
		_.each @config.pluginsPaths or [], (pluginsPath) =>
			exists = path.existsSync(pluginsPath)
			if exists
				tasks.push (complete) =>
					@loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		_.each @config.pluginPaths or [], (pluginPath) =>
			exists = path.existsSync(pluginPath)
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

	# Load PLugin
	# next(err)
	loadPlugin: (fileFullPath,_next) ->
		# Prepare
		docpad = @
		logger = @logger
		config = @config
		next = (err) ->
			# Remove from slow plugins
			delete docpad.slowPlugins[pluginName]
			# Forward
			return _next(err)

		# Prepare variables
		loader = new PluginLoader(
			dirPath: fileFullPath
			docpad: docpad
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
			logger.log 'debug', "Skipping plugin: #{pluginName}"
			return next()
		else
			# Load
			logger.log 'debug', "Loading plugin: #{pluginName}"
			loader.exists (err,exists) ->
				return next(err)  if err or not exists
				loader.supported (err,supported) ->
					return next(err)  if err or not supported
					loader.install (err) ->
						return next(err)  if err
						loader.load (err) ->
							return next(err)  if err
							loader.create {}, (err,pluginInstance) ->
								return next(err)  if err
								# Add to plugin stores
								docpad.loadedPlugins[loader.pluginName] = pluginInstance
								# Log completion
								logger.log 'debug', "Loaded plugin: #{pluginName}"
								# Forward
								return next()

	# Load Plugins
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Load Plugins
		logger.log 'debug', "Plugins loading for: #{pluginsPath}"
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
				pluginName = path.basename(fileFullPath)
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
				logger.log 'debug', "Plugins loaded for: #{pluginsPath}"
				return next?(err)
		)

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
		logger = @logger

		# Multiple actions?
		actions = action.split /[,\s]+/g
		if actions.length > 1
			tasks = new balUtil.Group(next)
			tasks.total = actions.length
			for action in actions
				@action action, tasks.completer()
			return @

		# Log
		logger.log 'debug', "Performing the action #{action}"

		# Handle
		switch action
			when 'install', 'update'
				@installAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			when 'skeleton', 'scaffold'
				@skeletonAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			when 'generate'
				@generateAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			when 'clean'
				@cleanAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			when 'render'
				@renderAction opts, (err,data) =>
					return @fatal(err)  if err
					next?(err,data)

			when 'watch'
				@watchAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			when 'server', 'serve'
				@serverAction opts, (err) =>
					return @fatal(err)  if err
					next?()

			else
				@skeletonAction opts, (err) =>
					return @fatal(err)  if err
					@generateAction opts, (err) =>
						return @fatal(err)  if err
						@serverAction opts, (err) =>
							return @fatal(err)  if err
							@watchAction opts, (err) =>
								return @fatal(err)  if err
								next?()

		# Chain
		@



	# ---------------------------------
	# Install

	# Install
	# next(err)
	installAction: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		logger = @logger

		# Initialise the Website's modules
		@initNodeModules @config.rootPath, (err) =>
			# Error?
			return @error(err)  if err

			# Done
			return next?()

		# Chain
		@

	# Clean
	# next(err)
	cleanAction: (opts,next) ->
		# Prepare
		logger = @logger

		# Files
		balUtil.rmdir @config.outPath, (err,list,tree) ->
			logger.log 'debug', 'Cleaned files'  unless err
			return next?()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Parse a directory
	# next(err)
	parseDirectory: (opts={}) ->
		# Prepare
		docpad = @
		logger = @logger
		database = @database

		# Extract
		{path,createFunction,resultCollection,next} = opts

		# Log
		logger.log 'debug', 'Parsing #{documents.length} files'

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
				file.load (err) ->
					# Check
					if err
						docpad.warn("Failed to load the file: #{fileRelativePath}. The error follows:", err)
						return nextFile()

					# Prepare
					fileIgnored = file.get('ignored')
					fileParse = file.get('parse')

					# Ignored?
					if fileIgnored or (fileParse? and !fileParse)
						logger.log 'info', 'Skipped manually ignored file:', file.get('relativePath')
						return nextFile()
					else
						logger.log 'debug', 'Loaded the file:', file.get('relativePath')

					# Store Document
					resultCollection.add(file)  if resultCollection?

					# Forward
					return nextFile()

			# Next
			next: (err) ->
				# Log
				logger.log 'debug', 'Parsed #{documents.length} files'

				# Forward
				return next?(err)
		)

		# Chain
		@

	# Contextualize Files
	# next(err)
	contextualizeFiles: (opts={}) ->
		# Prepare
		docpad = @
		logger = @logger

		# Extract
		{documents,next} = opts

		# Log
		logger.log 'debug', 'Contextualizing #{documents.length} files'

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			logger.log 'debug', 'Contextualized #{documents.length} files'
			next?()

		# Fetch
		unless documents.length
			tasks.exit()
		else
			tasks.total = documents.length
			documents.forEach (document) ->
				document.contextualize tasks.completer()

		# Chain
		@

	# Render documents
	# next(err)
	renderDocuments: (opts={}) ->
		# Prepare
		docpad = @
		logger = @logger

		# Extract
		{documents,next} = opts

		# Log
		logger.log 'debug', "Rendering #{documents.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			# After
			docpad.emitSync 'renderAfter', {}, (err) ->
				logger.log 'debug', 'Rendered #{documents.length} files'  unless err
				next?(err)

		# Get the template data
		templateData = @getTemplateData()

		# Push the render tasks
		documents.forEach (document) ->
			tasks.push (complete) ->
				documentDynamic = document.get('dynamic')
				documentRender = document.get('render')
				if documentDynamic or (documentRender? and !documentRender)
					return complete()
				docpad.render(document,templateData,complete)

		# Fire the render tasks
		if tasks.total
			@emitSync 'renderBefore', {documents,templateData}, (err) =>
				return next?(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

	# Write documents
	# next(err)
	writeFiles: (err) ->
		# Prepare
		docpad = @
		logger = @logger

		# Extract
		{documents,next} = opts

		# Log
		logger.log 'debug', "Writing #{documents.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			# After
			docpad.emitSync 'writeAfter', {}, (err) ->
				logger.log 'debug', 'Wrote #{documents.length} files'  unless err
				next?(err)

		# Check
		unless documents.length
			return tasks.exit()

		# Cycle
		tasks.total = documents.length
		documents.forEach (document) ->
			# Fetch
			outPath = document.get('outPath')
			relativePath = document.get('relativePath')

			# Skip
			documentDynamic = document.get('dynamic')
			documentRender = document.get('render')
			documentWrite = document.get('write')
			if documentDynamic or (documentRender? and !documentRender) or (documentWrite? and !documentWrite)
				return tasks.complete()

			# Ensure path
			balUtil.ensurePath path.dirname(outPath), (err) ->
				# Error
				return tasks.exit(err)  if err

				# Write document
				logger.log 'debug', "Writing file: #{relativePath}"
				if document.get('encoding') is 'binary'
					document.write (err) ->
						tasks.complete(err)
				else
					document.writeRendered (err) ->
						tasks.complete(err)


	# Parse the files
	generateParse: (next) ->
		# Before
		@emitSync 'parseBefore', {}, (err) =>
			return next?(err)  if err

			# Prepare
			docpad = @
			logger = @logger

			# Log
			logger.log 'debug', 'Parsing everything'

			# Tasks
			tasks = new balUtil.Group (err) ->
				# Check
				if err
					docpad.warn("Failed to parse everything. The error follows:",err)
					return next?(err)

				# Contextualize
				docpad.generateParseContextualize (err) ->
					return next?(err)  if err

					# After
					docpad.emitSync 'parseAfter', {}, (err) ->
						if err
							docpad.warn("Failed to parse everything. The error follows:",err)
						else
							logger.log('debug', 'Parsed everything')
						return next?(err)
			tasks.total = 3

			# Documents
			@parseDirectory(
				path: @config.documentsPath
				createFunction: @createDocument
				resultCollection: @database
				next: tasks.completer()
			)

			# Files
			@parseDirectory(
				path: @config.filesPath
				createFunction: @createFile
				resultCollection: @database
				next: tasks.completer()
			)

			# Layouts
			@parseDirectory(
				path: @config.layoutsPath
				createFunction: @createDocument
				resultCollection: @database
				next: tasks.completer()
			)

		# Chain
		@


	# Generate Parse: Contextualize
	generateParseContextualize: (next) ->
		# Contextualize everything in the database
		@contextualizeDocuments(
			documents: @database
			next: next
		)

		# Chain
		@


	# Generate render
	generateRender: (next) ->
		# Render all the documents
		@renderDocuments(
			documents: @collections.documents
			next: next
		)

		# Chain
		@


	# Write
	generateWrite: (next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Before
		docpad.emitSync 'writeBefore', {}, (err) ->
			# Async
			tasks = new balUtil.Group (err) ->
				# After
				docpad.emitSync 'writeAfter', {}, (err) ->
					logger.log 'debug', 'Wrote everything'  unless err
					next?(err)
			tasks.total = 2

			# Write all the documents
			@renderDocuments(
				documents: @collections.documents
				next: tasks.completer()
			)

			# Write all the files
			@renderDocuments(
				documents: @collections.files
				next: tasks.completer()
			)

		# Chain
		@


	# Generate
	generateAction: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		logger = @logger
		notify = @notify

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.unblock 'loading', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.finish 'generating', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)

		# Check plugin count
		unless docpad.hasPlugins()
			logger.log 'warn', """
				DocPad is currently running without any plugins installed. You probably want to install some: https://github.com/bevry/docpad/wiki/Plugins
				"""

		# Block loading
		docpad.block 'loading', (err) ->
			return fatal(err)  if err
			# Start generating
			docpad.start 'generating', (err) =>
				return fatal(err)  if err
				logger.log 'info', 'Generating...'
				notify (new Date()).toLocaleTimeString(), title: 'Website generating...'
				# Plugins
				docpad.emitSync 'generateBefore', server: docpad.server, (err) ->
					return complete(err)  if err
					# Continue
					path.exists docpad.config.srcPath, (exists) ->
						# Check
						if exists is false
							return complete new Error 'Cannot generate website as the src dir was not found'
						# Generate Parse
						docpad.generateParse (err) ->
							return complete(err)  if err
							# Generate Render (First Pass)
							docpad.generateRender (err) ->
								return complete(err)  if err
								# Generate Render (Second Pass)
								docpad.generateRender (err) ->
									return complete(err)  if err
									# Generate Write
									docpad.generateWrite (err) ->
										return complete(err)  if err
										# Unblock
										docpad.unblock 'loading', (err) ->
											return complete(err)  if err
											# Plugins
											docpad.emitSync 'generateAfter', server: docpad.server, (err) ->
												return complete(err)  if err
												# Finished
												docpad.finished 'generating', (err) ->
													return complete(err)  if err
													# Generated
													logger.log 'info', 'Generated'
													notify (new Date()).toLocaleTimeString(), title: 'Website generated'
													# Completed
													complete()

		# Chain
		@


	# ---------------------------------
	# Render

	# Render Action
	renderAction: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		logger = @logger

		# Extract data
		data = opts.data or {}

		# Extract document
		if opts.filename
			document = @createDocument()
			document.set(
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
	# NOTE: Watching a directory and all it's contents (including subdirs and their contents) appears to be quite expiremental in node.js - if you know of a watching library that is quite stable, then please let me know - b@lupton.cc
	watchAction: (opts,next) ->
		# Require
		watchr = require('watchr')

		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		database = @database
		logger = @logger
		watchrInstance = null

		# Exits
		close = ->
			if watchrInstance
				watchrInstance.close()
				watchrInstance = null
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.finish 'watching', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.unblock 'loading', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)
		watch = (next) ->
			# Block loading
			docpad.block 'loading', (err) ->
				return next?(err)  if err
				docpad.start 'watching', (err) ->
					# Prepare
					logger.log 'Watching setup starting...'

					# Prepare change handler
					changeHappened = (eventName,filePath,fileCurrentStat,filePreviousStat) ->
						# Differential Rendering?
						if config.differentialRendering

							# Handle the action
							if eventName is 'unlink'
								changedFile.destroy()
							else if eventName is 'change'
								# Re-render just this file
								changedFile = database.findOne(fullPath: filePath)
								docpad.prepareAndRender changedFile, docpad.getTemplateData(), ->
									# Re-Render anything that references the changes
									pendingFiles = database.findAll(references: $has: changedFile).render()
									docpad.prepareAndRender pend

							else if eventName is 'new'

							# Re-Render anything that should always re-render
							database.findAll(referencesOthers: true).render()
						
						# Re-Render everything
						else
							docpad.action 'generate', (err) ->
								docpad.error(err)  if err
								logger.log 'Regenerated due to file watch at '+(new Date()).toLocaleString()

					# Watch the source directory
					close()
					watchrInstance = watchr.watch(
						path: docpad.config.srcPath
						listener: changeHappened
						next: next
						ignorePatterns: true
					)

		# Unwatch if loading started
		docpad.when 'loading:started', (err) ->
			return fatal(err)  if err
			# Unwatch the source directory
			close()

			# Watch when loading finished
			docpad.onceFinished 'loading', (err) ->
				return fatal(err)  if err
				# Watch the source directory
				watch()

		# Unwatch if generating started
		docpad.whenFinished 'generating:started', (err) ->
			return fatal(err)  if err
			# Unwatch the source directory
			close()

			# Watch when generating finished
			docpad.onceFinished 'generating', (err) ->
				return fatal(err)  if err
				# Watch the source directory
				watch()

		# Watch
		watch ->
			# Completed
			logger.log 'Watching setup'
			complete()


		# Chain
		@


	# ---------------------------------
	# Skeleton

	# Skeleton
	skeletonAction: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		logger = @logger
		skeletonId = @config.skeleton
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
				path.exists docpad.config.srcPath, (exists) ->
					# Check
					if exists
						logger.log 'info', "Didn't place the skeleton as the desired structure already exists"
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
	serverAction: (opts,next) ->
		# Require
		express = require('express')

		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		docpad = @
		logger = @logger
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
					docpad.server = express.createServer()  unless docpad.server
					server = docpad.server

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
								return next?()  unless docpad.documents

								# Prepare
								cleanUrl = req.url.replace(/\?.*/,'')
								document = docpad.documents.findOne(urls: '$in': cleanUrl)
								return next?()  unless document

								# Fetch
								contentTypeRendered = document.get('contentTypeRendered')
								url = document.get('url')
								dynamic = document.get('dynamic')
								contentRendered = document.get('contentRendered')

								# Send
								res.contentType(contentTypeRendered)
								if dynamic
									templateData = docpad.getTemplateData(req:req)
									docpad.render document, templateData, (err) ->
										contentRendered = document.get('contentRendered')
										if err
											docpad.error(err)
											res.send(err.message, 500)
										else
											res.send(contentRendered)
								else
									if contentRendered
										res.send(contentRendered)
									else
										next?()

							# Static
							if config.maxAge
								server.use(express.static config.outPath, maxAge: config.maxAge)
							else
								server.use(express.static config.outPath)

							# 404 Middleware
							server.use (req,res,next) ->
								res.send(404)

						# Start the server
						result = server.listen config.port
						try
							address = server.address()
							serverHostname = if address.address is '0.0.0.0' then 'localhost' else address.address
							serverPort = address.port
							serverLocation = "http://#{serverHostname}:#{serverPort}/"
							serverDir = config.outPath
							logger.log 'info', "DocPad listening to #{serverLocation} on directory #{serverDir}"
						catch err
							logger.log 'err', "Could not start the web server, chances are the desired port #{config.port} is already in use"

					# Plugins
					docpad.emitSync 'serverAfter', {server}, (err) ->
						return complete(err)  if err
						# Complete
						logger.log 'debug', 'Server setup'  unless err
						complete()

		# Chain
		@


# =====================================
# Export

# Export API
module.exports =
	DocPad: DocPad
	createInstance: (config,next) ->
		return new DocPad(config,next)
