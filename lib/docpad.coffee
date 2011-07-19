# Requirements
fs = require 'fs'
path = require 'path'
sys = require 'sys'
express = false
yaml = false
gfm = false
jade = false
eco = false
watchTree = false
util = false


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

		# Models
		@cleanModels = (next) =>
			Layouts = @Layouts = {}
			Documents = @Documents = {}
			@Layout::save = ->
				Layouts[@id] = @
			@Document::save = ->
				Documents[@id] = @
			next false  if next
		@cleanModels()

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
		# Requires
		util = require 'bal-util'  unless util

		# Prepare
		console.log 'Cleaning Files'

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
					console.log 'Cleaned Files'
				next err

	# Parse the files
	generateParse: (nextTask) ->
		# Requires
		util = require 'bal-util'  unless util
		yaml = require 'yaml'  unless yaml
		gfm = require 'github-flavored-markdown'  unless gfm
		jade = require 'jade'  unless jade

		# Prepare
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
				switch fileMeta.extension
					when '.jade'
						result = jade.render fileBody
					when '.md'
						fileMeta.content = gfm.parse fileBody
					else
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
				switch fileMeta.extension
					when '.jade','.md'
						fileMeta.url = '/'+fileMeta.relativeBase+'.html'
					else
						fileMeta.url = '/'+fileMeta.relativeBase+fileMeta.extension

				# Store fileMeta
				next fileMeta

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
						return nextFile false

					# Stat file
					fs.stat fileFullPath, (err,fileStat) ->
						# Check error
						return nextFile err  if err

						# Parse file
						parseFile fileFullPath,fileRelativePath,fileStat, (fileMeta) ->
							# Were we ignored?
							if fileMeta.ignore
								console.log 'Ignored Document:', fileRelativePath
								return nextFile false

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
						nextFile false
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
						nextFile false
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
		eco = require 'eco'	unless eco

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
						return tasks.complete false

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
					tasks.complete false

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
				next false

		# Async
		tasks = new util.Group (err) -> next err

		# Prepare site data
		Site = site =
			date: new Date()

		# Find documents
		documents = Documents.find({}).sort({'date':-1})
		tasks.total += documents.length
		documents.forEach (document) ->
			render(
				# Document
				document
				# layoutData
				{
					documents: documents
					document: document
					Documents: documents
					Document: document
					site: site
					Site: site
				}
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
		# Requires
		util = require 'bal-util'  unless util

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
			queryEngine = true
			require 'query-engine'
		util = require 'bal-util'	unless util

		# Prepare
		docpad = @

		# Check
		if @generating
			console.log 'Generate request received, but we are already busy generating...'
			return next false
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
				docpad.generateClean (err) ->
					return next err  if err
					docpad.generateParse (err) ->
						return next err  if err
						docpad.generateRelations (err) ->
							return next err  if err
							docpad.generateRender (err) ->
								return next err  if err
								docpad.generateWrite (err) ->
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
		next false

	# Skeleton
	skeletonAction: (next) ->
		# Requires
		util = require 'bal-util'	unless util

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
				next false
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

		# Try .html for urls with no extension
		@server.get /\/[a-z0-9]+\/?$/i, (req,res,next) =>
			filePath = @outPath+req.url.replace(/\.\./g,'')+'.html' # stop tricktsers
			path.exists filePath, (exists) ->
				if exists
					fs.readFile filePath, (err,data) ->
						if err
							res.send(err.message, 500)
						else
							res.send(data.toString())
				else
					next false

		# Start server listening
		if listen
			@server.listen @port
			console.log 'Express server listening on port %d and directory %s', @server.address().port, @outPath

		# Forward
		next false

# API
docpad =
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad
