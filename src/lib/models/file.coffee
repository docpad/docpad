# Import
pathUtil = require('path')
balUtil = require('bal-util')
typeChecker = require('typechecker')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
mime = require('mime')
extendr = require('extendr')
{extractOptsAndCallback} = require('extract-opts')

# Import: Optional
jschardet = null
Iconv = null

# Local
{Backbone,Model} = require('../base')
docpadUtil = require('../util')


# ---------------------------------
# File Model

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

	# The parsed file meta data (header)
	# Is a Backbone.Model instance
	meta: null

	# Get Options
	getOptions: ->
		return {@rootOutDirPath, @detectEncoding, @stat, @buffer, @meta}

	# Set Options
	setOptions: (opts={}) ->
		# Root Out Path
		if opts.detectEncoding?
			@rootOutDirPath = opts.detectEncoding
			delete opts.detectEncoding
			delete @attributes.detectEncoding

		# Root Out Path
		if opts.rootOutDirPath?
			@rootOutDirPath = opts.rootOutDirPath
			delete opts.rootOutDirPath
			delete @attributes.rootOutDirPath

		# Stat
		if opts.stat?
			@setStat(opts.stat)
			delete opts.stat
			delete @attributes.stat

		# Data
		if opts.data?
			@setBuffer(opts.data)
			delete opts.data
			delete @attributes.data

		# Buffer
		if opts.buffer?
			@setBuffer(opts.buffer)
			delete opts.buffer
			delete @attributes.buffer

		# Meta
		if opts.meta?
			@setMeta(opts.meta)
			delete opts.meta
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

		# Clone
		instance = new @klass(attrs, opts)
		instance._events = extendr.deepExtend(@_events)

		# Return
		return instance


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
		releativeOutBase: null

		# The MIME content-type for the source file
		contentType: null

		# The MIME content-type for the out file
		outContentType: null

		# The date object for when this document was created
		ctime: null

		# The date object for when this document was last modified
		mtime: null

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

		# Write this file to the output directory
		write: true

		# Write this file to the source directory
		writeSource: false

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

		# Whether or not we ignore this document (do not render it)
		ignored: false

		# Whether or not we should treat this file as standalone (that nothing depends on it)
		standalone: false



	# ---------------------------------
	# Helpers

	# Set Buffer
	setBuffer: (buffer) ->
		buffer = new Buffer(buffer)  unless Buffer.isBuffer(buffer)
		@buffer = buffer
		@

	# Get Buffer
	getBuffer: ->
		return @buffer

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
	getAttributes: ->
		attrs = @toJSON()
		attrs = extendr.dereference(attrs)
		return attrs

	# To JSON
	toJSON: ->
		data = super
		data.meta = @getMeta().toJSON()
		return data

	# Get Meta
	getMeta: (args...) ->
		@meta = new Model()  if @meta is null
		if args.length
			return @meta.get(args...)
		else
			return @meta

	# Set
	set: (attrs={},opts={}) ->
		# Check
		if typeChecker.isString(attrs)
			newAttrs = {}
			newAttrs[attrs] = opts
			return @set(newAttrs, opts)

		# Prepare
		@setOptions(attrs)

		# Super
		return super(attrs, opts)

	# Set Meta
	setMeta: (attrs) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Apply
		@setOptions(attrs)
		@getMeta().set(attrs)
		@set(attrs)

		# Chain
		return @

	# Set Meta Defaults
	setMetaDefaults: (attrs) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs

		# Apply
		@setOptions(attrs)
		@getMeta().setDefaults(attrs)
		@setDefaults(attrs)

		# Chain
		return @

	# Set Defaults
	setDefaults: (attrs) ->
		# Prepare
		attrs = attrs.toJSON?() ? attrs
		@setOptions(attrs)

		# Forward
		return super

	# Get Filename
	getFilename: ({filename,fullPath,relativePath}) ->
		filename or= @get('filename')
		if !filename
			filePath = @get('fullPath') or @get('relativePath')
			if filePath
				filename = pathUtil.basename(filePath)
		return filename or null

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

	# Initialize
	initialize: (attrs={},opts={}) ->
		# Other options
		@setOptions(opts)

		# Defaults
		# Apply directly as attributes have already been set
		now = new Date()
		@attributes.extensions ?= []
		@attributes.urls ?= []
		@attributes.ctime ?= now
		@attributes.mtime ?= now
		@id ?= @attributes.id ?= @cid

		# Super
		return super(attrs, opts)

	# Load
	# If the fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		file = @
		exists = opts.exists ? false

		# Fetch
		fullPath = @get('fullPath')
		filePath = fullPath or @get('relativePath') or @get('filename')

		# If stat is set, use that
		if opts.stat
			file.setStat(opts.stat)

		# If buffer is set, use that
		if opts.buffer
			file.setBuffer(opts.buffer)

		# Async
		file.log('debug', "Load: #{filePath}")
		tasks = new TaskGroup().setConfig(concurrency:0).once 'complete', (err) =>
			return next(err)  if err
			file.log('debug', "Load -> Parse: #{filePath}")
			file.parse (err) ->
				file.log('debug', "Parse -> Normalize: #{filePath}")
				return next(err)  if err
				file.normalize (err) ->
					file.log('debug', "Normalize -> Done: #{filePath}")
					return next(err)  if err
					return next()

		# Stat the file and cache the result
		tasks.addTask (complete) ->
			# Otherwise fetch new stat
			if fullPath and exists and opts.stat? is false
				return safefs.stat fullPath, (err,fileStat) ->
					return complete(err)  if err
					file.setStat(fileStat)
					return complete()
			else
				return complete()

		# Read the file and cache the result
		tasks.addTask (complete) ->
			# Otherwise fetch new buffer
			if fullPath and exists and opts.buffer? is false
				return safefs.readFile fullPath, (err,buffer) ->
					return complete(err)  if err
					file.setBuffer(buffer)
					return complete()
			else
				return complete()

		# Run the tasks
		if fullPath
			safefs.exists fullPath, (_exists) ->
				exists = _exists
				file.set({exists})
				tasks.run()
		else
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
			isText = balUtil.isTextSync(relativePath, buffer)

			# Text
			if isText is true
				# Detect source encoding if not manually specified
				if @detectEncoding
					# Import
					jschardet ?= require('jschardet')
					try
						Iconv ?= require('iconv').Iconv
					catch err
						Iconv = null

					# Detect
					encoding ?= jschardet.detect(buffer)?.encoding or 'utf8'
				else
					encoding ?= 'utf8'

				# Convert into utf8
				if encoding.toLowerCase() not in ['ascii','utf8','utf-8']
					# Can convert?
					if Iconv?
						@log('info', "Converting encoding #{encoding} to UTF-8 on #{relativePath}")

						# Convert
						d = require('domain').create()
						d.on 'error', =>
							@log('warn', "Encoding conversion failed, therefore we cannot convert the encoding #{encoding} to UTF-8 on #{relativePath}")
						d.run ->
							buffer = new Iconv(encoding, 'utf8').convert(buffer)

					# Can't convert
					else
						@log('warn', "Iconv did not load, therefore we cannot convert the encoding #{encoding} to UTF-8 on #{relativePath}")

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
			err = new Error('filename is required, it can be specified via filename, fullPath, or relativePath')
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
			changes.outPath = outPath = pathUtil.resolve(@rootOutDirPath, relativeDirPath, outFilename)

		# force outDirPath
		changes.outDirPath = outDirPath = docpadUtil.getDirPath(outPath)

		# force outFilename
		changes.outFilename = outFilename = docpadUtil.getFilename(outPath)

		# force outBasename
		changes.outBasename = outBasename = docpadUtil.getBasename(outFilename)

		# force outExtension
		changes.outExtension = outExtension = docpadUtil.getExtension(outFilename)

		# force relativeOutPath
		changes.relativeOutPath = relativeOutPath = outPath.replace(@rootOutDirPath, '').replace(/^[\/\\]/, '')

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


	# ---------------------------------
	# CRUD

	# Write the rendered file
	# next(err)
	write: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Fetch
		opts.path      or= @get('outPath')
		opts.encoding  or= @get('encoding') or 'utf8'
		opts.content   or= @getOutContent()
		opts.type      or= 'out file'

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless opts.path
			next()
			return @

		# Convert utf8 to original encoding
		unless opts.encoding.toLowerCase() in ['ascii','utf8','utf-8','binary']
			if Iconv?
				@log('info', "Converting encoding UTF-8 to #{opts.encoding} on #{opts.path}")
				try
					opts.content = new Iconv('utf8',opts.encoding).convert(opts.content)
				catch err
					@log('warn', "Encoding conversion failed, therefore we cannot convert the encoding UTF-8 to #{opts.encoding} on #{opts.path}")
			else
				@log('warn', "Iconv did not load, therefore we cannot convert the encoding UTF-8 to #{opts.encoding} on #{opts.path}")

		# Log
		file.log 'debug', "Writing the #{opts.type}: #{opts.path} #{opts.encoding}"

		# Write data
		safefs.writeFile opts.path, opts.content, (err) ->
			# Check
			return next(err)  if err

			# Log
			file.log 'debug', "Wrote the #{opts.type}: #{opts.path} #{opts.encoding}"

			# Next
			return next()

		# Chain
		@

	# Write the file
	# next(err)
	writeSource: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Fetch
		opts.path      or= @get('fullPath')
		opts.content   or= (@getContent() or '').toString('')
		opts.type      or= 'source file'

		# Write data
		@write(opts, next)

		# Chain
		@

	# Delete the file
	# next(err)
	delete: (next) ->
		# Prepare
		file = @
		fileOutPath = @get('outPath')

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless fileOutPath
			next()
			return @

		# Log
		file.log 'debug', "Delete the file: #{fileOutPath}"

		# Check existance
		safefs.exists fileOutPath, (exists) ->
			# Exit if it doesn't exist
			return next()  unless exists
			# If it does exist delete it
			safefs.unlink fileOutPath, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'debug', "Deleted the file: #{fileOutPath}"

				# Next
				next()

		# Chain
		@

# Export
module.exports = FileModel
