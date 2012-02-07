# =====================================
# Requires

# System
fs = require('fs')
path = require('path')
request = require('request')
sys = require('util')

# Necessary
_ = require('underscore')
caterpillar = require('caterpillar')
util = require('bal-util')
EventSystem = util.EventSystem

# Optional
growl = null
express = null
watchr = null
queryEngine = null

# Local
PluginLoader = require("#{__dirname}/plugin-loader.coffee")
BasePlugin = require("#{__dirname}/base-plugin.coffee")
require("#{__dirname}/prototypes.coffee")


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

	# File class
	File: null

	# Layout class
	Layout: null

	# Document class
	Document: null

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
	corePath: "#{__dirname}/.."

	# The docpad library directory
	libPath: "#{__dirname}"

	# The main docpad file
	mainPath: "#{__dirname}/docpad.coffee"

	# The docpad package.json path
	packagePath: "#{__dirname}/package.json"

	# The docpad plugins directory
	pluginsPath: "#{__dirname}/exchange/plugins"


	# -----------------------------
	# Exchange

	###
	Exchange Configuration
	Still to be decided how it should function for now.
	Eventually it will be loaded from:
		- a remote url upon initialisation
		- then stored in ~/.docpad/exchange.json
	Used to:
		- store the information of available extensions for docpad
	###
	exchange:
		# Plugins
		plugins: {}
		# Skeletons
		skeletons: {}
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
		enabledPlugins:
			# Enable only stable plugins by default
			admin: false # not stable # not stable
			authenticate: false # not stable
			autoupdate: false # not stable
			buildr: false # not stable
			cleanurls: true
			coffee: true
			eco: true # has sys problem
			haml: true
			html2jade: false # not stable
			jade: true
			less: true
			markdown: true
			related: true
			rest: false # not stable
			roy: true # has sys problem
			sass: true
			stylus: true

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
		layoutsPath: 'src/layouts'

		# The website's document's directory
		documentsPath: 'src/documents'

		# The website's public directory
		publicPath: 'src/public'

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
		exchangeUrl: 'http://registry.npmjs.org/'


	# =================================
	# Initialisation Functions

	# Construct DocPad
	# next(err)
	constructor: (config={},next) ->
		# Prepare
		docpad = @

		# Initialise a default logger
		@logger = new caterpillar.Logger
			transports:
				level: @config.logLevel
				formatter: module: module
		
		# Bind the error handler, so we don't crash on errors
		process.on 'uncaughtException', (err) ->
			docpad.error err
		
		# Destruct prototype references
		@pluginsArray = []
		@pluginsObject = {}
		@templateData = {}

		# Apply configuration
		@loadConfiguration config, (err) ->
			# Error?
			return docpad.error(err)  if err

			# Version Check
			docpad.compareVersion()

			# Next
			next?()

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
			fs.readFile jsonPath, (err,data) ->
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
			docpad.unblock 'generating, watching, serving', ->
				docpad.finish 'loading', ->
					next?(err)
	
		# Block other events
		docpad.block 'generating, watching, serving', (err) =>
			return fatal(err)  if err
					
			# Start loading
			docpad.start 'loading', (err) =>
				return fatal(err)  if err

				# Prepare
				instanceConfig.rootPath or= process.cwd()
				instanceConfig.packagePath or=  @config.packagePath
				docpadPackagePath = @packagePath
				websitePackagePath = path.resolve instanceConfig.rootPath, instanceConfig.packagePath
				docpadConfig = {}
				docpadConfig = {}
				websiteConfig = {}

				# Async
				tasks = new util.Group (err) =>
					return fatal(err)  if err

					# Apply Configuration
					@config = _.extend(
						{}
						@config
						docpadConfig
						websiteConfig
						instanceConfig
					)
					
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
					@logger = @config.logger or= new caterpillar.Logger
						transports:
							level: @config.logLevel
							formatter: module: module

					# Prepare enabled plugins
					if typeof @config.enabledPlugins is 'string'
						enabledPlugins = {}
						for enabledPlugin in @config.enabledPlugins.split(/[ ,]+/)
							enabledPlugins[enabledPlugin] = true
						@config.enabledPlugins = enabledPlugins
					
					# Load plugins then exit
					docpad.loadPlugins complete
				

				# Prepare configuration loading
				tasks.total = 2
				
				# Load DocPad Configuration
				@loadJsonPath docpadPackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}
					data.docpad or= {}

					# Apply data to parent scope
					docpadConfig = data.docpad

					# Compelte the loading
					tasks.complete()
				
				# Load DocPad Configuration
				@loadJsonPath websitePackagePath, (err,data) ->
					return tasks.complete(err)  if err
					data or= {}
					data.docpad or= {}

					# Apply data to parent scope
					websiteConfig = data.docpad

					# Compelte the loading
					tasks.complete()


	# Initialise the Skeleton
	initializeSkeleton: (skeleton, destinationPath, next) ->
		# Prepare
		docpad = @
		logger = @logger
		skeletonRepo = @config.skeletons[skeleton].repo
		logger.log 'info', "[#{skeleton}] Initialising the Skeleton to #{destinationPath}"
		snore = @createSnore "[#{skeleton}] This could take a while, grab a snickers"

		# Async
		tasks = new util.Group (err) ->
			snore.clear()
			logger.log 'info', "[#{skeleton}] Initialised the Skeleton"  unless err
			next?(err)
		tasks.total = 2
		
		# Pull
		logger.log 'debug', "[#{skeleton}] Pulling in the Skeleton"
		util.gitPull destinationPath, skeletonRepo, (err,stdout,stderr) ->
			# Output
			if err
				console.log stdout.replace(/\s+$/,'')  if stdout
				console.log stderr.replace(/\s+$/,'')  if stderr
				return next?(err)
			
			# Log
			logger.log 'debug', "[#{skeleton}] Pulled in the Skeleton"

			# Git Submodules
			logger.log 'debug', "[#{skeleton}] Initialising Git Submodules for Skeleton"
			util.initGitSubmodules destinationPath, (err,stdout,stderr) ->
				# Output
				if err
					console.log stdout.replace(/\s+$/,'')  if stdout
					console.log stderr.replace(/\s+$/,'')  if stderr
					return tasks.complete(err)  
				
				# Complete
				logger.log 'debug', "[#{skeleton}] Initalised Git Submodules for Skeleton"
				tasks.complete()
			
			# Node Modules
			path.exists "#{destinationPath}/package.json", (exists) ->
				tasks.complete()  unless exists
				logger.log 'debug', "[#{skeleton}] Initialising Node Modules for Skeleton"
				util.initNodeModules destinationPath, (err,stdout,stderr) ->
					# Output
					if err
						console.log stdout.replace(/\s+$/,'')  if stdout
						console.log stderr.replace(/\s+$/,'')  if stderr
						return tasks.complete(err)  
					
					# Complete
					logger.log 'debug', "[#{skeleton}] Initialised Node Modules for Skeleton"
					tasks.complete()

		# Chain
		@
	

	# ---------------------------------
	# Exchange

	# Update the Exchange
	updateExchange: (next) ->
		try
			details.local = JSON.parse fs.readFileSync(local).toString()
			request = require 'request'  unless request
			request remote, (err,response,body) =>
				if not err and response.statusCode is 200
					details.remote = JSON.parse body
					unless @versionCompare(details.local.version, '>=', details.remote.version)
						newVersionCallback(details)  if newVersionCallback
					else
						oldVersionCallback(details)  if oldVersionCallback
		catch err
			errorCallback(err)  if errorCallback


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
		notify = @notify
		logger = @logger

		# Check
		util.packageCompare
			local: "#{@corePath}/package.json"
			remote: 'https://raw.github.com/bevry/docpad/master/package.json'
			newVersionCallback: (details) ->
				docpad.notify 'There is a new version of #{details.local.name} available'
				docpad.logger.log 'notice', """
					There is a new version of #{details.local.name} available, you should probably upgrade...
					current version:  #{details.local.version}
					new version:      #{details.remote.version}
					grab it here:     #{details.remote.homepage}
					"""
		@
	

	# Create a next wrapper
	createNextWrapper: (next) ->
		return (args...) =>
			@error(args[0])  if args[0]
			next.apply(next,apply)  if typeof next is 'function'
	
	
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
			@emit 'error', err
		
		# Chain
		@


	# Perform a growl notification
	notify: (args...) =>
		# Check if we want to use growl
		return @  unless @config.growl

		# Load growl
		growl = require('growl')  unless growl

		# Use growl
		growl.apply(growl,args)

		# Chain
		@


	# ---------------------------------
	# Models

	# Layout Document
	createDocument: (meta={}) ->
		# Prepare
		config =
			docpad: @
			layouts: @layouts
			logger: @logger
			outDirPath: @config.outPath
			meta: meta
		
		# Create and return
		document = new @Document config
	

	# Create Layout
	createLayout: (meta={}) ->
		# Prepare
		config =
			docpad: @
			layouts: @layouts
			logger: @logger
			meta: meta

		# Create and return
		layout = new @Layout config


	# Clean Models
	cleanModels: (next) ->
		# Prepare
		File = @File = require("#{@libPath}/file.coffee")
		Layout = @Layout = class extends File
		Document = @Document = class extends File
		layouts = @layouts = new queryEngine.Collection
		documents = @documents = new queryEngine.Collection
		
		# Extend
		Layout::store = ->
			layouts[@id] = @
		Document::store = ->
			documents[@id] = @
		
		# Next
		next?()

		# Chain
		@
	

	# Render a document
	render: (document,data,next) ->
		templateData = _.extend {}, @templateData, data
		templateData.document = document
		document.render templateData, (err) =>
			@error err  if err
			next?()


	# ---------------------------------
	# Plugins

	# Get a plugin by it's name
	getPlugin: (pluginName) ->
		@pluginsObject[pluginName]


	# Trigger a plugin event
	# next?(err)
	triggerPluginEvent: (eventName,data,next) ->
		# Prepare
		data or= data
		data.logger = @logger
		data.docpad = @

		# Async
		logger = @logger
		tasks = new util.Group (err) ->
			logger.log 'debug', "Plugins finished for #{eventName}"
			next?(err)
		tasks.total = @pluginsArray.length

		# Cycle
		logger.log 'debug', "Plugins started for #{eventName}"
		for plugin in @pluginsArray
			if typeof plugin[eventName] is 'function'
				plugin[eventName](data, tasks.completer())
			else
				tasks.complete()
		
		###
		# Trigger
		@cycle eventName, data, next
		###

		# Chain
		@


	# Load Plugins
	loadPlugins: (next) ->
		# Prepare
		logger = @logger
		docpad = @
		snore = @createSnore "We're preparing your plugins, this may take a while the first time. Perhaps grab a snickers?"

		# Async
		tasks = new util.Group (err) ->
			snore.clear()
			return next?(err)  if err
			logger.log 'debug', 'All plugins loaded'
			next?(err)
		
		# Load in the docpad and local plugin directories
		tasks.push => @loadPluginsIn @pluginsPath, tasks.completer()
		if @config.rootPath isnt __dirname and path.existsSync "#{@config.rootPath}/plugins"
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
		util.scandir(
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
						docpad.error err, 'warn'
					_nextFile(null,skip)

				# Prepare
				loader = new PluginLoader dirPath: fileFullPath, docpad: docpad, BasePlugin: BasePlugin
				pluginName = loader.pluginName
				enabled = (
					(config.enableUnlistedPlugins  and  config.enabledPlugins[pluginName]? is false)  or
					config.enabledPlugins[pluginName] is true
				)

				# Check
				unless enabled
					# Skip
					logger.log 'debug', "Skipping plugin #{pluginName}"
					return nextFile(null,true)
				else
					# Load
					logger.log 'debug', "Loading plugin #{pluginName}"
					loader.exists (err,exists) ->
						return nextFile(err,true)  if err or not exists
						loader.install (err) ->
							return nextFile(err,true)  if err
							loader.load (err) ->
								return nextFile(err,true)  if err
								loader.create {}, (err,pluginInstance) ->
									return nextFile(err,true)  if err
									docpad.pluginsObject[loader.pluginName] = pluginInstance
									docpad.pluginsArray.push pluginInstance
									logger.log 'debug', "Loaded plugin #{pluginName}"
									return nextFile(null,true)
				
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

	# Perform an action
	# next(err)
	action: (action,next) ->
		# Prepare
		error = @error
		logger = @logger

		# Multiple actions?
		actions = action.split /[,\s]+/g
		if actions.length > 1
			tasks = new util.Group next
			tasks.total = actions.length
			for action in actions
				@action action, tasks.completer()
			return @

		# LOG
		logger.log 'debug', "Performing the action #{action}"

		# Handle
		switch action
			when 'skeleton', 'scaffold'
				@skeletonAction (err) =>
					return error(err)  if err
					next?()

			when 'generate'
				@generateAction (err) =>
					return error(err)  if err
					next?()

			when 'watch'
				@watchAction (err) =>
					return error(err)  if err
					next?()

			when 'server', 'serve'
				@serverAction (err) =>
					return error(err)  if err
					next?()

			else
				@skeletonAction (err) =>
					return error(err)  if err
					@generateAction (err) =>
						return error(err)  if err
						@serverAction (err) =>
							return error(err)  if err
							@watchAction (err) =>
								return error(err)  if err
								next?()
		
		# Chain
		@


	# ---------------------------------
	# Generate
	
	# Clean the database
	generateClean: (next) ->
		# Before
		@triggerPluginEvent 'cleanBefore', {}, (err) =>
			return next?(err)  if err

			# Prepare
			docpad = @
			logger = @logger
			logger.log 'debug', 'Cleaning started'

			# Models
			@cleanModels()
			
			# Async
			tasks = new util.Group (err) ->
				# After
				docpad.triggerPluginEvent 'cleanAfter', {}, (err) ->
					logger.log 'debug', 'Cleaning finished'  unless err
					next?(err)
			tasks.total = 6

			# Files
			util.rmdir @config.outPath, (err,list,tree) ->
				logger.log 'debug', 'Cleaned files'  unless err
				tasks.complete err

			# Layouts
			@layouts.remove {}, (err) ->
				logger.log 'debug', 'Cleaned layouts'  unless err
				tasks.complete err
			
			# Documents
			@documents.remove {}, (err) ->
				logger.log 'debug', 'Cleaned documents'  unless err
				tasks.complete err
			
			# Ensure Layouts
			util.ensurePath @config.layoutsPath, (err) ->
				logger.log 'debug', 'Ensured layouts'  unless err
				tasks.complete err
			
			# Ensure Documents
			util.ensurePath @config.documentsPath, (err) ->
				logger.log 'debug', 'Ensured documents'  unless err
				tasks.complete err
		
			# Ensure Public
			util.ensurePath @config.publicPath, (err) ->
				logger.log 'debug', 'Ensured public'  unless err
				tasks.complete err
		
		# Chain
		@


	# Parse the files
	generateParse: (next) ->
		# Before
		@triggerPluginEvent 'parseBefore', {}, (err) =>
			return next?(err)  if err

			# Requires
			docpad = @
			logger = @logger
			logger.log 'debug', 'Parsing files'

			# Async
			tasks = new util.Group (err) ->
				# Check
				return next?(err)  if err
				# Contextualize
				docpad.generateParseContextualize (err) ->
					return next?(err)  if err
					# After
					docpad.triggerPluginEvent 'parseAfter', {}, (err) ->
						logger.log 'debug', 'Parsed files'  unless err
						next?(err)
			
			# Tasks
			tasks.total = 2

			# Layouts
			util.scandir(
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
							nextFile err
					
				# Dir Action
				null,

				# Next
				(err) ->
					logger.log 'warn', 'Failed to parse layouts', err  if err
					tasks.complete err
			)

			# Documents
			util.scandir(
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
							return nextFile err  if err

							# Ignored?
							if document.ignore or document.ignored or document.skip or document.published is false or document.draft is true
								logger.log 'info', 'Skipped manually ignored document:', document.relativePath
								return nextFile()
							else
								logger.log 'debug', 'Loaded in the document:', document.relativePath
							
							# Store Document
							document.store()
							nextFile err
				
				# Dir Action
				null,

				# Next
				(err) ->
					logger.log 'warn', 'Failed to parse documents', err  if err
					tasks.complete err
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
		tasks = new util.Group (err) ->
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
		tasks = new util.Group (err) ->
			return next?(err)  if err
			# After
			docpad.triggerPluginEvent 'renderAfter', {}, (err) ->
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
		@triggerPluginEvent 'renderBefore', {documents,@templateData}, (err) =>
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
		util.cpdir(
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
		tasks = new util.Group (err) ->
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
				util.ensurePath path.dirname(document.outPath), (err) ->
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
		docpad.triggerPluginEvent 'writeBefore', {}, (err) ->
			return next?(err)  if err
			logger.log 'debug', 'Writing everything'

			# Async
			tasks = new util.Group (err) ->
				return next?(err)  if err
				# After
				docpad.triggerPluginEvent 'writeAfter', {}, (err) ->
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
	generateAction: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		notify = @notify
		queryEngine = require('query-engine')  unless queryEngine

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			docpad.unblock 'loading', (err) ->
				fatal(err)  if err  # continue on
				docpad.finish 'generating', ->
					fatal(err)  if err  # continue on
					next?(err)
		
		# Block loading
		docpad.block 'loading', (err) ->
			return fatal(err)  if err
			# Start generating
			docpad.start 'generating', (err) =>
				return fatal(err)  if err
				logger.log 'info', 'Generating...'
				# Plugins
				docpad.triggerPluginEvent 'generateBefore', server: docpad.server, (err) ->
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
												docpad.triggerPluginEvent 'generateAfter', server: docpad.server, (err) ->
													return complete(err)  if err
													# Finished
													docpad.finished 'generating', (err) ->
														return complete(err)  if err
														# Generated
														logger.log 'info', 'Generated'
														notify (new Date()).toLocaleTimeString(), title: 'Website Generated'
														# Completed
														complete()

		# Chain
		@


	# ---------------------------------
	# Watch
	
	# Watch
	# NOTE: Watching a directory and all it's contents (including subdirs and their contents) appears to be quite expiremental in node.js - if you know of a watching library that is quite stable, then please let me know - b@lupton.cc
	watchAction: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		watchr = require('watchr')  unless watchr
		watchrInstance = null

		# Exits
		close = ->
			if watchrInstance
				watchrInstance.close()
				watchrInstance = null
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			# Finish
			docpad.finish 'watching', ->
				fatal(err)  if err  # continue on
				# Unblock
				docpad.unblock 'loading', (err) ->
					fatal(err)  if err  # continue on
					# Next
					next?(err)
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
	skeletonAction: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		skeleton = @config.skeleton
		destinationPath = @config.rootPath

		# Exits
		fatal = (err) ->
			docpad.fatal(err,next)
		complete = (err) ->
			# Finish
			docpad.finish 'skeleton', ->
				fatal(err)  if err  # continue on
				# Unblock
				docpad.unblock 'loading, generating', (err) ->
					fatal(err)  if err  # continue on
					# Next
					next?(err)

		# Block loading
		docpad.block 'loading, generating', (err) ->
			return fatal(err)  if err
			docpad.start 'skeleton', (err) ->
				return fatal(err)  if err
				# Copy
				path.exists docpad.config.srcPath, (exists) ->
					# Check
					if exists
						logger.log 'info', "Didn't place the skeleton as the desired structure already exists"
						return complete()
					
					# Initialise Skeleton
					logger.log 'info', "About to initialize the skeleton [#{skeleton}] to [#{destinationPath}]"
					docpad.initializeSkeleton skeleton, destinationPath, (err) ->
						return complete(err)

		# Chain
		@


	# ---------------------------------
	# Server
	
	# Server
	serverAction: (next) ->
		# Prepare
		docpad = @
		logger = @logger
		config = @config
		express = require 'express'  unless express

		# Exists
		fatal = (err) ->
			return docpad.fatal(err,next)
		complete = (err) ->
			# Finish
			docpad.finish 'serving', ->
				fatal(err)  if err  # continue on
				# Unblock
				docpad.unblock 'loading', (err) ->
					fatal(err)  if err  # continue on
					# Next
					next?(err)
		
		# Block loading
		docpad.block 'loading', (err) ->
			return fatal(err)  if err
			docpad.start 'serving', (err) ->
				return fatal(err)  if err
				# Plugins
				docpad.triggerPluginEvent 'serverBefore', {}, (err) ->
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
										docpad.error err
										res.send(err.message, 500)
									else if document
										res.contentType(document.outPath or document.url)
										if document.dynamic
											docpad.render document, req: req, (err) =>
												if err
													docpad.error err
													res.send(err.message, 500)
												else
													res.send(document.contentRendered)
										else
											res.send(document.contentRendered)
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
					docpad.triggerPluginEvent 'serverAfter', {server}, (err) ->
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
