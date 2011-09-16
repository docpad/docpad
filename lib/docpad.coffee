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
express = false
yaml = false
eco = false
watchTree = false
queryEngine = false

# Logger
logger = new caterpillar.Logger
	transports:
		level: 7
		formatter:
			module: module

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
		@tags = []
		@relatedDocuments = []

	# Load
	# next(err)
	load: (next) ->
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
			@filename = @basename.replace(/\..*/, '')

			# Temp
			fullDirPath = path.dirname @fullPath
			relativeDirPath = path.dirname(@relativePath).replace(/^\.$/,'')

			# Update Meta
			@content = fileBody
			@contentSrc = fileBody
			@contentRaw = fileData
			@relativeBase = (if relativeDirPath.length then relativeDirPath+'/' else '')+@filename
			@title = @title || path.basename(@fullPath)
			@date = new Date(@date)  if @date
			@slug = util.generateSlugSync @relativeBase
			@id = @slug
			@url = '/'+@relativeBase+'.'+@extension

			# Apply User Meta
			for own key, value of fileMeta
				@[key] = value

			# Complete
			tasks.complete()

class Layout extends File
	
class Document extends File


# -------------------------------------
# Docpad

class Docpad

	# Options
	rootPath: null
	outPath: 'out'
	srcPath: 'src'
	skeletonsPath: 'skeletons'
	defaultSkeleton: 'bootstrap'
	maxAge: false

	# Docpad
	generating: false
	loading: true
	generateTimeout: null
	server: null
	port: 9778

	# Models
	Layout: Layout
	Document: Document
	Layouts: {}
	Documents: {}
	

	# ---------------------------------
	# Plugins

	# Plugins Array
	PluginsArray: []

	# Plugins Object
	PluginsObject: {}
	
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

	# Trigger the renderFile event
	# next(err)
	triggerRenderFileEvent: (data,next) ->
		# Prepare
		fileMeta = data.fileMeta
		count = 0

		# Sync
		tasks = new util.Group (err) ->
			logger.log 'debug', "Renderers completed for #{fileMeta.relativePath}"
			next err

		if fileMeta.renderers and fileMeta.renderers.length
			for pluginName in fileMeta.renderers
				plugin = @getPlugin pluginName
				continue  unless plugin
				++count
				tasks.push ((plugin,data,tasks) -> ->
					plugin.renderFile.apply plugin, [data,tasks.completer()]
				)(plugin,data,tasks)
		else
			for plugin in @PluginsArray
				runPlugin = false

				if plugin.extensions is true
					runPlugin = true
				else if plugin.extensions
					for extension in fileMeta.extensions
						if extension in plugin.extensions
							runPlugin = true
							break
				
				if runPlugin
					++count
					tasks.push ((plugin,data,tasks) -> ->
						plugin.renderFile.apply plugin, [data,tasks.completer()]
					)(plugin,data,tasks)
		
		if count
			tasks.sync()
		else
			next()
	
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
					@registerPlugin fileFullPath, nextFile
				
				# Dir Action
				false,

				# Next
				(err) ->
					logger.log 'debug', "Plugins loaded for #{pluginsPath}"
					next err
			)


	# ---------------------------------
	# Main

	# Init
	constructor: ({command,rootPath,outPath,srcPath,skeletonsPath,maxAge,port,server}={}) ->
		# Options
		command = command || process.argv[2] || false
		@rootPath = rootPath || process.cwd()
		@outPath = outPath || @rootPath+'/'+@outPath
		@srcPath = srcPath || @rootPath+'/'+@srcPath
		@skeletonsPath = skeletonsPath || __dirname+'/../'+@skeletonsPath
		@port = port if port
		@maxAge = maxAge if maxAge
		@server = server if server
		@loadPlugins null, =>
			logger.log 'info', 'Finished loading'
			@loading = false


	# Clean Models
	cleanModels: (next) ->
		Layouts = @Layouts = new queryEngine.Collection
		Documents = @Documents = new queryEngine.Collection
		@Layout::save = ->
			Layouts[@id] = @
		@Document::save = ->
			Documents[@id] = @
		next()  if next
	

	# Handle
	action: (action) ->
		switch action
			when 'skeleton'
				@skeletonAction (err) ->
					throw err  if err
					process.exit()

			when 'generate'
				@generateAction (err) ->
					throw err  if err
					process.exit()

			when 'watch'
				@watchAction (err) ->
					throw err  if err
					logger.log 'info', 'DocPad is now watching you...'

			when 'server'
				@serverAction (err) ->
					throw err  if err
					logger.log 'info', 'DocPad is now serving you...'

			else
				@skeletonAction (err) =>
					throw err  if err
					@generateAction (err) =>
						throw err  if err
						@serverAction (err) =>
							throw err  if err
							@watchAction (err) =>
								throw err  if err
								logger.log 'info', 'DocPad is is now watching and serving you...'


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

		# Prepare
		docpad = @
		Layout = @Layout
		Document = @Document
		Layouts = @Layouts
		Documents = @Documents

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
		# Requires
		docpad = @
		Layouts = @Layouts
		Documents = @Documents

		# Log
		logger.log 'debug', 'Rendering'

		# Render helper
		_renderFile = (fileMeta,templateData,next) ->
			fileMeta.content = fileMeta.contentSrc
			docpad.triggerRenderFileEvent {fileMeta,templateData}, (err) ->
				renderedContent = fileMeta.content
				fileMeta.content = fileMeta.contentSrc
				return next err, renderedContent

		# Render recursive helper
		_renderRecursive = (content,child,templateData,next) ->
			# Handle parent
			if child.layout
				# Find parent
				Layouts.findOne {relativeBase:child.layout}, (err,parent) ->
					# Check
					if err
						return next err
					else if not parent
						err = new Error 'Could not find the layout: '+child.layout
						return next err

					# Render parent
					templateData.content = content
					_renderFile parent, templateData, (err,content) ->
						return next err  if err
						_renderRecursive content, parent, templateData, next
					
			# Handle loner
			else
				next content

		# Render
		renderDocument = (document,templateData,next) ->
			# Adjust templateData
			templateData.document = templateData.Document = document

			# Render original
			_renderFile document, templateData, (err,content) ->
				# Wrap in parents
				_renderRecursive content, document, templateData, (contentRendered) ->
					document.contentRendered = contentRendered
					next()

		# Async
		tasks = new util.Group (err) -> next err

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
		
		# Trigger Helpers
		@triggerEvent 'renderStarted', {documents,templateData}, (err) ->
			return next err  if err
			# Render documents
			tasks.total += documents.length
			documents.forEach (document) ->
				renderDocument(
					# Document
					document
					# templateData
					templateData
					# next
					tasks.completer()
				)


	# Write files
	generateWriteFiles: (next) ->
		logger.log 'debug', 'Copying files'
		util.cpdir(
			# Src Path
			@srcPath+'/files',
			# Out Path
			@outPath
			# Next
			(err) ->
				unless err
					logger.log 'debug', 'Copied files'
				next err
		)


	# Write documents
	generateWriteDocuments: (next) ->
		Documents = @Documents
		outPath = @outPath
		logger.log 'debug', 'Writing documents'

		# Async
		tasks = new util.Group (err) ->
			next err

		# Find documents
		Documents.find {}, (err,documents,length) ->
			# Error
			return tasks.exit err  if err

			# Cycle
			tasks.total += length
			documents.forEach (document) ->
				# Generate path
				fileFullPath = outPath+'/'+document.url #relativeBase+'.html'
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
		logger.log 'debug', 'Writing files'
		util.parallel \
			# Tasks
			[
				# Files
				(next) =>
					@generateWriteFiles (err) ->
						unless err
							logger.log 'debug', 'Wrote layouts'
						next err
				# Documents
				(next) =>
					@generateWriteDocuments (err) ->
						unless err
							logger.log 'debug', 'Wrote documents'
						next err
			],
			# Completed
			(err) ->
				unless err
					logger.log 'debug', 'Wrote files'
				next err


	# Generate
	generateAction: (next) ->
		# Requires
		unless queryEngine
			queryEngine = require 'query-engine'

		# Prepare
		docpad = @

		# Clear
		if @generateTimeout
			clearTimeout(@generateTimeout)
			@generateTimeout = null

		# Check
		if @loading
			logger.log 'notice', 'Generate request received, but we still loading... waiting...'
			@generateTimeout = setTimeout(
				=>
					@generateAction next
				500
			)
			return
		else if @generating
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
				throw new Error 'Cannot generate website as the src dir was not found'

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
		skeleton = (process.argv.length >= 3 and process.argv[2] is 'skeleton' and process.argv[3]) || @defaultSkeleton
		skeletonPath = @skeletonsPath + '/' + skeleton
		toPath = (process.argv.length >= 5 and process.argv[2] is 'skeleton' and process.argv[4]) || @rootPath
		toPath = util.prefixPathSync(toPath,@rootPath)

		# Copy
		path.exists docpad.srcPath, (exists) ->
			if exists
				logger.log 'notice', 'Cannot place skeleton as the desired structure already exists'
				next()
			else
				logger.log 'info', 'Copying the skeleton ['+skeleton+'] to ['+toPath+']'
				util.cpdir skeletonPath, toPath, (err) ->
					unless err
						logger.log 'info', 'Copied the skeleton'
					next err


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
