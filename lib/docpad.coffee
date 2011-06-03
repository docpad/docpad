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
sys = require 'sys'
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
# Main

class Docpad

	# Options
	rootPath: null
	outPath: 'out'
	srcPath: 'src'
	skeletonsPath: 'skeletons'
	dsn: 'mongodb://localhost/docpad'

	# Docpad
	generating: false
	server: null
	port: 9778

	# Model
	LayoutSchema: null
	DocumentSchema: null
	LayoutModel: null
	DocumentModel: null

	# Init
	constructor: ({command,rootPath,outPath,srcPath,skeletonsPath,dsn,port}={}) ->
		# Options
		command = command || process.argv[2] || false
		@rootPath = rootPath || process.cwd()
		@outPath = outPath || @rootPath+'/'+@outPath
		@srcPath = srcPath || @rootPath+'/'+@srcPath
		@skeletonsPath = skeletonsPath || __dirname+'/../'+@skeletonsPath
		@dsn = dsn if dsn
		@port = port if port

		# Connect
		mongoose.connect @dsn

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
		@main command
	
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
		console.log 'Cleaning files'

		timeoutCallback = ->
			throw new Error 'Could not connect to the mongod'	
		timeout = setTimeout timeoutCallback, 1500

		async.parallel [
			(callback) =>
				@LayoutModel.remove {}, (err) ->
					throw err if err
					console.log 'Cleaned layouts'
					callback()
			(callback) =>
				@DocumentModel.remove {}, (err) ->
					throw err if err
					console.log 'Cleaned documents'
					callback()
		],
		->
			clearTimeout timeout
			console.log 'Cleaned files'
			next()
	
	# Parse the files
	generateParse: (next) ->
		LayoutModel = @LayoutModel
		DocumentModel = @DocumentModel

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
					console.log 'Failed to parse the directory:',fullPath
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
					Layout = new LayoutModel()

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
				documentsSrcPath,
				# One Parsed
				(fileMeta,next) ->
					# Prepare
					Document = new DocumentModel()

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
		DocumentModel = @DocumentModel

		# Async
		tasks = new util.Group (err) ->
			console.log 'Generated Relations'
			next err

		# Find documents
		DocumentModel.find {}, (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++tasks.total

				# Find related documents
				DocumentModel.find {tags:{'$in':Document.tags}}, (err,relatedDocuments) ->
					# Check
					if err
						throw err
					else if relatedDocuments.length is 0
						return tasks.complete false
					
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
						tasks.complete false
	
	# Generate render
	generateRender: (next) ->
		LayoutModel = @LayoutModel
		DocumentModel = @DocumentModel

		# Render helper
		_render = (Document,layoutData) ->
			rendered = Document.content
			rendered = eco.render rendered, layoutData
			return rendered
		
		# Render recursive helper
		_renderRecursive = (content,child,layoutData,next) ->
			# Handle parent
			if child.layout
				# Find parent
				LayoutModel.findOne {relativeBase:child.layout}, (err,parent) ->
					# Check
					if err then throw err
					else if not parent then throw new Error 'Could not find the layout: '+child.layout
					
					# Render parent
					layoutData.content = content
					content = _render parent, layoutData

					# Recurse
					_renderRecursive content, parent, layoutData, next
			# Handle loner
			else
				next content
		
		# Render
		render = (Document,layoutData,next) ->
			# Render original
			renderedContent = _render Document, layoutData
			
			# Wrap in parents
			_renderRecursive renderedContent, Document, layoutData, (contentRendered) ->
				Document.contentRendered = contentRendered
				Document.save (err) ->
					throw err if err
					next()
			
		# Async
		tasks = new util.Group (err) -> next err

		# Find documents
		DocumentModel.find({}).sort('date',-1).execFind (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++tasks.total
				render(
					Document,
					{
						Documents: Documents
						DocumentModel: DocumentModel
						Document: Document
					},
					tasks.completer()
				)
	
	# Write files
	generateWriteFiles: (next) ->
		console.log 'Starting write files'
		util.cpdir(
			# Src Path
			@srcPath+'/files',
			# Out Path
			@outPath
			# Next
			(err) ->
				throw err if err
				next()
		)
	
	# Write documents
	generateWriteDocuments: (next) ->
		DocumentModel = @DocumentModel
		outPath = @outPath
		console.log 'Starting write documents'

		# Async
		tasks = new util.Group (err) ->
			console.log 'Rendered Documents'
			next err
		
		# Find documents
		DocumentModel.find {}, (err,Documents) ->
			throw err if err
			Documents.forEach (Document) ->
				++tasks.total

				# Generate path
				fileFullPath = outPath+'/'+Document.relativeBase+'.html'

				# Ensure path
				util.ensurePath path.dirname(fileFullPath), (err) ->
					throw err if err
					# Write document
					fs.writeFile fileFullPath, Document.contentRendered, (err) ->
						throw err if err
						tasks.complete false
	
	# Write
	generateWrite: (next) ->
		console.log 'Starting write'
		async.parallel [
			# Files
			(callback) =>
				@generateWriteFiles (err) ->
					throw err if err
					callback()
			# Documents
			(callback) =>
				@generateWriteDocuments (err) ->
					throw err if err
					callback()
		],
		-> 
			console.log 'Completed write'
			next()
	
	# Generate
	generate: (next) ->
		docpad = @

		# Check
		if @generating
			console.log 'Generate request received, but we are already busy generating...'
			return
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
					throw err
				console.log 'Cleaned the out path'
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
		docpad = @

		# Log
		console.log 'Setting up watching...'
		
		# Watch the src directory
		watch.createMonitor docpad.srcPath, (monitor) ->
			# Log
			console.log 'Set up watching'

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
		docpad = @

		skeleton = (process.argv.length >= 3 and process.argv[2] is 'skeleton' and process.argv[3]) || 'balupton'
		skeletonPath = @skeletonsPath + '/' + skeleton
		toPath = (process.argv.length >= 5 and process.argv[2] is 'skeleton' and process.argv[4]) || @rootPath
		toPath = util.prefixPathSync(toPath,@rootPath)

		path.exists docpad.srcPath, (exists) ->
			if exists
				console.log 'Cannot place skeleton as the desired structure already exists'
				next()
			else
				console.log 'Copying the skeleton ['+skeleton+'] to ['+toPath+']'
				util.cpdir skeletonPath, toPath, (err) ->
					console.log 'done'
					throw err if err
					next()
	
	# Server
	server: (next) ->
		# Server
		@server = express.createServer()

		# Configuration
		@server.configure =>
			# Standard
			@server.use express.methodOverride()
			@server.use express.errorHandler()
			@server.use express.bodyParser()

			# Routing
			@server.use @server.router
			@server.use express.static @outPath
		
		# Route something
		@server.get /^\/docpad/, (req,res) ->
			res.send 'DocPad!'

		# Init server
		@server.listen @port
		console.log 'Express server listening on port %d', @server.address().port

		# Forward
		next()
	
# API
docpad =
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad