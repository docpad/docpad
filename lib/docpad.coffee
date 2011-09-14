###
Docpad by Benjamin Lupton
The easiest way to generate your static website.

Recent things since last release:
	
	1. Added plugin infrastructure
	2. Moved clean urls to plugin
	3. Moved relations to plugin
	4. Moved jade and markdown parsing to plugin

Things to do before next release:

	1. Add plugin scanning and loading
	2. Add better commenting structure (like Buildr's)
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

		# Register Plugin
		if plugin instanceof Plugin
			@PluginsObject[plugin.name] = plugin
			@PluginsArray.push plugin
			@PluginsArray.sort (a,b) -> a.priority < b.priority
		else if typeof plugin is 'String'
			try
				@registerPlugin require plugin
			catch err
				error = new Error 'Unknown plugin: '+plugin
		else
			error = new Eerror 'Unknown plugin: '+plugin
		
		# Forward
		next error

	# Trigger a plugin event
	# next(err)
	triggerEvent: (eventName,data,next) ->
		# Async
		tasks = new util.Group (err) ->
			console.log "Plugins completed for #{eventName}"
			next err
		tasks.total = @PluginsArray.length

		# Cycle
		for plugin in @PluginsArray
			data.docpad = @
			plugin[eventName].apply plugin, [data,tasks.completer()]

	# Trigger a parseFile event
	# next(err)
	triggerParseFileEvent: (data,next) ->
		# Sync
		tasks = new util.Group (err) ->
			console.log "Parsers completed for #{eventName}"
			next err

		if fileMeta.parsers and fileMeta.parsers.length
			for pluginName in fileMeta.parsers
				plugin = @getPlugin pluginName
				continue  unless plugin
				tasks.push (-> (plugin,data,queue) ->
					plugin.parseContent.apply plugin, [data,queue.completer()]
				)(plugin,data,queue)
		else
			for plugin in @PluginArray
				if fileMeta.extension in plugin.parseExtensions
					tasks.push (-> (plugin,data,queue) ->
						plugin.parseContent.apply plugin, [data,queue.completer()]
					)(plugin,data,queue)
		
		tasks.sync()
	
	# Load Plugins
	loadPlugins: (pluginsPath, next) ->
		unless pluginsPath
			# Async
			tasks = new util.Group (err) ->
				console.log "Plugins loaded for #{pluginsPath}"
				next err
			
			tasks.push => @loadPlugins "#{__dirname}/plugins"
			if @rootPath isnt __dirname
				tasks.push => @loadPlugins "#{@rootPath}/plugins"
			
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
				next
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
		@loadPlugins =>
			caterpillar.log 'info', 'finished loading'
			@loading = true

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
					console.log 'DocPad is now watching you...'

			when 'server'
				@serverAction (err) ->
					throw err  if err
					console.log 'DocPad is now serving you...'

			else
				@skeletonAction (err) =>
					throw err  if err
					@generateAction (err) =>
						throw err  if err
						@serverAction (err) =>
							throw err  if err
							@watchAction (err) =>
								throw err  if err
								console.log 'DocPad is is now watching and serving you...'

	# Clean the database
	generateClean: (next) ->
		# Prepare
		console.log 'Cleaning'

		# Models
		@cleanModels()
		
		# Async
		util.parallel \
			# Tasks
			[
				(next) =>
					@Layouts.remove {}, (err) ->
						unless err
							console.log 'Cleaned Layouts'
						next err

				(next) =>
					@Documents.remove {}, (err) ->
						unless err
							console.log 'Cleaned Documents'
						next err
			],
			# Completed
			(err) ->
				unless err
					console.log 'Cleaned'
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
					if path.basename(fileFullPath).startsWith('.')
						console.log 'Hidden Document:', fileRelativePath
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
								console.log 'Ignored Document:', fileRelativePath
								return nextFile()

							# We are cared about! Yay!
							else
								callback fileMeta, nextFile
				
				# Dir Action
				false,

				# Next
				(err) ->
					if err
						console.log 'Failed to parse the directory:',fullPath
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
						console.log 'Parsed Layout:', layout.relativeBase
						nextFile()
					,
					# All Parsed
					(err) ->
						unless err
							console.log 'Parsed Layouts'
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
						console.log 'Parsed Document:', document.relativeBase
						nextFile()
					,
					# All Parsed
					(err) ->
						unless err
							console.log 'Parsed Documents'
						taskCompleted err
				)
			],
			# Completed
			(err) ->
				unless err
					console.log 'Parsed Files'
				nextTask err

	# Generate relations
	generateRelations: (next) ->
		# Requires
		eco = require 'eco'	 unless eco

		# Prepare
		Documents = @Documents
		console.log 'Generating Relations'

		# Async
		tasks = new util.Group (err) ->
			console.log 'Generated Relations'
			next err

		# Find documents
		Documents.find {}, (err,documents,length) ->
			return tasks.exit err  if err
			tasks.total += length
			documents.forEach (document) ->
				# Find related documents
				Documents.find {tags:{'$in':document.tags}}, (err,relatedDocuments) ->
					# Check
					if err
						return tasks.exit err
					else if relatedDocuments.length is 0
						return tasks.complete()

					# Fetch
					relatedDocumentsArray = []
					relatedDocuments.sort (a,b) ->
						return a.tags.hasCount(document.tags) < b.tags.hasCount(document.tags)
					.forEach (relatedDocument) ->
						return null  if document.url is relatedDocument.url
						relatedDocumentsArray.push relatedDocument

					# Save
					document.relatedDocuments = relatedDocumentsArray
					document.save()
					tasks.complete()

	# Generate render
	generateRender: (next) ->
		Layouts = @Layouts
		Documents = @Documents
		console.log 'Generating Render'

		# Render helper
		_render = (document,layoutData) ->
			rendered = document.content
			rendered = eco.render rendered, layoutData
			return rendered

		# Render recursive helper
		_renderRecursive = (content,child,layoutData,next) ->
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
					layoutData.content = content
					content = _render parent, layoutData

					# Recurse
					_renderRecursive content, parent, layoutData, next
			# Handle loner
			else
				next content

		# Render
		render = (document,layoutData,next) ->
			# Render original
			renderedContent = _render document, layoutData

			# Wrap in parents
			_renderRecursive renderedContent, document, layoutData, (contentRendered) ->
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
			document: document
			Documents: documents
			Document: document
			site: site
			Site: site
		
		# Trigger Helpers
		@triggerEvent 'renderFileStarted', {documents,templateData}, (err) ->
			return next err  if err
			# Render documents
			tasks.total += documents.length
			documents.forEach (document) ->
				render(
					# Document
					document
					# layoutData
					layoutData
					# next
					tasks.completer()
				)

	# Write files
	generateWriteFiles: (next) ->
		console.log 'Copying Files'
		util.cpdir(
			# Src Path
			@srcPath+'/files',
			# Out Path
			@outPath
			# Next
			(err) ->
				unless err
					console.log 'Copied Files'
				next err
		)

	# Write documents
	generateWriteDocuments: (next) ->
		Documents = @Documents
		outPath = @outPath
		console.log 'Writing Documents'

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
		console.log 'Writing Files'
		util.parallel \
			# Tasks
			[
				# Files
				(next) =>
					@generateWriteFiles (err) ->
						unless err
							console.log 'Wrote Layouts'
						next err
				# Documents
				(next) =>
					@generateWriteDocuments (err) ->
						unless err
							console.log 'Wrote Documents'
						next err
			],
			# Completed
			(err) ->
				unless err
					console.log 'Wrote Files'
				next err

	# Generate
	generateAction: (next) ->
		# Requires
		unless queryEngine
			queryEngine = require 'query-engine'

		# Prepare
		docpad = @

		# Check
		if @generating
			console.log 'Generate request received, but we are already busy generating...'
			return next()
		else
			console.log 'Generating...'
			@generating = true

		# Continue
		path.exists @srcPath, (exists) ->
			# Check
			if exists is false
				throw new Error 'Cannot generate website as the src dir was not found'

			# Log
			console.log 'Cleaning the out path'

			# Continue
			util.rmdir docpad.outPath, (err,list,tree) ->
				if err
					console.log 'Failed to clean the out path '+docpad.outPath
					return next err
				console.log 'Cleaned the out path'
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
													console.log 'Website Generated'
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
		console.log 'Setting up watching...'

		# Watch the src directory
		watcher = watchTree.watchTree(docpad.srcPath)
		watcher.on 'fileDeleted', (path) ->
			docpad.generateAction ->
				console.log 'Regenerated due to file delete at '+(new Date()).toLocaleString()
		watcher.on 'fileCreated', (path,stat) ->
			docpad.generateAction ->
				console.log 'Regenerated due to file create at '+(new Date()).toLocaleString()
		watcher.on 'fileModified', (path,stat) ->
			docpad.generateAction ->
				console.log 'Regenerated due to file change at '+(new Date()).toLocaleString()

		# Log
		console.log 'Watching setup'

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
				console.log 'Cannot place skeleton as the desired structure already exists'
				next()
			else
				console.log 'Copying the skeleton ['+skeleton+'] to ['+toPath+']'
				util.cpdir skeletonPath, toPath, (err) ->
					unless err
						console.log 'Copied the skeleton'
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
			console.log 'Express server listening on port %d and directory %s', @server.address().port, @outPath

		# Plugins
		@triggerEvent 'serverFinished', {server}, (err) ->
			# Forward
			next err

# API
docpad =
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad
