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
async = false
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
			next() if next
		@cleanModels()

	# Handle
	action: (action) ->
		switch action
			when 'skeleton'
				@skeletonAction -> 
					process.exit()
			
			when 'generate'
				@generateAction -> 
					process.exit()
			
			when 'watch'
				@watchAction ->
					console.log 'DocPad is now watching you...'
			
			when 'server'
				@serverAction ->
					console.log 'DocPad is now servering you...'
			
			else
				@skeletonAction => @generateAction => @serverAction => @watchAction =>
					console.log 'DocPad is is now watching and serving you...'
	
	# Clean the database
	generateClean: (next) ->
		# Requires
		async = require 'async'		unless async
		
		# Prepare
		console.log 'Cleaning files'

		# Timeout
		timeoutCallback = ->
			throw new Error 'Could not connect to the mongod'	
		timeout = setTimeout timeoutCallback, 1500

		# Handle
		async.parallel [
			(callback) =>
				@Layouts.remove {}, (err) ->
					throw err if err
					console.log 'Cleaned layouts'
					callback()
			(callback) =>
				@Documents.remove {}, (err) ->
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
		# Requires
		yaml = require 'yaml'							unless yaml
		gfm = require 'github-flavored-markdown'		unless gfm
		jade = require 'jade'							unless jade
		async = require 'async'		unless async
		
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
		parseFiles = (fullPath,callback,next) ->
			util.scandir(
				# Path
				fullPath,
				# File Action
				(fileFullPath,fileRelativePath,next) ->
                                         #Ignore hidden files in SRC directory (such as .DS_Store on Mac)
					if path.basename(fileFullPath).startsWith('.')
						console.log 'Skipping Hidden File:',fileFullPath
						return next()
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
					layout = new Layout()

					# Apply
					for own key, fileMetaValue of fileMeta
						layout[key] = fileMetaValue
					
					# Save
					layout.save()
					console.log 'Parsed Layout:', layout.relativeBase
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
					document = new Document()

					# Apply
					for own key, fileMetaValue of fileMeta
						document[key] = fileMetaValue
					
					# Save
					document.save()
					console.log 'Parsed Document:', document.relativeBase
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
			throw err if err
			tasks.total += length
			documents.forEach (document) ->
				# Find related documents
				Documents.find {tags:{'$in':document.tags}}, (err,relatedDocuments) ->
					# Check
					if err
						throw err
					else if relatedDocuments.length is 0
						return tasks.complete false

					# Fetch
					relatedDocumentsArray = []
					relatedDocuments.sort (a,b) ->
						return a.tags.hasCount(document.tags) < b.tags.hasCount(document.tags)
					.forEach (relatedDocument) ->
						if document.url is relatedDocument.url then return
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
		Documents = @Documents
		outPath = @outPath
		console.log 'Starting write documents'

		# Async
		tasks = new util.Group (err) ->
			console.log 'Rendered Documents'
			next err
		
		# Find documents
		Documents.find {}, (err,documents,length) ->
			throw err if err
			tasks.total += length
			documents.forEach (document) ->
				# Generate path
				fileFullPath = outPath+'/'+document.url #relativeBase+'.html'

				# Ensure path
				util.ensurePath path.dirname(fileFullPath), (err) ->
					throw err if err
					# Write document
					fs.writeFile fileFullPath, document.contentRendered, (err) ->
						throw err if err
						tasks.complete false

	# Write
	generateWrite: (next) ->
		# Requires
		async = require 'async'		unless async
		
		# Handle
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
									docpad.cleanModels()
									docpad.generating = false
									next()
	
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
				next()
			else
				console.log 'Copying the skeleton ['+skeleton+'] to ['+toPath+']'
				util.cpdir skeletonPath, toPath, (err) ->
					console.log 'done'
					throw err if err
					next()
	
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
					next()
		
		# Start server listening
		if listen
			@server.listen @port
			console.log 'Express server listening on port %d and directory %s', @server.address().port, @outPath

		# Forward
		next()
	
# API
docpad =
	createInstance: (config) ->
		return new Docpad(config)

# Export
module.exports = docpad