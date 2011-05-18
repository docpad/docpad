# Requirements
fs = require 'fs'
yaml = require 'yaml'
express = require 'express'
gfm = require 'github-flavored-markdown'
jade = require 'jade'
eco = require 'eco'
path = require 'path'
async = require 'async'
watch = require 'watch'
util = require 'bal-util'
mongoose = require 'mongoose'
Schema = mongoose.Schema 
SchemaTypes = Schema.Types 
ObjectId = Schema.ObjectId


# -------------------------------------
# Prototypes

# Prepare
Array.prototype.hasCount = (arr) ->
	count = 0
	for a in this
		for b in arr
			if a is b
				++count
				break
	return count


Date.prototype.toShortDateString = ->
	return this.toDateString().replace(/^[^\s]+\s/,'')


# -------------------------------------
# Server

docpad =
	# Options
	options:
		rootPath: null
		outPath: 'out'
		srcPath: 'src'
		viewPath: 'views'
		dsn: 'mongodb://localhost/docpad'

	# Variables
	generating: false

	# Model
	LayoutSchema: null
	DocumentSchema: null
	LayoutModel: null
	DocumentModel: null

	# Initialise Server
	init: ->
		# Configure
		@options.rootPath = process.cwd()
		@options.skeletonPath = __dirname+'/../'+@options.srcPath
		@options.srcPath = @options.rootPath+'/'+@options.srcPath
		@options.outPath = @options.rootPath+'/'+@options.outPath
		@options.viewPath = __dirname+'/'+@options.viewPath
		
		# Connect
		mongoose.connect @options.dsn

		# Schemas
		@LayoutSchema = new Schema
			layout: String
			fullPath: String
			relativePath: String
			relativeBase: String
			body: String
			contentRaw: String
			content: String
			date: Date
			title: String
		@DocumentSchema = new Schema
			layout: String 
			fullPath: String 
			relativePath: String 
			relativeBase: String 
			url: String
			tags: [String] 
			relatedDocuments: [
				new Schema
					url: String 
					title: String 
					date: Date
					slug: String
			] 
			body: String 
			contentRaw: String 
			content: String 
			contentRendered: String 
			date: Date 
			title: String
			slug: String
		
		# Models
		mongoose.model 'Layout', @LayoutSchema
		mongoose.model 'Document', @DocumentSchema
		@LayoutModel = mongoose.model 'Layout'
		@DocumentModel = mongoose.model 'Document'

		# Handle
		@main process.argv[2] || false
	
	# Handle
	main: (command) ->
		switch command
			when 'skeleton'
				@skeleton -> process.exit()
			
			when 'generate'
				@generate -> process.exit()
			
			when 'watch'
				@watch ->
			
			when 'server'
				@server ->
			
			else
				@skeleton => @watch => @generate ->
				@server ->
	
	# Clean the database
	generateClean: (next) ->
		async.parallel [
			(callback) ->
				docpad.LayoutModel.remove {}, (err) ->
					throw err if err
					console.log 'Cleaned Layouts'
					callback()
			(callback) ->
				docpad.DocumentModel.remove {}, (err) ->
					throw err if err
					console.log 'Cleaned Documents'
					callback()
		],
		->
			console.log 'Cleaned Files'
			next()
	
	# Parse the files
	generateParse: (next) ->
		# Paths
		layoutsSrcPath = @options.srcPath+'/layouts'
		docsSrcPath = @options.srcPath+'/docs'

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
				throw err if err
				
				# Handle data
				fileData = data.toString()
				fileSplit = fileData.split '---'
				if fileSplit.length is 3 and !fileSplit[0]
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
				fileMeta.url = '/'+fileMeta.relativeBase+'.html'
				fileMeta.body = fileBody
				fileMeta.title = fileMeta.title || path.basename(fileFullPath)
				fileMeta.date = new Date(fileMeta.date || fileStat.ctime)
				fileMeta.slug = util.generateSlugSync fileMeta.relativeBase

				# Store fileMeta
				next fileMeta
		
		# Files Parser
		parseFiles = (fullPath,callback,next) ->
			util.scandir(
				# Path
				fullPath,
				# File Action
				(fileFullPath,fileRelativePath,next) ->
					fs.stat fileFullPath, (err,fileStat) ->
						throw err if err
						parseFile fileFullPath,fileRelativePath,fileStat,(fileMeta) ->
							callback fileMeta, next
				# Dir Action
				false,
				# Next
				(err) ->
					throw err if err
					next()
			)
		
		# Parse Files
		async.parallel [
			# Layouts
			(callback) -> parseFiles(
				# Full Path
				layoutsSrcPath,
				# One Parsed
				(fileMeta,next) ->
					# Prepare
					Layout = new docpad.LayoutModel()

					# Apply
					for own key, fileMetaValue of fileMeta
						Layout[key] = fileMetaValue
					
					# Save
					Layout.save (err) ->
						throw err if err
						console.log 'Parsed Layout:', Layout.relativeBase
						next()
				,
				# All Parsed
				->
					console.log 'Parsed Layouts'
					callback()
			),
			# Documents
			(callback) -> parseFiles(
				# Full Path
				docsSrcPath,
				# One Parsed
				(fileMeta,next) ->
					# Prepare
					Document = new docpad.DocumentModel()

					# Apply
					for own key, fileMetaValue of fileMeta
						Document[key] = fileMetaValue
					
					# Save
					Document.save (err) ->
						throw err if err
						console.log 'Parsed Document:', Document.relativeBase
						next()
				,
				# All Parsed
				->
					console.log 'Parsed Document'
					callback()
			)
		],
		->
			console.log 'Parsed Files'
			next()
		
	# Generate relations
	generateRelations: (next) ->
		# Async
		completed = 0
		total = 0
		complete = ->
			++completed
			if completed is total
				console.log 'Generated Relations'
				next()

		# Find documents
		docpad.DocumentModel.find {}, (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++total

				# Find related documents
				docpad.DocumentModel.find {tags:{'$in':Document.tags}}, (err,relatedDocuments) ->
					# Check
					if err then throw err
					else if relatedDocuments.length is 0 then return complete()
					
					# Fetch
					relatedDocumentsArray = []
					relatedDocuments.sort (a,b) ->
						return a.tags.hasCount(Document.tags) < b.tags.hasCount(Document.tags)
					.forEach (relatedDocument) ->
						if Document.url is relatedDocument.url then return
						relatedDocumentsArray.push
							title: relatedDocument.title
							url: relatedDocument.url
							date: relatedDocument.date
				
					# Save
					Document.relatedDocuments = relatedDocumentsArray
					Document.save (err) ->
						throw err if err
						complete()
	
	# Generate render
	generateRender: (next) ->
		# Render helper
		_render = (Document,templateData) ->
			rendered = Document.content
			rendered = eco.render rendered, templateData
			return rendered
		
		# Render recursive helper
		_renderRecursive = (content,child,templateData,next) ->
			# Handle parent
			if child.layout
				# Find parent
				docpad.LayoutModel.findOne {relativeBase:child.layout}, (err,parent) ->
					# Check
					if err then throw err
					else if not parent then throw new Error 'Could not find the layout: '+child.layout
					
					# Render parent
					templateData.content = content
					content = _render parent, templateData

					# Recurse
					_renderRecursive content, parent, templateData, next
			# Handle loner
			else
				next content
		
		# Render
		render = (Document,templateData,next) ->
			# Render original
			renderedContent = _render Document, templateData
			
			# Wrap in parents
			_renderRecursive renderedContent, Document, templateData, (contentRendered) ->
				Document.contentRendered = contentRendered
				Document.save (err) ->
					throw err if err
					next()
			
		# Async
		completed = 0
		total = 0
		complete = ->
			completed++
			if completed is total
				console.log 'Rendered Files'
				next()
		
		# Find documents
		docpad.DocumentModel.find({}).sort('date',-1).execFind (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++total
				render(
					Document,
					{
						Documents: Documents
						DocumentModel: docpad.DocumentModel
						Document: Document
					},
					complete
				)
	
	# Write files
	generateWriteFiles: (next) ->
		util.cpdir(
			# Src Path
			docpad.options.srcPath+'/public',
			# Out Path
			docpad.options.outPath
			# Next
			(err) ->
				throw err if err
				next()
		)
	
	# Write documents
	generateWriteDocuments: (next) ->
		# Async
		completed = 0
		total = 0
		complete = ->
			completed++
			if completed is total
				console.log 'Rendered Documents'
				next()
		
		# Find documents
		docpad.DocumentModel.find {}, (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++total

				# Generate path
				fileFullPath = docpad.options.outPath+'/'+Document.relativeBase+'.html'

				# Ensure path
				util.ensurePath path.dirname(fileFullPath), (err) ->
					throw err if err
					# Write document
					fs.writeFile fileFullPath, Document.contentRendered, (err) ->
						throw err if err
						complete()
	
	# Write
	generateWrite: (next) ->
		async.parallel [
			# Files
			(callback) ->
				docpad.generateWriteFiles (err) ->
					throw err if err
					callback()
			# Documents
			(callback) -> 
				docpad.generateWriteDocuments (err) ->
					throw err if err
					callback()
		],
		-> 
			next()
	
	# Generate
	generate: (next) ->
		# Check
		if docpad.genetating then return
		else docpad.generating = true

		# Continue
		path.exists docpad.options.srcPath, (exists) ->
			# Check
			if not exists then throw Error 'Cannot generate website as the src dir was not found'

			# Continue
			util.rmdir docpad.options.outPath, (err) ->
				throw err if err
				docpad.generateClean ->
					docpad.generateParse ->
						docpad.generateRelations ->
							docpad.generateRender ->
								docpad.generateWrite ->
									console.log 'Website Generated'
									docpad.generating = false
									next()
	
	# Watch
	watch: (next) ->
		# Watch the src directory
		watch.createMonitor docpad.options.srcPath, (monitor) ->
			
			# File Changed
			monitor.on 'changed', (fileFullPath,newStat,oldStat) ->
				docpad.generate ->
				
			# File Created
			monitor.on 'created', (fileFullPath,stat) ->
				docpad.generate ->
				
			# File Deleted
			monitor.on 'removed', (fileFullPath,stat) ->
				docpad.generate ->
			
			# Next
			next()
	
	# Skeleton
	skeleton: (next) ->
		path.exists docpad.options.srcPath, (exists) ->
			if exists
				console.log 'Cannot place skeleton as the out dir already exists'
				next()
			else
				util.cpdir docpad.options.skeletonPath, docpad.options.srcPath, (err) ->
					throw err if err
					next()
	
	# Server
	server: (next) ->
		# Server
		app = express.createServer()

		# Configuration
		app.configure ->
			# Standard
			app.use express.methodOverride()
			app.use express.errorHandler()
			app.use express.bodyParser()

			# Routing
			app.use app.router
			app.use express.static docpad.options.outPath
		
		# Route something
		app.get /^\/docpad/, (req,res) ->
			res.send 'DocPad!'

		# Init server
		app.listen 9778
		console.log 'Express server listening on port %d', app.address().port

		# Forward
		next()
	
# Initialise docpad
docpad.init()


	