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
encodingUtil = null
#Iconv = null

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
		return {@detectEncoding, @rootOutDirPath, @stat, @buffer, @meta}

	# Is Option
	isOption: (key) ->
		names = ['detectEncoding', 'rootOutDirPath', 'stat', 'data', 'buffer', 'meta']
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

		# Clone
		instance = new @klass(attrs, opts)

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
		relativeOutBase: null

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

		# The tags for this document
		tags: null  # CSV/Array

		# Whether or not we should render this file
		render: false

		# Whether or not we should write this file to the output directory
		write: true

		# Whether or not we should write this file to the source directory
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

		# Whether or not we ignore this file
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
	getAttributes: (dereference=true) ->
		attrs = @toJSON(dereference)
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

	# Initialize
	initialize: (attrs,opts) ->
		# Defaults
		@attributes ?= {}
		@attributes.extensions ?= []
		@attributes.urls ?= []
		now = new Date()
		@attributes.ctime = now
		@attributes.mtime = now

		# Id
		@id ?= @attributes.id ?= @cid

		# Options
		@setOptions(opts)

		# Super
		super

		# Chain
		@

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
		filePath = @getFilePath({fullPath})

		# If stat is set, use that
		if opts.stat
			file.setStat(opts.stat)

		# If buffer is set, use that
		if opts.buffer
			file.setBuffer(opts.buffer)

		# Async
		file.log('debug', "Load #{@type}: #{filePath}")
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
					jschardet ?= require('jschardet')
					encoding ?= jschardet.detect(buffer)?.encoding

				# Default the encoding
				encoding or= 'utf8'

				# Convert into utf8
				if docpadUtil.isStandardEncoding(encoding) is false
					# Import optional dependencies
					try
						#Iconv ?= require('iconv').Iconv
						encodingUtil ?= require('encoding')
						# ^ when we prove encoding/iconv-lite works better than iconv
						# we can move this out of the try catch and make detectEncoding standard
					catch err
						# ignore

					# Can convert?
					if encodingUtil?
						@log('info', "Converting encoding #{encoding} to UTF-8 on #{relativePath}")

						# Convert
						d = require('domain').create()
						d.on 'error', =>
							@log('warn', "Encoding conversion failed, therefore we cannot convert the encoding #{encoding} to UTF-8 on #{relativePath}")
						d.run ->
							#buffer = new Iconv(encoding, 'utf8').convert(buffer)
							buffer = encodingUtil.convert(buffer, 'utf8', encoding)  # content, to, from

					# Can't convert
					else
						@log('warn', "Encoding utilities did not load, therefore we cannot convert the encoding #{encoding} to UTF-8 on #{relativePath}")

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

	# Write the out file
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
			# Import optional dependencies
			try
				#Iconv ?= require('iconv').Iconv
				encodingUtil ?= require('encoding')
			catch err
				# ignore

			# Convert
			if encodingUtil?
				@log('info', "Converting encoding UTF-8 to #{opts.encoding} on #{opts.path}")
				try
					#opts.content = new Iconv('utf8',opts.encoding).convert(opts.content)
					opts.content = encodingUtil.convert(opts.content, opts.encoding, 'utf8')  # content, to, from
				catch err
					@log('warn', "Encoding conversion failed, therefore we cannot convert the encoding UTF-8 to #{opts.encoding} on #{opts.path}")
			else
				@log('warn', "Encoding utilities did not load, therefore we cannot convert the encoding UTF-8 to #{opts.encoding} on #{opts.path}")

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

	# Write the source file
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

	# Delete the out file
	# next(err)
	'delete': (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @

		# Fetch
		opts.path      or= @get('outPath')
		opts.type      or= 'out file'

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless opts.path
			next()
			return @

		# Log
		file.log 'debug', "Delete the #{opts.type}: #{opts.path}"

		# Check existance
		safefs.exists opts.path, (exists) ->
			# Exit if it doesn't exist
			return next()  unless exists

			# If it does exist delete it
			safefs.unlink opts.path, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'debug', "Deleted the #{opts.type}: #{opts.path}"

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
		opts.path      or= @get('fullPath')
		opts.type      or= 'source file'

		# Write data
		@delete(opts, next)

		# Chain
		@

# Export
module.exports = FileModel
