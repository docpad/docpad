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
		level: 6
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
# Main

class Docpad

	# Options
	rootPath: null
	outPath: 'out'
	srcPath: 'src'
	skeletonsPath: 'skeletons'
	maxAge: false

	# Docpad
	generating: false
	loading: true
	generateTimeout: null
	server: null
	port: 9778

	# Models
	Layout: class
		layout: ''
		fullPath: ''
		relativePath: ''
		relativeBase: ''
		body: ''
		contentRaw: ''
		content: ''
		date: new Date()
		title: ''
	Document: class
		layout: ''
		fullPath: ''
		relativePath: ''
		relativeBase: ''
		url: ''
		tags: []
		relatedDocuments: []
		body: ''
		contentRaw: ''
		content: ''
		contentRendered: ''
		date: new Date()
		title: ''
		slug: ''
		ignore: false
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

	# Trigger a parseFile event
	# next(err)
	triggerParseFileEvent: (data,next) ->
		# Prepare
		fileMeta = data.fileMeta
		count = 0

		# Sync
		tasks = new util.Group (err) ->
			logger.log 'debug', "Parsers completed for #{fileMeta.relativePath}"
			next err

		if fileMeta.parsers and fileMeta.parsers.length
			for pluginName in fileMeta.parsers
				plugin = @getPlugin pluginName
				continue  unless plugin
				++count
				tasks.push ((plugin,data,tasks) -> ->
					console.log plugin
					plugin.parseDocument.apply plugin, [data,tasks.completer()]
				)(plugin,data,tasks)
		else
			for plugin in @PluginsArray
				if plugin.parseExtensions and fileMeta.extension in plugin.parseExtensions
					++count
					tasks.push ((plugin,data,tasks) -> ->
						plugin.parseDocument.apply plugin, [data,tasks.completer()]
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
		util.parallel \
			# Tasks
			[
				(next) =>
					@Layouts.remove {}, (err) ->
						unless err
							logger.log 'debug', 'Cleaned layouts'
						next err

				(next) =>
					@Documents.remove {}, (err) ->
						unless err
							logger.log 'debug', 'Cleaned documents'
						next err
			],
			# Completed
			(err) ->
				unless err
					logger.log 'debug', 'Cleaning finished'
				next err

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

		# File Parser
		parseFile = (fileFullPath,fileRelativePath,fileStat,next) ->
			# Prepare
			fileMeta = {}
			fileData = ''
			fileSplit = []
			fileHead = ''
			fileBody = ''

			# Log
			logger.log 'debug', 'Parsing the file ['+fileRelativePath+']'

			# Read the file
			fs.readFile fileFullPath, (err,data) ->
				return next err  if err

				# Handle data
				fileData = data.toString()
				fileSplit = fileData.split '---'
				if fileSplit.length >= 3 and !fileSplit[0]
					# Extract parts
					fileHead = fileSplit[1].replace(/\t/g,'    ').replace(/\s+$/m,'').replace(/\r\n?/g,'\n')+'\n'
					fileBody = fileSplit.slice(2).join('---')
					fileMeta = yaml.eval fileHead
				else
					# Extract part
					fileBody = fileData

				# Markup
				fileMeta.extension = path.extname fileFullPath
				fileMeta.content = fileBody

				# Temp
				fullDirPath = path.dirname fileFullPath
				relativeDirPath = path.dirname(fileRelativePath).replace(/^\.$/,'')

				# Update Meta
				fileMeta.parsers = []
				fileMeta.contentRaw = fileData
				fileMeta.fullPath = fileFullPath
				fileMeta.relativePath = fileRelativePath
				fileMeta.relativeBase = (if relativeDirPath.length then relativeDirPath+'/' else '')+path.basename(fileRelativePath,path.extname(fileRelativePath))
				fileMeta.body = fileBody
				fileMeta.title = fileMeta.title || path.basename(fileFullPath)
				fileMeta.date = new Date(fileMeta.date || fileStat.ctime)
				fileMeta.slug = util.generateSlugSync fileMeta.relativeBase
				fileMeta.id = fileMeta.slug

				# Update Url
				fileMeta.url = '/'+fileMeta.relativeBase+fileMeta.extension
				
				# Parsers
				docpad.triggerParseFileEvent {fileMeta}, (err) ->
					return next err  if err
					
					# Update Url
					fileMeta.url = '/'+fileMeta.relativeBase+fileMeta.extension
					
					# Plugins
					docpad.triggerEvent 'parseFileFinished', {fileMeta}, (err) ->
						# Forward
						return next err, fileMeta

		# Files Parser
		parseFiles = (fullPath,callback,nextTask) ->
			util.scandir(
				# Path
				fullPath,

				# File Action
				(fileFullPath,fileRelativePath,nextFile) ->
					# Ignore hidden files
					if path.basename(fileFullPath).startsWith('.') or path.basename(fileFullPath).finishesWith('~')
						logger.log 'info', 'Ignored hidden document:', fileRelativePath
						return nextFile()

					# Stat file
					fs.stat fileFullPath, (err,fileStat) ->
						# Check error
						return nextFile err  if err

						# Parse file
						parseFile fileFullPath,fileRelativePath,fileStat, (err,fileMeta) ->
							return nextFile err  if err

							# Were we ignored?
							if fileMeta.ignore
								logger.log 'info', 'Ignored document:', fileRelativePath
								return nextFile()

							# We are cared about! Yay!
							else
								callback fileMeta, nextFile
				
				# Dir Action
				false,

				# Next
				(err) ->
					if err
						logger.log 'warn', 'Failed to parse the directory:', fullPath, err
					nextTask err
			)

		# Parse Files
		util.parallel \
			# Tasks
			[
				# Layouts
				(taskCompleted) -> parseFiles(
					# Full Path
					layoutsSrcPath,
					# Callback: Each File
					(fileMeta,nextFile) ->
						# Prepare
						layout = new Layout()

						# Apply
						for own key, fileMetaValue of fileMeta
							layout[key] = fileMetaValue

						# Save
						layout.save()
						logger.log 'debug', 'Parsed layout:', layout.relativeBase
						nextFile()
					,
					# All Parsed
					(err) ->
						unless err
							logger.log 'debug', 'Parsed layouts'
						taskCompleted err
				),
				# Documents
				(taskCompleted) -> parseFiles(
					# Full Path
					documentsSrcPath,
					# One Parsed
					(fileMeta,nextFile) ->
						# Prepare
						document = new Document()

						# Apply
						for own key, fileMetaValue of fileMeta
							document[key] = fileMetaValue

						# Save
						document.save()
						logger.log 'debug', 'Parsed document:', document.relativeBase
						nextFile()
					,
					# All Parsed
					(err) ->
						unless err
							logger.log 'debug', 'Parsing documents finished'
						else
							logger.log 'err', 'Parsing documents failed', err
						taskCompleted err
				)
			],
			# Completed
			(err) ->
				unless err
					logger.log 'debug', 'Parsed files'
				nextTask err

	# Generate render
	generateRender: (next) ->
		# Requires
		eco = require 'eco'	 unless eco
		Layouts = @Layouts
		Documents = @Documents

		# Log
		logger.log 'debug', 'Rendering'

		# Render helper
		_render = (document,templateData) ->
			rendered = document.content
			rendered = eco.render rendered, templateData
			return rendered

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
						return next new Error 'Could not find the layout: '+child.layout

					# Render parent
					templateData.content = content
					content = _render parent, templateData

					# Recurse
					_renderRecursive content, parent, templateData, next
			# Handle loner
			else
				next content

		# Render
		render = (document,templateData,next) ->
			# Adjust templateData
			templateData.document = templateData.Document = document

			# Render original
			renderedContent = _render document, templateData

			# Wrap in parents
			_renderRecursive renderedContent, document, templateData, (contentRendered) ->
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
				render(
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
		skeleton = (process.argv.length >= 3 and process.argv[2] is 'skeleton' and process.argv[3]) || 'balupton'
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
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad
