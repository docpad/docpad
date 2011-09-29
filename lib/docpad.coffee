###
Docpad by Benjamin Lupton
The easiest way to generate your static website.
###

# Requirements
fs = require 'fs'
path = require 'path'
sys = require 'sys'
caterpillar = require 'caterpillar'
util = require 'bal-util'
exec = require('child_process').exec
growl = require('growl')
versionCompare = false
request = false
express = false
yaml = false
watchTree = false
queryEngine = false
logger = false
packageJSON = JSON.parse fs.readFileSync("#{__dirname}/../package.json").toString()


# -------------------------------------
# Prototypes

Array::hasCount = (arr) ->
	count = 0
	for a in this
		for b in arr
			if a is b
				++count
				break
	return count

Date::toShortDateString = ->
	return this.toDateString().replace(/^[^\s]+\s/,'')

Date::toISODateString = Date::toIsoDateString = ->
	pad = (n) ->
		if n < 10 then ('0'+n) else n

	# Return
	@getUTCFullYear()+'-'+
		pad(@getUTCMonth()+1)+'-'+
		pad(@getUTCDate())+'T'+
		pad(@getUTCHours())+':'+
		pad(@getUTCMinutes())+':'+
		pad(@getUTCSeconds())+'Z'

String::startsWith = (prefix) ->
	return @indexOf(prefix) is 0

String::finishesWith = (suffix) ->
	return @indexOf(suffix) is @length-1


# -------------------------------------
# Collections

Layouts = {}
Documents = {}

# -------------------------------------
# Models

class File
	# Auto
	id: null
	basename: null
	extensions: []
	extension: null
	filename: null
	fullPath: null
	relativePath: null
	relativeBase: null
	content: null
	contentSrc: null
	contentRaw: null
	contentRendered: null

	# User
	title: null
	date: null
	slug: null
	url: null
	ignore: false
	tags: []
	relatedDocuments: []

	# Constructor
	constructor: (fullPath,relativePath) ->
		@fullPath = fullPath
		@relativePath = relativePath
		@extensions = []
		@tags = []
		@relatedDocuments = []

	# Load
	# next(err)
	load: (next) ->
		# Log
		logger.log 'debug', "Reading the file #{@relativePath}"

		# Async
		tasks = new util.Group (err) =>
			if err
				logger.log 'err', "Failed to read the file #{@relativePath}"
			else
				logger.log 'debug', "Read the file #{@relativePath}"
			next err
		tasks.total = 2

		# Stat the file
		fs.stat @fullPath, (err,fileStat) =>
			return next err  if err
			@date = fileStat.ctime
			tasks.complete()

		# Read the file
		fs.readFile @fullPath, (err,data) =>
			return next err  if err

			# Handle data
			fileData = data.toString()
			fileSplit = fileData.split '---'
			fileMeta = {}
			if fileSplit.length >= 3 and !fileSplit[0]
				# Extract parts
				fileHead = fileSplit[1].replace(/\t/g,'    ').replace(/\s+$/m,'').replace(/\r\n?/g,'\n')+'\n'
				fileBody = fileSplit.slice(2).join('---')
				fileMeta = yaml.eval fileHead
			else
				# Extract part
				fileBody = fileData

			# Extensions
			@basename = path.basename @fullPath
			@extensions = @basename.split /\./g
			@extensions.shift()
			@extension = @extensions[0]
			@extensionRendered = @extension
			@filename = @basename.replace(/\..*/, '')

			# Temp
			fullDirPath = path.dirname @fullPath
			relativeDirPath = path.dirname(@relativePath).replace(/^\.$/,'')

			# Update Meta
			@content = fileBody
			@contentSrc = fileBody
			@contentRaw = fileData
			@contentRendered = fileBody
			@relativeBase = (if relativeDirPath.length then relativeDirPath+'/' else '')+@filename
			@title = @title || path.basename(@fullPath)
			@date = new Date(@date)  if @date
			@slug = util.generateSlugSync @relativeBase
			@id = @slug
			
			# Refresh data
			@refresh()

			# Apply user meta
			for own key, value of fileMeta
				@[key] = value

			# Complete
			tasks.complete()
	
	# Refresh data
	refresh: ->
		@url = "/#{@relativeBase}.#{@extensionRendered}"
	
	# getParent
	# next(err,layout)
	getLayout: (next) ->
		# Find parent
		Layouts.findOne {relativeBase:@layout}, (err,layout) ->
			# Check
			if err
				return next err
			else if not layout
				err = new Error "Could not find the layout: #{@layout}"
				return next err
			else
				return next null, layout

	# Render
	# next(err,finalExtension)
	render: (triggerRenderEvent,templateData,next) ->
		# Log
		logger.log 'debug', "Rendering the file #{@relativePath}"

		# Prepare
		@contentRendered = @content
		@content = @contentSrc

		# Async
		tasks = new util.Group (err) =>
			next err  if err

			# Wrap in layout
			if @layout
				@getLayout (err,layout) =>
					return next err  if err
					templateData.content = @contentRendered
					layout.render triggerRenderEvent, templateData, (err) =>
						@contentRendered = layout.contentRendered
						@extensionRendered = layout.extension
						@refresh()
						logger.log 'debug', "Rendering completed for #{@relativePath}"
						next err
			else
				logger.log 'debug', "Rendering completed for #{@relativePath}"
				next err
		
		tasks.total = @extensions.length-1

		# Check tasks
		if tasks.total <= 0
			# No rendering necessary
			tasks.total = 1
			tasks.complete()
			return
		
		# Clone extensions
		extensions = []
		for extension in @extensions
			extensions.unshift extension

		# Cycle through all the extension groups
		previousExtension = null
		for extension in extensions
			# Has a previous extension
			if previousExtension
				# Event Data
				eventData =
					inExtension: previousExtension
					outExtension: extension
					templateData: templateData
					file: @
				
				# Render through plugins
				triggerRenderEvent eventData, (err) =>
					return tasks.exit err  if err

					# Update rendered content
					@contentRendered = @content
					@content = @contentSrc

					# Complete
					tasks.complete err
			
			# Cycle
			previousExtension = extension


