# =====================================
# Requires

# System
fs = require('fs')
path = require('path')

# Necessary
_ = require('underscore')
caterpillar = require('caterpillar')
balUtil = require('bal-util')
EventSystem = balUtil.EventSystem

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

	# The data which we pass over to your templates
	templateData: {}
	
	
	# ---------------------------------
	# Models

	# File Model
	FileModel: require(path.join __dirname, 'models', 'file.coffee')

	# Document Model
	DocumentModel: require(path.join __dirname, 'models', 'document.coffee')

	# Layout Model
	LayoutModel: require(path.join __dirname, 'models', 'layout.coffee')

	# Partial Model
	PartialModel: require(path.join __dirname, 'models', 'partial.coffee')


	# ---------------------------------
	# Collections

	# Layouts collection
	layouts: null

	# Documents collection
	documents: null
	

	# ---------------------------------
	# Plugins

	# Loaded plugins sorted by priority
	pluginsArray: []

	# Loaded plugins indexed by name
	pluginsObject: {}


	# -----------------------------
	# Paths

	# The doocpad directory
	corePath: path.join __dirname, '..'

	# The docpad library directory
	libPath: __dirname

	# The main docpad file
	mainPath: path.join __dirname, 'docpad.coffee'

	# The docpad package.json path
	packagePath: path.join __dirname, '..', 'package.json'

	# The docpad plugins directory
	pluginsPath: path.join __dirname, 'exchange', 'plugins'

	# The docpad skeletons directory
	skeletonsPath: path.join __dirname, 'exchange', 'skeletons'


	# -----------------------------
	# Exchange

	###
	Exchange Configuration
	Still to be decided how it should function for now.
	Eventually it will be loaded from:
		- a remote url upon initialization
		- then stored in ~/.docpad/exchange.json
	Used to:
		- store the information of available extensions for docpad
	###
	exchange:
		# Plugins
		plugins: {}

		# Skeletons
		skeletons:
			'kitchensink.docpad':
				'branch': 'docpad-3.x'
				'repo': 'git://github.com/bevry/kitchensink.docpad.git'
			'canvas.docpad':
				'branch': 'docpad-3.x'
				'repo': 'git://github.com/bevry/canvas.docpad.git'
			
		# Themes
		themes: {}

	
	###
	Instance Configuration
	Loaded from:
		- the passed instanceConfiguration when creating a new docpad instance
		- the detected websiteConfiguration inside ./package.json>docpad
		- the default prototypeConfiguration which we see here
	###
	config:
		# -----------------------------
		# Plugins

		# Whether or not we should enable plugins that have not been listed or not
		enableUnlistedPlugins: true

		# Plugins which should be enabled or not pluginName: pluginEnabled
		enabledPlugins: {}

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: {}
		

		# -----------------------------
		# Website Paths

		# The website directory
		rootPath: '.'

		# The website's out directory
		outPath: 'out'

		# The website's src directory
		srcPath: 'src'

		# The website's layouts directory
		layoutsPath: path.join 'src', 'layouts'

		# The website's document's directory
		documentsPath: path.join 'src', 'documents'

		# The website's public directory
		publicPath: path.join 'src', 'public'

		# The website's package.json path
		packagePath: 'package.json'

		# The website's plugins directory
		pluginsPath: 'plugins'

		
		# -----------------------------
		# Server

		# A express server that we want docpad to use
		server: null

		# Whether or not we should extend the server with extra middleware and routing
		extendServer: true

		# The port that the server should use
		port: 9778

		# The caching time limit that is sent to the client
		maxAge: false


		# -----------------------------
		# Logging

		# Which level of logging should we actually output
		logLevel: (if process.argv.has('-d') then 7 else 6)

		# A caterpillar instance if we already have one
		logger: null

		# Whether or not to send notifications to growl when we have them
		growl: true
		

		# -----------------------------
		# Remote connection variables
		# Not currently used

		# Our unique and anoynmous user identifer
		# Used to provide completely anonymous user experience statistics back to the docpad server
		anonId: null

		# Our unique and anonymous cryptographic salt
		# Used to securely and safely anonamize anything that could possibly be personaly identifiable when reporting statistics
		anonSalt: null

		# Whether or not we should submit user experience statistics back the the docpad server
		track: true

		# Whether or not to update our exchange data
		updateExchange: true

		# Whether or not to check for newer versions of DocPad
		checkVersion: true

		# Exchange Database Url
		exchangeUrl: 'http://bevry.iriscouch.com/docpad-registry/_design/app/_rewrite' # 'http://registry.npmjs.org/'


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
		@setLogLevel(config.logLevel or @config.logLevel)
		
		# Bind the error handler, so we don't crash on errors
		process.on 'uncaughtException', (err) ->
			docpad.error(err)
		
		# Destruct prototype references
		@pluginsArray = []
		@pluginsObject = {}
		@templateData = {}

		# Clean the models
		@cleanModels()

		# Apply configuration
		@loadConfiguration config, (err) ->
			# Error?
			return docpad.error(err)  if err

			# Version Check
			docpad.compareVersion()

			# Next
			next?()
	
	# Set Log Level
	setLogLevel: (level) ->
		@logger.setLevel(level)
		@

	# Load a json path
	# next(err,parsedData)
	loadJsonPath: (jsonPath,next) ->
		# Prepare
		logger = @logger

		# Log
		logger.log 'debug', "Attempting to load the configuration file #{jsonPath}"

		# Read local configuration
		path.exists jsonPath, (exists) ->
			return next?()  if not exists
			balUtil.openFile -> fs.readFile jsonPath, (err,data) ->
				balUtil.closeFile()
				return next?(err)  if err
				return next?()  unless data
				try
					parsedData = JSON.parse data.toString()
				catch err
					return next?(err)
				finally
					return next?(null,parsedData)
	
	# Load Configuration
	loadConfiguration: (instanceConfig={},next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.unblock 'generating, watching, serving', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.finish 'loading', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)
	
		# Block other events
		docpad.block 'generating, watching, serving', (lockError) =>
			return fatal(lockError)  if lockError
					
			# Start loading
			docpad.start 'loading', (lockError) =>
				return fatal(lockError)  if lockError

				# Prepare
				instanceConfig.rootPath or= process.cwd()
				instanceConfig.packagePath or=  @config.packagePath
				docpadPackagePath = @packagePath
				websitePackagePath = path.resolve instanceConfig.rootPath, instanceConfig.packagePath
				docpadConfig = {}
				docpadConfig = {}
				websiteConfig = {}

				# Async
				tasks = new balUtil.Group (err) =>
					return fatal(err)  if err

					# Merge Configuration (not deep!)
					config = _.extend(
						{}
						@config
						docpadConfig
						websiteConfig
						instanceConfig
					)

					# Merge enabled plugins
					config.enabledPlugins = _.extend(
						{}
						@config.enabledPlugins or {}
						docpadConfig.enabledPlugins or {}
						websiteConfig.enabledPlugins or {}
						instanceConfig.enabledPlugins or {}
					)

					# Apply merged configuration
					@config = config
					
					# Options
					@server = @config.server  if @config.server

					# Noramlize and resolve the configuration paths
					@config.rootPath = path.normalize(@config.rootPath or process.cwd())
					@config.outPath = path.resolve @config.rootPath, @config.outPath
					@config.srcPath = path.resolve @config.rootPath, @config.srcPath
					@config.layoutsPath = path.resolve @config.rootPath, @config.layoutsPath
					@config.documentsPath = path.resolve @config.rootPath, @config.documentsPath
					@config.publicPath = path.resolve @config.rootPath, @config.publicPath
					@config.pluginsPath = path.resolve @config.rootPath, @config.pluginsPath

					# Logger
					@logger = @config.logger  if @config.logger
					@setLogLevel(@config.logLevel)

					# Initialize
					@loadPlugins complete

				# Prepare configuration loading
				tasks.total = 2
				
				# Load DocPad Configuration
				@loadJsonPath docpadPackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}
					data.docpad or= {}

					# Apply data to parent scope
					docpadConfig = data.docpad

					# Version
					docpad.version = data.version

					# Compelte the loading
					tasks.complete()
				
				# Load Website Configuration
				@loadJsonPath websitePackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}
					data.docpad or= {}

					# Apply data to parent scope
					websiteConfig = data.docpad

					# Compelte the loading
					tasks.complete()


	# Get Skeletons
	# next(err,skeletons)
	getSkeletons: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		skeletons = {}
		exists = false

		# Exists?
		path.exists docpad.skeletonsPath, (exists) ->
			# Check
			unless exists
				return next(null,skeletons,exists)

			# Ask about the skeletons
			balUtil.scandir(
				# Path
				docpad.skeletonsPath
				# File Action
				false
				# Dir Action
				(fileFullPath,fileRelativePath,complete) ->
					# Check if package.json exists
					packagePath = "#{fileFullPath}/package.json"
					path.exists packagePath, (exists) ->
						# Skip if it doesn't exist
						return complete(null,true)  unless exists

						# It does exist, let's get it's information
						docpad.loadJsonPath packagePath, (err,data) ->
							return complete(err,true)  if err
							data or= {}

							# Add it to the skeleton listing
							skeletons[fileRelativePath] = data

							# Complete
							return complete(null,true)
				# Next
				(err) ->
					# Check
					return next(err)  if err

					# Exists
					for own skeleton of skeletons
						exists = true
						break

					# Return the skeletons to the callback
					return next(null,skeletons,exists)
			)
		
		# Chain
		@
	
	# Get Skeleton Path
	getSkeletonPathSync: (skeleton) ->
		# Return
		skeletonPath = path.join @skeletonsPath, skeleton
	
	# Init Node Modules
	# with cross platform support
	# supports linux, heroku, osx, windows
	# next(err,results)
	initNodeModules: (dirPath,next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Global NPM on Windows
		if /^win/.test(process.platform)
			command = "npm install"
		
		# Local NPM on everything else
		else
			nodePath = if /node$/.test(process.execPath) then process.execPath else 'node'
			npmPath = path.resolve(docpad.corePath, 'node_modules', 'npm', 'bin', 'npm-cli.js')
			command = "\"#{nodePath}\" \"#{npmPath}\" install"

		# Execute npm install inside the pugin directory
		logger.log 'debug', "Initializing node modules\non:   #{dirPath}\nwith: #{command}"
		balUtil.exec command, {cwd: dirPath}, next

		# Chain
		@

	# Install a Skeleton
	installSkeleton: (skeletonId, next) ->
		# Prepare
		docpad = @
		logger = @logger
		skeletonDetails = @exchange.skeletons[skeletonId] or {}
		skeletonPath = @getSkeletonPathSync(skeletonId)
		packagePath = path.join skeletonPath, 'package.json'

		# Log
		logger.log 'debug', "Installing the skeleton #{skeletonId}"

		# Async
		tasks = new balUtil.Group (err) ->
			# Check
			return next?(err)  if err

			# Initialized
			logger.log 'debug', "Installed the skeleton #{skeletonId}"  unless err
			return next?(err)
		
		# Init node modules
		initNodeModules = (next) ->
			path.exists packagePath, (exists) ->
				return next?()  unless exists
				logger.log 'debug', "Initializing node modules for the skeleton #{skeletonId}"
				docpad.initNodeModules skeletonPath, (err,results) ->
					# Check
					if err
						logger.log 'debug', results
						return next?(err)
					
					# Complete
					logger.log 'debug', "Initialized node modules for the skeleton #{skeletonId}"
					return next?()
		
		# Init git submodules
		initGitSubmodules = (next) ->
			logger.log 'debug', "Initializing git submodules for the skeleton #{skeletonId}"
			balUtil.initGitSubmodules skeletonPath, (err,results) ->
				# Check
				if err
					logger.log 'debug', results
					return next?(err)  
				
				# Complete
				logger.log 'debug', "Initialized git submodules for the skeleton #{skeletonId}"
				return next?()
		
		# Init git pull
		# Requires internet access
		initGitPull = (next) ->
			command = "git pull origin #{skeletonDetails.branch}"
			logger.log 'debug', "Initializing git pulls for the skeleton #{skeletonId}\nwith: #{command}"
			balUtil.exec command, {cwd:skeletonPath}, (err,results) ->
				# Check
				if err
					logger.log 'debug', results
					return next?(err)  
				
				# Complete
				logger.log 'debug', "Initializing git pull for the skeleton #{skeletonId}"
				return next?()
		
		# Init git repo
		# Requires internet access
		initGitRepo = (next) ->
			command = "git clone  --branch #{skeletonDetails.branch}  --recursive  #{skeletonDetails.repo}  #{skeletonPath}"
			logger.log 'debug', "Initializing git repo for the skeleton #{skeletonId}\nwith: #{command}"
			balUtil.exec command, {cwd:docpad.corePath}, (err,results) ->
				# Check
				if err
					logger.log 'debug', results
					return next?(err) 
				
				# Complete
				logger.log 'debug', "Initialized git repo for the skeleton #{skeletonId}"
				return next?()
				
		
		# Check if the skeleton path already exists
		path.exists skeletonPath, (exists) ->
			# It doesn't exist
			if not exists
				tasks.total = 1
				initGitRepo (err) ->
					return next?(err)  if err
					initNodeModules tasks.completer()
			
			# It does exist
			else
				tasks.total = 2
				initGitPull (err) ->
					return next?(err)  if err
					initGitSubmodules tasks.completer()
					initNodeModules tasks.completer()

		# Chain
		@
	
	# Install the skeletons
	installSkeletons: (next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Log
		logger.log 'debug', "Installing skeletons"
		snore = @createSnore "We're installing your skeletons, this may take a while the first time. Perhaps grab a snickers?"
		
		# Tasks
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err

			# Initialized Skeletons Successfully
			snore.clear()
			logger.log 'debug', "Installed skeletons completed"
			return next?(err)
		
		# Add Init Skeleton
		addInitSkeleton = (skeletonId) ->
			tasks.push (complete) ->
				docpad.installSkeleton skeletonId, complete
		
		# Ensure skeletons path exists
		balUtil.ensurePath docpad.skeletonsPath, (err) ->
			# Check
			return next?(err)  if err

			# Cycle through the skeletons
			for own skeletonId, skeletonDetails of docpad.exchange.skeletons
				# Initialise the skeleton
				addInitSkeleton(skeletonId)  
			
			# Run them async
			tasks.async()
		
		# Chain
		@
	
	# Ensure Skeletons
	# next(err)
	ensureSkeletons: (next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Load the skeletons
		@getSkeletons (err,skeletons,exists) ->
			return next?()  if exists
			docpad.installSkeletons(next)
			return
		
		# Chain
		@
	

	# ---------------------------------
	# Utilities

	# Check if the file path is ignored
	# next?(err,ignore)
	filePathIgnored: (fileFullPath,next) ->
		if path.basename(fileFullPath).startsWith('.') or path.basename(fileFullPath).finishesWith('~')
			next?(null, true)
		else
			next?(null, false)
		
		# Chain
		@
	
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
			local: path.join docpad.corePath, 'package.json'
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
		@error(err)
		process.exit(-1)
	

	# Handle an error
	error: (err,type='err') ->
		# Check
		return @  unless err

		# Log the error only if it hasn't been logged already
		unless err.logged
			err.logged = true
			err = new Error(err)  unless err instanceof Error
			err.logged = true
			@logger.log type, 'An error occured:', err.message, err.stack
			#@emit 'error', err
			#node's default action is to exit when we hit an error, if there are no listeners
		
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

	# Instantiate a Partial
	createPartial: (meta={}) ->
		# Prepare
		docpad = @
		config =
			docpad: @
			logger: @logger
			meta: meta
		
		# Create and return
		partial = new @PartialModel(config)
		
		# Bubble
		partial.on 'render', (args...) ->
			docpad.emitSync 'render', args...
		partial.on 'renderDocument', (args...) ->
			docpad.emitSync 'renderDocument', args...

		# Return
		return partial
	
	# Instantiate a Document
	createDocument: (meta={}) ->
		# Prepare
		docpad = @
		config =
			docpad: @
			layouts: @layouts
			logger: @logger
			outDirPath: @config.outPath
			meta: meta
		
		# Create and return
		document = new @DocumentModel(config)
		
		# Bubble
		document.on 'render', (args...) ->
			docpad.emitSync 'render', args...
		document.on 'renderDocument', (args...) ->
			docpad.emitSync 'renderDocument', args...

		# Return
		return document
	
	# Instantiate a Layout
	createLayout: (meta={}) ->
		# Prepare
		docpad = @
		config =
			docpad: @
			layouts: @layouts
			logger: @logger
			meta: meta

		# Create and return
		layout = new @LayoutModel(config)
		
		# Bubble
		layout.on 'render', (args...) ->
			docpad.emitSync 'render', args...
		layout.on 'renderDocument', (args...) ->
			docpad.emitSync 'renderDocument', args...

		# Return
		return layout



	# Clean Models
	cleanModels: (next) ->
		# Require
		queryEngine = require('query-engine')

		# Prepare
		layouts = @layouts = new queryEngine.Collection
		documents = @documents = new queryEngine.Collection
		
		# Layout Prototype
		@LayoutModel::store = ->
			layouts[@id] = @

		# Document Prototype
		@DocumentModel::store = ->
			documents[@id] = @
		
		# Next
		next?()

		# Chain
		@
	

	# Render a document
	# next(err,document)
	render: (document,data,next) ->
		templateData = _.extend {}, @templateData, data
		templateData.document = document
		document.render templateData, (err) =>
			@error(err)  if err
			return next?(err,document)

		# Chain
		@
	
	# Render a document
	# next(err,document)
	prepareAndRender: (document,data,next) ->
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
					docpad.render document, data, (err) ->
						return next?(err,document)

		# Chain
		@


	# ---------------------------------
	# Plugins

	# Get a plugin by it's name
	getPlugin: (pluginName) ->
		@pluginsObject[pluginName]

	# Load Plugins
	loadPlugins: (next) ->
		# Prepare
		logger = @logger
		docpad = @
		snore = @createSnore "We're preparing your plugins, this may take a while the first time. Perhaps grab a snickers?"

		# Async
		tasks = new balUtil.Group (err) ->
			snore.clear()
			return next?(err)  if err
			logger.log 'info', 'Loaded the following plugins:', _.keys(docpad.pluginsObject).sort().join(', ')
			next?(err)
		
		# Load in the docpad and local plugin directories
		tasks.push => @loadPluginsIn @pluginsPath, tasks.completer()
		if @pluginsPath isnt @config.pluginsPath and path.existsSync(@config.pluginsPath)
			tasks.push => @loadPluginsIn @config.pluginsPath, tasks.completer()
		
		# Execute the loading asynchronously
		tasks.async()

		# Chain
		@


	# Load Plugins
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		docpad = @
		logger = @logger
		config = @config

		# Load Plugins
		logger.log 'debug', "Plugins loading for #{pluginsPath}"
		balUtil.scandir(
			# Path
			pluginsPath,

			# Skip files
			false,

			# Handle directories
			(fileFullPath,fileRelativePath,_nextFile) ->
				# Prepare
				return _nextFile(null,false)  if fileFullPath is pluginsPath
				nextFile = (err,skip) ->
					if err
						logger.log 'warn', "Failed to load the plugin #{loader.pluginName} at #{fileFullPath}. The error follows"
						docpad.error(err, 'warn')
					_nextFile(null,true)

				# Prepare
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

				# Check
				unless enabled
					# Skip
					logger.log 'debug', "Skipping plugin #{pluginName}"
					return nextFile(null)
				else
					# Load
					logger.log 'debug', "Loading plugin #{pluginName}"
					loader.exists (err,exists) ->
						return nextFile(err)  if err or not exists
						loader.supported (err,supported) ->
							return nextFile(err)  if err or not supported
							loader.install (err) ->
								return nextFile(err)  if err
								loader.load (err) ->
									return nextFile(err)  if err
									loader.create {}, (err,pluginInstance) ->
										return nextFile(err)  if err
										docpad.pluginsObject[loader.pluginName] = pluginInstance
										docpad.pluginsArray.push pluginInstance
										logger.log 'debug', "Loaded plugin #{pluginName}"
										return nextFile(null)
				
			# Next
			(err) =>
				@pluginsArray.sort (a,b) -> a.priority - b.priority
				logger.log 'debug', "Plugins loaded for #{pluginsPath}"
				next?(err)
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
			tasks = new balUtil.Group next
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

		# Setup out skeletons
		@installSkeletons (err) ->
			return next?(err)  if err
			logger.log 'info', 'DocPad installation was successfull'
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
	
	# Clean the database
	generateClean: (next) ->
		# Before
		@emitSync 'cleanBefore', {}, (err) =>
			return next?(err)  if err

			# Prepare
			docpad = @
			logger = @logger
			logger.log 'debug', 'Cleaning started'

			# Models
			@cleanModels()
			
			# Async
			tasks = new balUtil.Group (err) ->
				# After
				docpad.emitSync 'cleanAfter', {}, (err) ->
					logger.log 'debug', 'Cleaning finished'  unless err
					next?(err)
			tasks.total = 5

			# Layouts
			@layouts.remove {}, (err) ->
				logger.log 'debug', 'Cleaned layouts'  unless err
				tasks.complete err
			
			# Documents
			@documents.remove {}, (err) ->
				logger.log 'debug', 'Cleaned documents'  unless err
				tasks.complete err
			
			# Ensure Layouts
			balUtil.ensurePath @config.layoutsPath, (err) ->
				logger.log 'debug', 'Ensured layouts'  unless err
				tasks.complete err
			
			# Ensure Documents
			balUtil.ensurePath @config.documentsPath, (err) ->
				logger.log 'debug', 'Ensured documents'  unless err
				tasks.complete err
		
			# Ensure Public
			balUtil.ensurePath @config.publicPath, (err) ->
				logger.log 'debug', 'Ensured public'  unless err
				tasks.complete err
		
		# Chain
		@


	# Parse the files
	generateParse: (next) ->
		# Before
		@emitSync 'parseBefore', {}, (err) =>
			return next?(err)  if err

			# Requires
			docpad = @
			logger = @logger
			logger.log 'debug', 'Parsing files'

			# Async
			tasks = new balUtil.Group (err) ->
				# Check
				return next?(err)  if err
				# Contextualize
				docpad.generateParseContextualize (err) ->
					return next?(err)  if err
					# After
					docpad.emitSync 'parseAfter', {}, (err) ->
						logger.log 'debug', 'Parsed files'  unless err
						return next?(err)
			
			# Tasks
			tasks.total = 2

			# Layouts
			balUtil.scandir(
				# Path
				@config.layoutsPath,

				# File Action
				(fileFullPath,fileRelativePath,nextFile) ->
					# Ignore?
					docpad.filePathIgnored fileFullPath, (err,ignore) ->
						return nextFile(err)  if err or ignore
						layout = docpad.createLayout(
								fullPath: fileFullPath
								relativePath: fileRelativePath
						)
						layout.load (err) ->
							return nextFile(err)  if err
							layout.store()
							return nextFile()
					
				# Dir Action
				null,

				# Next
				(err) ->
					logger.log 'warn', 'Failed to parse layouts', err  if err
					return tasks.complete(err)
			)

			# Documents
			balUtil.scandir(
				# Path
				@config.documentsPath,

				# File Action
				(fileFullPath,fileRelativePath,nextFile) ->
					# Ignore?
					docpad.filePathIgnored fileFullPath, (err,ignore) ->
						return nextFile(err)  if err or ignore
						document = docpad.createDocument(
							fullPath: fileFullPath
							relativePath: fileRelativePath
						)
						document.load (err) ->
							return nextFile(err)  if err

							# Ignored?
							if document.ignore or document.ignored or document.skip or document.published is false or document.draft is true
								logger.log 'info', 'Skipped manually ignored document:', document.relativePath
								return nextFile()
							else
								logger.log 'debug', 'Loaded in the document:', document.relativePath
							
							# Store Document
							document.store()
							return nextFile()
				
				# Dir Action
				null,

				# Next
				(err) ->
					logger.log 'warn', 'Failed to parse documents', err  if err
					return tasks.complete(err)
			)

		# Chain
		@
	

	# Generate Parse: Contextualize
	generateParseContextualize: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		logger.log 'debug', 'Parsing files: Contextualizing files'

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			logger.log 'debug', 'Parsing files: Contextualized files'
			next?()
		
		# Fetch
		documents = @documents.find({}).sort({'date':-1})
		return tasks.exit()  unless documents.length
		tasks.total += documents.length

		# Scan all documents
		documents.forEach (document) ->
			document.contextualize tasks.completer()

		# Chain
		@
	
	
	# Generate render
	generateRender: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		logger.log 'debug', 'Rendering files'

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			# After
			docpad.emitSync 'renderAfter', {}, (err) ->
				logger.log 'debug', 'Rendered files'  unless err
				next?(err)
		
		# Prepare template data
		documents = @documents.find({}).sort('date': -1)
		return tasks.exit()  unless documents.length
		@templateData =
			require: require
			docpad: @
			documents: documents
			database: @documents
			document: null
			site:
				date: new Date()
			blocks:
				scripts: []
				styles: []
				meta: [
					'<meta http-equiv="X-Powered-By" content="DocPad"/>'
				]

		# Before
		@emitSync 'renderBefore', {documents,@templateData}, (err) =>
			return next?(err)  if err
			# Render documents
			tasks.total += documents.length
			documents.forEach (document) =>
				return tasks.complete()  if document.dynamic
				@render document, {}, tasks.completer()

		# Chain
		@


	# Write files
	generateWriteFiles: (next) ->
		# Prepare
		logger = @logger
		logger.log 'debug', 'Writing files'

		# Write
		balUtil.rpdir(
			# Src Path
			@config.publicPath,
			# Out Path
			@config.outPath
			# Next
			(err) ->
				logger.log 'debug', 'Wrote files'  unless err
				next?(err)
		)

		# Chain
		@


	# Write documents
	generateWriteDocuments: (next) ->
		# Prepare
		logger = @logger
		logger.log 'debug', 'Writing documents'

		# Async
		tasks = new balUtil.Group (err) ->
			logger.log 'debug', 'Wrote documents'  unless err
			next?(err)

		# Find documents
		@documents.find {}, (err,documents,length) ->
			# Error
			return tasks.exit err  if err
			return tasks.exit()  unless length

			# Cycle
			tasks.total += length
			documents.forEach (document) ->
				# Dynamic
				return tasks.complete()  if document.dynamic

				# Ensure path
				balUtil.ensurePath path.dirname(document.outPath), (err) ->
					# Error
					return tasks.exit err  if err

					# Write document
					logger.log 'debug', "Writing file #{document.relativePath}, #{document.url}"
					document.writeRendered (err) ->
						tasks.complete err

		# Chain
		@


	# Write
	generateWrite: (next) ->
		# Prepare
		docpad = @
		logger = @logger

		# Before
		docpad.emitSync 'writeBefore', {}, (err) ->
			return next?(err)  if err
			logger.log 'debug', 'Writing everything'

			# Async
			tasks = new balUtil.Group (err) ->
				return next?(err)  if err
				# After
				docpad.emitSync 'writeAfter', {}, (err) ->
					logger.log 'debug', 'Wrote everything'  unless err
					next?(err)
			tasks.total = 2

			# Files
			docpad.generateWriteFiles tasks.completer()
			
			# Documents
			docpad.generateWriteDocuments tasks.completer()

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
						# Generate Clean
						docpad.generateClean (err) ->
							return complete(err)  if err
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
			document.filename = opts.filename
			document.fullPath = opts.filename
			document.data = opts.content
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
					changeHappened = ->
						# What to do when a file has changed
						docpad.action 'generate', (err) ->
							docpad.error(err)  if err
							logger.log 'Regenerated due to file watch at '+(new Date()).toLocaleString()

					# Watch the source directory
					close()
					watchrInstance = watchr.watch docpad.config.srcPath, changeHappened, next
		
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
		skeleton = @config.skeleton
		destinationPath = @config.rootPath
		selectSkeletonCallback = opts.selectSkeletonCallback or null

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.finish 'skeleton', (lockError) ->
				return fatal(lockError)  if lockError
				docpad.unblock 'loading, generating', (lockError) ->
					return fatal(lockError)  if lockError
					return next?(err)
		useSkeleton = (skeletonId) ->
			# Copy over the skeleton
			logger.log 'info', "Copying over the Skeleton"
			skeletonPath = docpad.getSkeletonPathSync(skeletonId)
			balUtil.cpdir skeletonPath, destinationPath, (err) ->
				return complete(err)  if err
				logger.log 'info', "Copied over the Skeleton"
				return complete()

		# Block loading
		docpad.block 'loading, generating', (lockError) ->
			return fatal(lockError)  if lockError
			docpad.start 'skeleton', (lockError) ->
				return fatal(lockError)  if lockError
				# Copy
				path.exists docpad.config.srcPath, (exists) ->
					# Check
					if exists
						logger.log 'info', "Didn't place the skeleton as the desired structure already exists"
						return complete()
					
					# Ensure Skeletons
					docpad.ensureSkeletons (err) ->
						# Check
						return fatal(err)  if err
				
						# Initialize Skeleton
						if skeleton
							return useSkeleton(skeleton)
						else
							# Get the skeletons
							docpad.getSkeletons (err,skeletons) ->
								# Check
								return fatal(err)  if err

								# Provide selection to the interface
								selectSkeletonCallback skeletons, (err,skeleton) ->
									# Check
									return fatal(err)  if err

									# Use the selected skeleton
									return useSkeleton(skeleton)

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
								return next?()  unless docpad.documents
								cleanUrl = req.url.replace(/\?.*/,'')
								docpad.documents.findOne {urls:{'$in':cleanUrl}}, (err,document) =>
									if err
										docpad.error(err)
										res.send(err.message, 500)
									else if document
										res.contentType(document.outPath or document.url)
										if document.dynamic
											docpad.render document, req: req, (err) =>
												if err
													docpad.error(err)
													res.send(err.message, 500)
												else
													res.send(document.contentRendered)
										else
											if document.contentRendered
												res.send(document.contentRendered)
											else
												next?()
									else
										next?()

							# Static
							if config.maxAge
								server.use express.static config.outPath, maxAge: config.maxAge
							else
								server.use express.static config.outPath
							
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
							logger.log 'info', "DocPad listening to #{serverLocation} with directory #{serverDir}"
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
