# =====================================
# Requires

# Standard Library
util = require('util')
pathUtil = require('path')

# External
isTextOrBinary = require('istextorbinary')
typeChecker = require('typechecker')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
mime = require('mime')
extendr = require('extendr')
{extractOptsAndCallback} = require('extract-opts')

# Optional
jschardet = null
encodingUtil = null

# Local
{Backbone,Model} = require('../base')
docpadUtil = require('../util')


# =====================================
# Classes

class FileModel extends Model

	# ---------------------------------
	# Properties

	# Model Class
	klass: FileModel

	# Model Type
	type: 'file'

	# The out directory path to put the relative path
	rootOutDirPath: null

	# Whether or not we should detect encoding
	detectEncoding: false

	# Stat Object
	stat: null

	# File buffer
	buffer: null

	# Buffer time
	bufferTime: null

	# The parsed file meta data (header)
	# Is a Backbone.Model instance
	meta: null

	# Locale
	locale: null

	# Get Options
	# @TODO: why does this not use the isOption way?
	getOptions: ->
		return {@detectEncoding, @rootOutDirPath, @locale, @stat, @buffer, @meta}

	# Is Option
	isOption: (key) ->
		names = ['detectEncoding', 'rootOutDirPath', 'locale', 'stat', 'data', 'buffer', 'meta']
		result = key in names
		return result

	# Extract Options
	extractOptions: (attrs) ->
		# Prepare
		result = {}

		# Extract
		for own key,value of attrs
			if @isOption(key)
				result[key] = value
				delete attrs[key]

		# Return
		return result

	# Set Options
	setOptions: (attrs={}) ->
		# Root Out Path
		if attrs.detectEncoding?
			@rootOutDirPath = attrs.detectEncoding
			delete @attributes.detectEncoding

		# Root Out Path
		if attrs.rootOutDirPath?
			@rootOutDirPath = attrs.rootOutDirPath
			delete @attributes.rootOutDirPath

		# Locale
		if attrs.locale?
			@locale = attrs.locale
			delete @attributes.locale

		# Stat
		if attrs.stat?
			@setStat(attrs.stat)
			delete @attributes.stat

		# Data
		if attrs.data?
			@setBuffer(attrs.data)
			delete @attributes.data

		# Buffer
		if attrs.buffer?
			@setBuffer(attrs.buffer)
			delete @attributes.buffer

		# Meta
		if attrs.meta?
			@setMeta(attrs.meta)
			delete @attributes.meta

		# Chain
		@

	# Clone
	clone: ->
		# Fetch
		attrs = @getAttributes()
		opts = @getOptions()

		# Clean up
		delete attrs.id
		delete attrs.meta.id
		delete opts.meta.id
		delete opts.meta.attributes.id

		# Clone
		clonedModel = new @klass(attrs, opts)

		# Emit clone event so parent can re-attach listeners
		@emit('clone', clonedModel)

		# Return
		return clonedModel


	# ---------------------------------
	# Attributes

	defaults:

		# ---------------------------------
		# Automaticly set variables

		# The unique document identifier
		id: null

		# The file's name without the extension
		basename: null

		# The out file's name without the extension
		outBasename: null

		# The file's last extension
		# "hello.md.eco" -> "eco"
		extension: null

		# The extension used for our output file
		outExtension: null

		# The file's extensions as an array
		# "hello.md.eco" -> ["md","eco"]
		extensions: null  # Array

		# The file's name with the extension
		filename: null

		# The full path of our source file, only necessary if called by @load
		fullPath: null

		# The full directory path of our source file
		fullDirPath: null

		# The output path of our file
		outPath: null

		# The output path of our file's directory
		outDirPath: null

		# The file's name with the rendered extension
		outFilename: null

		# The relative path of our source file (with extensions)
		relativePath: null

		# The relative output path of our file
		relativeOutPath: null

		# The relative directory path of our source file
		relativeDirPath: null

		# The relative output path of our file's directory
		relativeOutDirPath: null

		# The relative base of our source file (no extension)
		relativeBase: null

		# The relative base of our out file (no extension)
		relativeOutBase: null

		# The MIME content-type for the source file
		contentType: null

		# The MIME content-type for the out file
		outContentType: null

		# The date object for when this document was created
		ctime: null

		# The date object for when this document was last modified
		mtime: null

		# The date object for when this document was last rendered
		rtime: null

		# The date object for when this document was last written
		wtime: null

		# Does the file actually exist on the file system
		exists: null


		# ---------------------------------
		# Content variables

		# The encoding of the file
		encoding: null

		# The raw contents of the file, stored as a String
		source: null

		# The contents of the file, stored as a String
		content: null


		# ---------------------------------
		# User set variables

		# The tags for this document
		tags: null  # CSV/Array

		# Whether or not we should render this file
		render: false

		# Whether or not we should write this file to the output directory
		write: true

		# Whether or not we should write this file to the source directory
		writeSource: false

		# Whether or not this file should be re-rendered on each request
		dynamic: false

		# The title for this document
		# Useful for page headings
		title: null

		# The name for this document, defaults to the outFilename
		# Useful for navigation listings
		name: null

		# The date object for this document, defaults to mtime
		date: null

		# The generated slug (url safe seo title) for this document
		slug: null

		# The url for this document
		url: null

		# Alternative urls for this document
		urls: null  # Array

		# Whether or not we ignore this file
		ignored: false

		# Whether or not we should treat this file as standalone (that nothing depends on it)
		standalone: false



	# ---------------------------------
	# Helpers

	# Encode
	# opts = {path, to, from, content}
	encode: (opts) ->
		# Prepare
		locale = @locale
		result = opts.content
		opts.to ?= 'utf8'
		opts.from ?= 'utf8'

		# Import optional dependencies
		try encodingUtil ?= require('encoding')

		# Convert
		if encodingUtil?
			@log 'info', util.format(locale.fileEncode, opts.to, opts.from, opts.path)
			try
				result = encodingUtil.convert(opts.content, opts.to, opts.from)
			catch err
				@log 'warn', util.format(locale.fileEncodeConvertError, opts.to, opts.from, opts.path)
		else
			@log 'warn', util.format(locale.fileEncodeConvertError, opts.to, opts.from, opts.path)

		# Return
		return result

	# Set Buffer
	setBuffer: (buffer) ->
		buffer = new Buffer(buffer)  unless Buffer.isBuffer(buffer)
		@bufferTime = @get('mtime') or new Date()
		@buffer = buffer
		@

	# Get Buffer
	getBuffer: ->
		return @buffer

	# Is Buffer Outdated
	# True if there is no buffer OR the buffer time is outdated
	isBufferOutdated: ->
		return @buffer? is false or @bufferTime < (@get('mtime') or new Date())

	# Set Stat
	setStat: (stat) ->
		@stat = stat
		@set(
			ctime: new Date(stat.ctime)
			mtime: new Date(stat.mtime)
		)
		@

	# Get Stat
	getStat: ->
		return @stat

	# Get Attributes
	getAttributes: (dereference=true) ->
		attrs = @toJSON(dereference)
		delete attrs.id
		return attrs

	# To JSON
	toJSON: (dereference=false) ->
		data = super
		data.meta = @getMeta().toJSON()
		data = extendr.dereference(data)  if dereference is true
		return data

	# Get Meta
	getMeta: (args...) ->
		@meta = new Model()  if @meta is null
		if args.length
			return @meta.get(args...)
		else
			return @meta

	# Set
	set: (attrs,opts) ->
		# Check
		if typeChecker.isString(attrs)
			newAttrs = {}
			newAttrs[attrs] = opts
			return @set(newAttrs, opts)

		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Extract options
		options = @extractOptions(attrs)

		# Perform the set
		super(attrs, opts)

		# Apply the options
		@setOptions(options, opts)

		# Chain
		@

	# Set Defaults
	setDefaults: (attrs,opts) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Extract options
		options = @extractOptions(attrs)

		# Apply
		super(attrs, opts)

		# Apply the options
		@setOptions(options, opts)

		# Chain
		return @

	# Set Meta
	setMeta: (attrs,opts) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Extract options
		options = @extractOptions(attrs)

		# Apply
		@getMeta().set(attrs, opts)
		@set(attrs, opts)

		# Apply the options
		@setOptions(options, opts)

		# Chain
		return @

	# Set Meta Defaults
	setMetaDefaults: (attrs,opts) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Extract options
		options = @extractOptions(attrs)

		# Apply
		@getMeta().setDefaults(attrs, opts)
		@setDefaults(attrs, opts)

		# Apply the options
		@setOptions(options, opts)

		# Chain
		return @

	# Get Filename
	getFilename: (opts={}) ->
		# Prepare
		{fullPath,relativePath,filename} = opts

		# Determine
		result = (filename ? @get('filename'))
		if !result
			result = (fullPath ? @get('fullPath')) or (relativePath ? @get('relativePath'))
			result = pathUtil.basename(result)  if result
		result or= null

		# REturn
		return result

	# Get File Path
	getFilePath: (opts={}) ->
		# Prepare
		{fullPath,relativePath,filename} = opts

		# Determine
		result = (fullPath ? @get('fullPath')) or (relativePath ? @get('relativePath')) or (filename ? @get('filename')) or null

		# Return
		return result

	# Get Extensions
	getExtensions: ({extensions,filename}) ->
		extensions or= @get('extensions') or null
		if (extensions or []).length is 0
			filename = @getFilename({filename})
			if filename
				extensions = docpadUtil.getExtensions(filename)
		return extensions or null

	# Get Content
	getContent: ->
		return @get('content') or @getBuffer()

	# Get Out Content
	getOutContent: ->
		return @getContent()

	# Is Text?
	isText: ->
		return @get('encoding') isnt 'binary'

	# Is Binary?
	isBinary: ->
		return @get('encoding') is 'binary'

	# Set the url for the file
	setUrl: (url) ->
		@addUrl(url)
		@set({url})
		@

	# Add a url
	# Allows our file to support multiple urls
	addUrl: (url) ->
		# Multiple Urls
		if url instanceof Array
			for newUrl in url
				@addUrl(newUrl)

		# Single Url
		else if url
			found = false
			urls = @get('urls')
			for existingUrl in urls
				if existingUrl is url
					found = true
					break
			urls.push(url)  if not found
			@trigger('change:urls', @, urls, {})
			@trigger('change', @, {})

		# Chain
		@

	# Remove a url
	# Removes a url from our file
	removeUrl: (userUrl) ->
		urls = @get('urls')
		for url,index in urls
			if url is userUrl
				urls.splice(index,1)
				break
		@

	# Get a Path
	# If the path starts with `.` then we get the path in relation to the document that is calling it
	# Otherwise we just return it as normal
	getPath: (relativePath, parentPath) ->
		if /^\./.test(relativePath)
			relativeDirPath = @get('relativeDirPath')
			path = pathUtil.join(relativeDirPath, relativePath)
		else
			if parentPath
				path = pathUtil.join(parentPath, relativePath)
			else
				path = relativePath
		return path


	# ---------------------------------
	# Actions

	# The action runner instance bound to docpad
	actionRunnerInstance: null
	getActionRunner: -> @actionRunnerInstance
	action: (args...) => docpadUtil.action.apply(@, args)

	# Initialize
	initialize: (attrs,opts={}) ->
		# Defaults
		file = @
		@attributes ?= {}
		@attributes.extensions ?= []
		@attributes.urls ?= []
		now = new Date()
		@attributes.ctime ?= now
		@attributes.mtime ?= now

		# Id
		@id ?= @attributes.id ?= @cid

		# Options
		@setOptions(opts)

		# Error
		if @rootOutDirPath? is false or @locale? is false
			throw new Error("Use docpad.createModel to create the file or document model")

		# Create our action runner
		@actionRunnerInstance = new TaskGroup("file action runner").whenDone (err) ->
			file.emit('error', err)  if err

		# Apply
		@emit('init')

		# Chain
		@

	# Load
	# If the fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		file = @
		opts.exists ?= null

		# Fetch
		fullPath = @get('fullPath')
		filePath = @getFilePath({fullPath})

		# Apply options
		file.set(exists: opts.exists)  if opts.exists?
		file.setStat(opts.stat)        if opts.stat?
		file.setBuffer(opts.buffer)    if opts.buffer?

		# Tasks
		tasks = new TaskGroup("load tasks for file: #{filePath}", {next})
			.on('item.run', (item) ->
				file.log("debug", "#{item.getConfig().name}: #{file.type}: #{filePath}")
			)

		# Detect the file
		tasks.addTask "Detect the file", (complete) ->
			if fullPath and opts.exists is null
				safefs.exists fullPath, (exists) ->
					opts.exists = exists
					file.set(exists: opts.exists)
					return complete()
			else
				return complete()

		tasks.addTask "Stat the file and cache the result", (complete) ->
			# Otherwise fetch new stat
			if fullPath and opts.exists and opts.stat? is false
				return safefs.stat fullPath, (err,fileStat) ->
					return complete(err)  if err
					file.setStat(fileStat)
					return complete()
			else
				return complete()

		# Process the file
		tasks.addTask "Read the file and cache the result", (complete) ->
			# Otherwise fetch new buffer
			if fullPath and opts.exists and opts.buffer? is false and file.isBufferOutdated()
				return safefs.readFile fullPath, (err,buffer) ->
					return complete(err)  if err
					file.setBuffer(buffer)
					return complete()
			else
				return complete()

		tasks.addTask "Load -> Parse", (complete) ->
			file.parse(complete)

		tasks.addTask "Parse -> Normalize", (complete) ->
			file.normalize(complete)

		tasks.addTask "Normalize -> Contextualize", (complete) ->
			file.contextualize(complete)

		# Run the tasks
		tasks.run()

		# Chain
		@

	# Parse
	# Parse our buffer and extract meaningful data from it
	# next(err)
	parse: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		buffer = @getBuffer()
		relativePath = @get('relativePath')
		encoding = opts.encoding or @get('encoding') or null
		changes = {}

		# Detect Encoding
		if buffer and encoding? is false or opts.reencode is true
			isText = isTextOrBinary.isTextSync(relativePath, buffer)

			# Text
			if isText is true
				# Detect source encoding if not manually specified
				if @detectEncoding
					jschardet ?= require('jschardet')
					encoding ?= jschardet.detect(buffer)?.encoding

				# Default the encoding
				encoding or= 'utf8'

				# Convert into utf8
				if docpadUtil.isStandardEncoding(encoding) is false
					buffer = @encode({
						path: relativePath
						to: 'utf8'
						from: encoding
						content: buffer
					})

				# Apply
				changes.encoding = encoding

			# Binary
			else
				# Set
				encoding = changes.encoding = 'binary'

		# Binary
		if encoding is 'binary'
			# Set
			content = source = ''

			# Apply
			changes.content = content
			changes.source = source

		# Text
		else
			# Default
			encoding = changes.encoding = 'utf8'  if encoding? is false

			# Set
			source = buffer?.toString('utf8') or ''
			content = source

			# Apply
			changes.content = content
			changes.source = source

		# Apply
		@set(changes)

		# Next
		next()
		@

	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		changes = {}
		meta = @getMeta()
		locale = @locale

		# App specified
		filename = opts.filename or @get('filename') or null
		relativePath = opts.relativePath or @get('relativePath') or null
		fullPath = opts.fullPath or @get('fullPath') or null
		mtime = opts.mtime or @get('mtime') or null

		# User specified
		tags = opts.tags or meta.get('tags') or null
		date = opts.date or meta.get('date') or null
		name = opts.name or meta.get('name') or null
		slug = opts.slug or meta.get('slug') or null
		url = opts.url or meta.get('url') or null
		contentType = opts.contentType or meta.get('contentType') or null
		outContentType = opts.outContentType or meta.get('outContentType') or null
		outFilename = opts.outFilename or meta.get('outFilename') or null
		outExtension = opts.outExtension or meta.get('outExtension') or null
		outPath = opts.outPath or meta.get('outPath') or null

		# Force specifeid
		extensions = null
		extension = null
		basename = null
		outBasename = null
		relativeOutPath = null
		relativeDirPath = null
		relativeOutDirPath = null
		relativeBase = null
		relativeOutBase = null
		outDirPath = null
		fullDirPath = null

		# filename
		changes.filename = filename = @getFilename({filename, relativePath, fullPath})

		# check
		if !filename
			err = new Error(locale.filenameMissingError)
			return next(err)

		# relativePath
		if !relativePath and filename
			changes.relativePath = relativePath = filename

		# force basename
		changes.basename = basename = docpadUtil.getBasename(filename)

		# force extensions
		changes.extensions = extensions = @getExtensions({filename})

		# force extension
		changes.extension = extension = docpadUtil.getExtension(extensions)

		# force fullDirPath
		if fullPath
			changes.fullDirPath = fullDirPath = docpadUtil.getDirPath(fullPath)

		# force relativeDirPath
		changes.relativeDirPath = relativeDirPath = docpadUtil.getDirPath(relativePath)

		# force relativeBase
		changes.relativeBase = relativeBase =
			if relativeDirPath
				pathUtil.join(relativeDirPath, basename)
			else
				basename

		# force contentType
		if !contentType
			changes.contentType = contentType = mime.lookup(fullPath or relativePath)

		# adjust tags
		if tags and typeChecker.isArray(tags) is false
			changes.tags = tags = String(tags).split(/[\s,]+/)

		# force date
		if !date
			changes.date = date = mtime or @get('date') or new Date()

		# force outFilename
		if !outFilename and !outPath
			changes.outFilename = outFilename = docpadUtil.getOutFilename(basename, outExtension or extensions.join('.'))

		# force outPath
		if !outPath
			changes.outPath = outPath =
				if @rootOutDirPath
					pathUtil.resolve(@rootOutDirPath, relativeDirPath, outFilename)
				else
					null
			# ^ we still do this set as outPath is a meta, and it may still be set as an attribute

		# refresh outFilename
		if outPath
			changes.outFilename = outFilename = docpadUtil.getFilename(outPath)

		# force outDirPath
		changes.outDirPath = outDirPath =
			if outPath
				docpadUtil.getDirPath(outPath)
			else
				null

		# force outBasename
		changes.outBasename = outBasename = docpadUtil.getBasename(outFilename)

		# force outExtension
		changes.outExtension = outExtension = docpadUtil.getExtension(outFilename)

		# force relativeOutPath
		changes.relativeOutPath = relativeOutPath =
			if outPath
				outPath.replace(@rootOutDirPath, '').replace(/^[\/\\]/, '')
			else
				pathUtil.join(relativeDirPath, outFilename)

		# force relativeOutDirPath
		changes.relativeOutDirPath = relativeOutDirPath = docpadUtil.getDirPath(relativeOutPath)

		# force relativeOutBase
		changes.relativeOutBase = relativeOutBase = pathUtil.join(relativeOutDirPath, outBasename)

		# force name
		if !name
			changes.name = name = outFilename

		# force url
		_defaultUrl = docpadUtil.getUrl(relativeOutPath)
		if url
			@setUrl(url)
			@addUrl(_defaultUrl)
		else
			@setUrl(_defaultUrl)

		# force outContentType
		if !outContentType and contentType
			changes.outContentType = outContentType = mime.lookup(outPath or relativeOutPath) or contentType

		# force slug
		if !slug
			changes.slug = slug = docpadUtil.getSlug(relativeOutBase)

		# Force date objects
		changes.wtime = wtime = new Date(wtime)  if typeof wtime is 'string'
		changes.rtime = rtime = new Date(rtime)  if typeof rtime is 'string'
		changes.ctime = ctime = new Date(ctime)  if typeof ctime is 'string'
		changes.mtime = mtime = new Date(mtime)  if typeof mtime is 'string'
		changes.date  = date  = new Date(date)   if typeof date is 'string'

		# Apply
		@set(changes)

		# Next
		next()
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Forward
		next()
		@


	# Render
	# Render this file
	# next(err,result,document)
	render: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Apply
		file.attributes.rtime = new Date()

		# Forward
		next(null, file.getOutContent(), file)
		@


	# ---------------------------------
	# CRUD

	# Write the out file
	# next(err)
	write: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		locale = @locale

		# Fetch
		opts.path      or= file.get('outPath')
		opts.encoding  or= file.get('encoding') or 'utf8'
		opts.content   or= file.getOutContent()
		opts.type      or= 'out file'

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless opts.path
			next()
			return @

		# Convert utf8 to original encoding
		unless opts.encoding.toLowerCase() in ['ascii','utf8','utf-8','binary']
			opts.content = @encode({
				path: opts.path
				to: opts.encoding
				from: 'utf8'
				content: opts.content
			})

		# Log
		file.log 'debug', util.format(locale.fileWrite, opts.type, opts.path, opts.encoding)

		# Write data
		safefs.writeFile opts.path, opts.content, (err) ->
			# Check
			return next(err)  if err

			# Update the wtime
			if opts.type is 'out file'
				file.attributes.wtime = new Date()

			# Log
			file.log 'debug',  util.format(locale.fileWrote, opts.type, opts.path, opts.encoding)

			# Next
			return next()

		# Chain
		@

	# Write the source file
	# next(err)
	writeSource: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Fetch
		opts.path      or= file.get('fullPath')
		opts.content   or= (file.getContent() or '').toString('')
		opts.type      or= 'source file'

		# Write data
		@write(opts, next)

		# Chain
		@

	# Delete the out file
	# next(err)
	'delete': (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		locale = @locale

		# Fetch
		opts.path      or= file.get('outPath')
		opts.type      or= 'out file'

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless opts.path
			next()
			return @

		# Log
		file.log 'debug',  util.format(locale.fileDelete, opts.type, opts.path)

		# Check existance
		safefs.exists opts.path, (exists) ->
			# Exit if it doesn't exist
			return next()  unless exists

			# If it does exist delete it
			safefs.unlink opts.path, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'debug', util.format(locale.fileDeleted, opts.type, opts.path)

				# Next
				next()

		# Chain
		@

	# Delete the source file
	# next(err)
	deleteSource: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Fetch
		opts.path      or= file.get('fullPath')
		opts.type      or= 'source file'

		# Write data
		@delete(opts, next)

		# Chain
		@


# ---------------------------------
# Export
module.exports = FileModel