class Layout extends File
class Document extends File


# -------------------------------------
# Docpad

class Docpad

	# Options
	rootPath: null
	outPath: 'out'
	srcPath: 'src'
	corePath: "#{__dirname}/.."
	skeleton: 'bootstrap'
	maxAge: false
	logLevel: 6
	version: packageJSON.version

	# Docpad
	generating: false
	loading: true
	generateTimeout: null
	actionTimeout: null
	server: null
	port: 9778

	# Models
	Layout: Layout
	Document: Document
	Layouts: Layouts
	Documents: Documents
	
	# Plugins
	PluginsArray: []
	PluginsObject: {}

	# Skeletons
	skeletons:
		bootstrap:
			repo: 'https://github.com/balupton/bootstrap.docpad.git'


	# ---------------------------------
	# Main

	# Init
	constructor: ({rootPath,outPath,srcPath,skeleton,maxAge,port,server,logLevel}={}) ->
		# Options
		@PluginsArray = []
		@PluginsObject = {}
		@port = port  if port
		@maxAge = maxAge  if maxAge
		@server = server  if server
		@rootPath = path.normalize(rootPath || process.cwd())
		@outPath = path.normalize(outPath || "#{@rootPath}/#{@outPath}")
		@srcPath = path.normalize(srcPath || "#{@rootPath}/#{@srcPath}")
		@skeleton = skeleton  if skeleton

		# Logger
		logger = new caterpillar.Logger
			transports:
				level: logLevel or @logLevel
				formatter:
					module: module
		
		# Version Check
		@compareVersions()
		
		# Load Plugins
		@loadPlugins null, =>
			@loading = false

	
	# Compare versions
	compareVersions: ->
		try
			versionCompare = require 'version-compare'  unless versionCompare
			request = require 'request'  unless request
			request 'https://raw.github.com/balupton/docpad/master/package.json', (err,response,body) =>
				if not err and response.statusCode == 200
					data = JSON.parse body
					unless versionCompare(@version,data.version,'>=')
						growl.notify 'There is a new version of docpad available'
						logger.log 'notice', """
							There is a new version of docpad available, you should probably upgrade...
							current version:  #{@version}
							new version:      #{data.version}
							grab it here:     #{data.homepage}
							"""
		catch err
			false
	

	# Initialise the Skeleton
	initialiseSkeleton: (skeleton, destinationPath, next) ->
		# Prepare
		skeletonRepo = @skeletons[skeleton].repo
		logger.log 'info', "[#{skeleton}] Initialising the Skeleton to #{destinationPath}"
		snoring = false
		notice = setTimeout(
			->
				snoring = true
				logger.log 'notice', "[#{skeleton}] This could take a while, grab a snickers"
			2000
		)

		# Async
		tasks = new util.Group (err) ->
			logger.log 'info', "[#{skeleton}] Initialised the Skeleton"  unless err
			next err
		tasks.total = 2
		
		# Pull
		logger.log 'debug', "[#{skeleton}] Pulling in the Skeleton"
		child = exec(
			# Command
			"git init; git remote add skeleton #{skeletonRepo}; git pull skeleton master"
			
			# Options
			{
				cwd: destinationPath
			}

			# Next
			(err,stdout,stderr) ->
				# Output
				if err
					console.log stdout.replace(/\s+$/,'')  if stdout
					console.log stderr.replace(/\s+$/,'')  if stderr
					return next err
				
				# Log
				logger.log 'debug', "[#{skeleton}] Pulled in the Skeleton"

				# Submodules
				path.exists "#{destinationPath}/.gitmodules", (exists) ->
					tasks.complete()  unless exists
					logger.log 'debug', "[#{skeleton}] Initialising Submodules for Skeleton"
					child = exec(
						# Command
						'git submodule init; git submodule update; git submodule foreach --recursive "git init; git checkout master; git submodule init; git submodule update"'
						
						# Options
						{
							cwd: destinationPath
						}

						# Next
						(err,stdout,stderr) ->
							# Output
							if err
								console.log stdout.replace(/\s+$/,'')  if stdout
								console.log stderr.replace(/\s+$/,'')  if stderr
								return tasks.complete(err)  
							
							# Complete
							logger.log 'debug', "[#{skeleton}] Initalised Submodules for Skeleton"
							tasks.complete()
					)
				
				# NPM
				path.exists "#{destinationPath}/package.json", (exists) ->
					tasks.complete()  unless exists
					logger.log 'debug', "[#{skeleton}] Initialising NPM for Skeleton"
					child = exec(
						# Command
						'npm install'

						# Options
						{
							cwd: destinationPath
						}

						# Next
						(err,stdout,stderr) ->
							# Output
							if err
								console.log stdout.replace(/\s+$/,'')  if stdout
								console.log stderr.replace(/\s+$/,'')  if stderr
								return tasks.complete(err)  
							
							# Complete
							logger.log 'debug', "[#{skeleton}] Initialised NPM for Skeleton"
							tasks.complete()
					)
		)
			

	# Clean Models
	cleanModels: (next) ->
		@Layouts = Layouts = new queryEngine.Collection
		@Documents = Documents = new queryEngine.Collection
		Layout::save = ->
			Layouts[@id] = @
		Document::save = ->
			Documents[@id] = @
		next()  if next


	# Handle
	action: (action,next=null) ->
		# Prepare
		next or= -> process.exit()

		# Clear
		if @actionTimeout
			clearTimeout(@actionTimeout)
			@actionTimeout = null

		# Check
		if @loading
			@actionTimeout = setTimeout(
				=>
					@action(action, next)
				1000
			)
			return
		
		# Handle
		switch action
			when 'skeleton', 'scaffold'
				@skeletonAction (err) ->
					return @error(err)  if err
					next()

			when 'generate'
				@generateAction (err) ->
					return @error(err)  if err
					next()

			when 'watch'
				@watchAction (err) ->
					return @error(err)  if err
					logger.log 'info', 'DocPad is now watching you...'

			when 'server', 'serve'
				@serverAction (err) ->
					return @error(err)  if err
					logger.log 'info', 'DocPad is now serving you...'

			else
				@skeletonAction (err) =>
					return @error(err)  if err
					@generateAction (err) =>
						return @error(err)  if err
						@serverAction (err) =>
							return @error(err)  if err
							@watchAction (err) =>
								return @error(err)  if err
								logger.log 'info', 'DocPad is is now watching and serving you...'
	

	# Handle an error
	error: (err) ->
		logger.log 'err', "An error occured: #{err}\n", err  if err



	# ---------------------------------
	# Plugins

	# Register a Plugin
	# next(err)
	registerPlugin: (plugin,next) ->
		# Prepare
		error = null

		# Plugin Path
		if typeof plugin is 'string'
			try
				pluginPath = plugin
				plugin = require pluginPath
				return @registerPlugin plugin, next
			catch err
				logger.log 'warn', 'Unable to load plugin', pluginPath
				logger.log 'debug', err
		
		# Loaded Plugin
		else if plugin and (plugin.name? or plugin::name?)
			plugin = new plugin  if typeof plugin is 'function'
			@PluginsObject[plugin.name] = plugin
			@PluginsArray.push plugin
			@PluginsArray.sort (a,b) -> a.priority < b.priority
			logger.log 'debug', "Loaded plugin [#{plugin.name}]"
		
		# Unknown Plugin Type
		else
			logger.log 'warn', 'Unknown plugin type', plugin
		
		# Forward
		next error
	

	# Get a plugin by it's name
	getPlugin: (pluginName) ->
		@PluginsObject[pluginName]


	# Trigger a plugin event
	# next(err)
	triggerEvent: (eventName,data,next) ->
		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', "Plugins completed for #{eventName}"
			next err
		tasks.total = @PluginsArray.length

		# Cycle
		for plugin in @PluginsArray
			data.docpad = @
			data.logger = logger
			data.util = util
			plugin[eventName].apply plugin, [data,tasks.completer()]


	# Load Plugins
	loadPlugins: (pluginsPath, next) ->
		unless pluginsPath
			# Async
			tasks = new util.Group (err) ->
				logger.log 'debug', 'Plugins loaded'
				next err
			
			tasks.push => @loadPlugins "#{__dirname}/plugins", tasks.completer()
			if @rootPath isnt __dirname and path.existsSync "#{@rootPath}/plugins"
				tasks.push => @loadPlugins "#{@rootPath}/plugins", tasks.completer()
			
			tasks.async()

		else
			util.scandir(
				# Path
				pluginsPath,

				# File Action
				(fileFullPath,fileRelativePath,nextFile) =>
					if /\.plugin\.[a-zA-Z0-9]+/.test(fileRelativePath)
						@registerPlugin fileFullPath, nextFile
				
				# Dir Action
				false,

				# Next
				(err) ->
					logger.log 'debug', "Plugins loaded for #{pluginsPath}"
					next err
			)


	# ---------------------------------
	# Actions

	# Clean the database
	generateClean: (next) ->
		# Prepare
		logger.log 'debug', 'Cleaning started'

		# Models
		@cleanModels()
		
		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Cleaning finished'  unless err
			next err
		tasks.total = 2

		# Layouts
		@Layouts.remove {}, (err) ->
			logger.log 'debug', 'Cleaned layouts'  unless err
			tasks.complete err
		
		# Documents
		@Documents.remove {}, (err) ->
			logger.log 'debug', 'Cleaned documents'  unless err
			tasks.complete err


	# Check if the file path is ignored
	# next(err,ignore)
	filePathIgnored: (fileFullPath,next) ->
		if path.basename(fileFullPath).startsWith('.') or path.basename(fileFullPath).finishesWith('~')
			next null, true
		else
			next null, false


	# Parse the files
	generateParse: (nextTask) ->
		# Requires
		yaml = require 'yaml'  unless yaml
		docpad = @

		# Log
		logger.log 'debug', 'Parsing files'

		# Paths
		layoutsSrcPath = @srcPath+'/layouts'
		documentsSrcPath = @srcPath+'/documents'

		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Parsed files'  unless err
			nextTask err
		tasks.total = 2

		# Layouts
		util.scandir(
			# Path
			layoutsSrcPath,

			# File Action
			(fileFullPath,fileRelativePath,nextFile) ->
				# Ignore?
				docpad.filePathIgnored fileFullPath, (err,ignore) ->
					return nextFile(err)  if err or ignore
					layout = new Layout fileFullPath, fileRelativePath
					layout.load (err) ->
						return nextFile err  if err
						layout.save()
						nextFile err
				
			# Dir Action
			false,

			# Next
			(err) ->
				logger.log 'warn', 'Failed to parse layouts', err  if err
				tasks.complete err
		)

		# Documents
		util.scandir(
			# Path
			documentsSrcPath,

			# File Action
			(fileFullPath,fileRelativePath,nextFile) ->
				# Ignore?
				docpad.filePathIgnored fileFullPath, (err,ignore) ->
					return nextFile(err)  if err or ignore
					document = new Document fileFullPath, fileRelativePath
					document.load (err) ->
						return nextFile err  if err
						document.save()
						nextFile err
			
			# Dir Action
			false,

			# Next
			(err) ->
				logger.log 'warn', 'Failed to parse documents', err  if err
				tasks.complete err
		)


	# Generate render
	generateRender: (next) ->
		docpad = @

		# Async
		tasks = new util.Group (err) ->
			next err

		# Prepare site data
		Site = site =
			date: new Date()

		# Prepare template data
		documents = Documents.find({}).sort({'date':-1})
		templateData = 
			documents: documents
			document: null
			Documents: documents
			Document: null
			site: site
			Site: site

		# Prepare event
		triggerRenderEvent = (args...) ->
			args.unshift('render')
			docpad.triggerEvent.apply(docpad,args)
		
		# Trigger Helpers
		@triggerEvent 'renderStarted', {documents,templateData}, (err) ->
			return next err  if err
			# Render documents
			tasks.total += documents.length
			documents.forEach (document) ->
				templateData.document = templateData.Document = document
				document.render(
					triggerRenderEvent
					templateData
					tasks.completer()
				)


	# Write files
	generateWriteFiles: (next) ->
		logger.log 'debug', 'Writing files'
		util.cpdir(
			# Src Path
			@srcPath+'/files',
			# Out Path
			@outPath
			# Next
			(err) ->
				logger.log 'debug', 'Wrote files'  unless err
				next err
		)


	# Write documents
	generateWriteDocuments: (next) ->
		outPath = @outPath
		logger.log 'debug', 'Writing documents'

		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Wrote documents'  unless err
			next err

		# Find documents
		Documents.find {}, (err,documents,length) ->
			# Error
			return tasks.exit err  if err

			# Cycle
			tasks.total += length
			documents.forEach (document) ->
				# Generate path
				fileFullPath = "#{outPath}/#{document.url}" #relativeBase+'.html'
				# Ensure path
				util.ensurePath path.dirname(fileFullPath), (err) ->
					# Error
					return tasks.exit err  if err

					# Write document
					fs.writeFile fileFullPath, document.contentRendered, (err) ->
						tasks.complete err


	# Write
	generateWrite: (next) ->
		# Handle
		logger.log 'debug', 'Writing everything'

		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Wrote everything'  unless err
			next err
		tasks.total = 2

		# Files
		@generateWriteFiles tasks.completer()
		
		# Documents
		@generateWriteDocuments tasks.completer()


	# Generate
	generateAction: (next) ->
		# Requires
		queryEngine = require('query-engine')  unless queryEngine

		# Prepare
		docpad = @

		# Clear
		if @generateTimeout
			clearTimeout(@generateTimeout)
			@generateTimeout = null

		# Check
		if @generating
			logger.log 'notice', 'Generate request received, but we are already busy generating... waiting...'
			@generateTimeout = setTimeout(
				=>
					@generateAction next
				500
			)
		else
			logger.log 'info', 'Generating...'
			@generating = true

		# Continue
		path.exists @srcPath, (exists) ->
			# Check
			if exists is false
				return next new Error 'Cannot generate website as the src dir was not found'

			# Log
			logger.log 'debug', 'Cleaning the out path'

			# Continue
			util.rmdir docpad.outPath, (err,list,tree) ->
				if err
					logger.log 'err', 'Failed to clean the out path', docpad.outPath
					return next err
				logger.log 'debug', 'Cleaned the out path'
				# Generate Clean
				docpad.generateClean (err) ->
					return next err  if err
					# Clean Completed
					docpad.triggerEvent 'cleanFinished', {}, (err) ->
						return next err  if err
						# Generate Parse
						docpad.generateParse (err) ->
							return next err  if err
							# Parse Completed
							docpad.triggerEvent 'parseFinished', {}, (err) ->
								return next err  if err
								# Generate Render
								docpad.generateRender (err) ->
									return next err  if err
									# Render Completed
									docpad.triggerEvent 'renderFinished', {}, (err) ->
										return next err  if err
										docpad.generateWrite (err) ->
											# Write Completed
											docpad.triggerEvent 'writeFinished', {}, (err) ->
												unless err
													growl.notify (new Date()).toLocaleTimeString(), title: 'Website Generated'
													logger.log 'info', 'Generated'
													docpad.cleanModels()
													docpad.generating = false
												next err


	# Watch
	watchAction: (next) ->
		# Requires
		watchTree = require 'watch-tree'	unless watchTree

		# Prepare
		docpad = @

		# Log
		logger.log 'Watching setup starting...'

		# Watch the src directory
		watcher = watchTree.watchTree(docpad.srcPath)
		watcher.on 'fileDeleted', (path) ->
			docpad.generateAction ->
				logger.log 'Regenerated due to file delete at '+(new Date()).toLocaleString()
		watcher.on 'fileCreated', (path,stat) ->
			docpad.generateAction ->
				logger.log 'Regenerated due to file create at '+(new Date()).toLocaleString()
		watcher.on 'fileModified', (path,stat) ->
			docpad.generateAction ->
				logger.log 'Regenerated due to file change at '+(new Date()).toLocaleString()

		# Log
		logger.log 'Watching setup'

		# Next
		next()


	# Skeleton
	skeletonAction: (next) ->
		# Prepare
		docpad = @
		skeleton = @skeleton
		destinationPath = @rootPath

		# Copy
		path.exists docpad.srcPath, (exists) =>
			# Check
			if exists
				logger.log 'notice', 'Cannot place skeleton as the desired structure already exists'
				return next()
			
			# Initialise Skeleton
			logger.log 'info', "About to initialise the skeleton [#{skeleton}] to [#{destinationPath}]"
			@initialiseSkeleton skeleton, destinationPath, (err) ->
				return next err


	# Server
	serverAction: (next) ->
		# Requires
		express = require 'express'			unless express

		# Server
		if @server
			listen = false
		else
			listen = true
			@server = express.createServer()

		# Configuration
		@server.configure =>
			# Routing
			if @maxAge
				@server.use express.static @outPath, maxAge: @maxAge
			else
				@server.use express.static @outPath

		# Route something
		@server.get /^\/docpad/, (req,res) ->
			res.send 'DocPad!'
		
		# Start server listening
		if listen
			@server.listen @port
			logger.log 'info', 'Express server listening on port', @server.address().port, 'and directory', @outPath

		# Plugins
		@triggerEvent 'serverFinished', {@server}, (err) ->
			# Forward
			next err

# API
docpad =
	Docpad: Docpad
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad
