# =====================================
# Requires

# Standard Library
util = require('util')
pathUtil = require('path')

# External
isTextOrBinary = require('istextorbinary')
typeChecker = require('typechecker')
safefs = require('safefs')
mime = require('mime')
extendr = require('extendr')
extractOptsAndCallback = require('extract-opts')

# Optional
jschardet = null
encodingUtil = null

# Local
{Model} = require('../base')
docpadUtil = require('../util')


# =====================================
# Classes

###*
# The FileModel class is DocPad's representation
# of a file in the file system.
# Extends the DocPad Model class
# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee#L49.
# FileModel manages the loading
# of a file and parsing both the content and the metadata (if any).
# Once loaded, the content, metadata and file stat (file info)
# properties of the FileModel are populated, as well
# as a number of DocPad specific attributes and properties.
# Typically we do not need to create FileModels ourselves as
# DocPad handles all of that. But it is possible that a plugin
# may need to manually create FileModels for some reason.
#
#	attrs =
#		fullPath: 'file/path/to/somewhere'
#	opts = {}
#	#we only really need the path to the source file to create
#	#a new file model
#	model = new FileModel(attrs, opts)
#
# The FileModel forms the base class for the DocPad DocumentModel class.
# @class FileModel
# @constructor
# @extends Model
###
class FileModel extends Model

	# ---------------------------------
	# Properties

	###*
	# The file model class. This should
	# be overridden in any descending classes.
	# @private
	# @property {Object} klass
	###
	klass: FileModel

	###*
	# String name of the model type.
	# In this case, 'file'. This should
	# be overridden in any descending classes.
	# @private
	# @property {String} type
	###
	type: 'file'

	###*
	# Task Group Class
	# @private
	# @property {Object} TaskGroup
	###
	TaskGroup: null

	###*
	# The out directory path to put the relative path.
	# @property {String} rootOutDirPath
	###
	rootOutDirPath: null

	###*
	# Whether or not we should detect encoding
	# @property {Boolean} detectEncoding
	###
	detectEncoding: false

	###*
	# Node.js file stat object.
	# https://nodejs.org/api/fs.html#fs_class_fs_stats.
	# Basically, information about a file, including file
	# dates and size.
	# @property {Object} stat
	###
	stat: null

	###*
	# File buffer. Node.js Buffer object.
	# https://nodejs.org/api/buffer.html#buffer_class_buffer.
	# Provides methods for dealing with binary data directly.
	# @property {Object} buffer
	###
	buffer: null

	###*
	# Buffer time.
	# @property {Object} bufferTime
	###
	bufferTime: null

	###*
	# The parsed file meta data (header).
	# Is a Model instance.
	# @private
	# @property {Object} meta
	###
	meta: null

	###*
	# Locale information for the file
	# @private
	# @property {Object} locale
	###
	locale: null
	###*
	# Get the file's locale information
	# @method getLocale
	# @return {Object} the locale
	###
	getLocale: -> @locale

	###*
	# Get Options. Returns an object containing
	# the properties detectEncoding, rootOutDirPath
	# locale, stat, buffer, meta and TaskGroup.
	# @private
	# @method getOptions
	# @return {Object}
	###
	# @TODO: why does this not use the isOption way?
	getOptions: ->
		return {@detectEncoding, @rootOutDirPath, @locale, @stat, @buffer, @meta, @TaskGroup}

	###*
	# Checks whether the passed key is one
	# of the options.
	# @private
	# @method isOption
	# @param {String} key
	# @return {Boolean}
	###
	isOption: (key) ->
		names = ['detectEncoding', 'rootOutDirPath', 'locale', 'stat', 'data', 'buffer', 'meta', 'TaskGroup']
		result = key in names
		return result

	###*
	# Extract Options.
	# @private
	# @method extractOptions
	# @param {Object} attrs
	# @return {Object} the options object
	###
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

	###*
	# Set the options for the file model.
	# Valid properties for the attrs parameter:
	# TaskGroup, detectEncoding, rootOutDirPath,
	# locale, stat, data, buffer, meta.
	# @method setOptions
	# @param {Object} [attrs={}]
	###
	setOptions: (attrs={}) ->
		# TaskGroup
		if attrs.TaskGroup?
			@TaskGroup = attrs.TaskGroup
			delete @attributes.TaskGroup

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

	###*
	# Clone the model and return the newly cloned model.
	# @method clone
	# @return {Object} cloned file model
	###
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

	###*
	# The default attributes for any file model.
	# @private
	# @property {Object}
	###
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

	###*
	# File encoding helper
	# opts = {path, to, from, content}
	# @private
	# @method encode
	# @param {Object} opts
	# @return {Object} encoded result
	###
	encode: (opts) ->
		# Prepare
		locale = @getLocale()
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

	###*
	# Set the file model's buffer.
	# Creates a new node.js buffer
	# object if a buffer object is
	# is not passed as the parameter
	# @method setBuffer
	# @param {Object} [buffer]
	###
	setBuffer: (buffer) ->
		buffer = new Buffer(buffer)  unless Buffer.isBuffer(buffer)
		@bufferTime = @get('mtime') or new Date()
		@buffer = buffer
		@

	###*
	# Get the file model's buffer object.
	# Returns a node.js buffer object.
	# @method getBuffer
	# @return {Object} node.js buffer object
	###
	getBuffer: ->
		return @buffer

	###*
	# Is Buffer Outdated
	# True if there is no buffer OR the buffer time is outdated
	# @method isBufferOutdated
	# @return {Boolean}
	###
	isBufferOutdated: ->
		return @buffer? is false or @bufferTime < (@get('mtime') or new Date())

	###*
	# Set the node.js file stat.
	# @method setStat
	# @param {Object} stat
	###
	setStat: (stat) ->
		@stat = stat
		@set(
			ctime: new Date(stat.ctime)
			mtime: new Date(stat.mtime)
		)
		@

	###*
	# Get the node.js file stat.
	# @method getStat
	# @return {Object} the file stat
	###
	getStat: ->
		return @stat

	###*
	# Get the file model attributes.
	# By default the attributes will be
	# dereferenced from the file model.
	# To maintain a reference, pass false
	# as the parameter. The returned object
	# will NOT contain the file model's ID attribute.
	# @method getAttributes
	# @param {Object} [dereference=true]
	# @return {Object}
	###
	#NOTE: will the file model's ID be deleted if
	#dereference=false is passed??
	getAttributes: (dereference=true) ->
		attrs = @toJSON(dereference)
		delete attrs.id
		return attrs

	###*
	# Get the file model attributes.
	# By default the attributes will
	# maintain a reference to the file model.
	# To return a dereferenced object, pass true
	# as the parameter. The returned object
	# will contain the file model's ID attribute.
	# @method toJSON
	# @param {Object} [dereference=false]
	# @return {Object}
	###
	toJSON: (dereference=false) ->
		data = super
		data.meta = @getMeta().toJSON()
		data = extendr.dereferenceJSON(data)  if dereference is true
		return data

	###*
	# Get the file model metadata object.
	# Optionally pass a list of metadata property
	# names corresponding to those properties that
	# you want returned.
	# @method getMeta
	# @param {Object} [args...]
	# @return {Object}
	###
	getMeta: (args...) ->
		@meta = new Model()  if @meta is null
		if args.length
			return @meta.get(args...)
		else
			return @meta

	###*
	# Assign attributes and options to the file model.
	# @method set
	# @param {Array} attrs the attributes to be applied
	# @param {Object} opts the options to be applied
	###
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

	###*
	# Set defaults. Apply default attributes
	# and options to the file model
	# @method setDefaults
	# @param {Object} attrs the attributes to be applied
	# @param {Object} opts the options to be applied
	###
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

	###*
	# Set the file model meta data,
	# attributes and options in one go.
	# @method setMeta
	# @param {Object} attrs the attributes to be applied
	# @param {Object} opts the options to be applied
	###
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


	###*
	# Set the file model meta data defaults
	# @method setMetaDefaults
	# @param {Object} attrs the attributes to be applied
	# @param {Object} opts the options to be applied
	###
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

	###*
	# Get the file name. Depending on the
	# parameters passed this will either be
	# the file model's filename property or,
	# the filename determined from the fullPath
	# or relativePath property. Valid values for
	# the opts parameter are: fullPath, relativePath
	# or filename. Format: {filename}
	# @method getFilename
	# @param {Object} [opts={}]
	# @return {String}
	###
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

	###*
	# Get the file path. Depending on the
	# parameters passed this will either be
	# the file model's fullPath property, the
	# relativePath property or the filename property.
	# Valid values for the opts parameter are:
	# fullPath, relativePath
	# or filename. Format: {fullPath}
	# @method getFilePath
	# @param {Object} [opts={}]
	# @return {String}
	###
	getFilePath: (opts={}) ->
		# Prepare
		{fullPath,relativePath,filename} = opts

		# Determine
		result = (fullPath ? @get('fullPath')) or (relativePath ? @get('relativePath')) or (filename ? @get('filename')) or null

		# Return
		return result

	###*
	# Get file extensions. Depending on the
	# parameters passed this will either be
	# the file model's extensions property or
	# the extensions extracted from the file model's
	# filename property. The opts parameter is passed
	# in the format: {extensions,filename}.
	# @method getExtensions
	# @param {Object} opts
	# @return {Array} array of extension names
	###
	getExtensions: ({extensions,filename}) ->
		extensions or= @get('extensions') or null
		if (extensions or []).length is 0
			filename = @getFilename({filename})
			if filename
				extensions = docpadUtil.getExtensions(filename)
		return extensions or null

	###*
	# Get the file content. This will be
	# the text content if loaded or the file buffer object.
	# @method getContent
	# @return {String or Object}
	###
	getContent: ->
		return @get('content') or @getBuffer()

	###*
	# Get the file content for output.
	# @method getOutContent
	# @return {String or Object}
	###
	getOutContent: ->
		return @getContent()

	###*
	# Is this a text file? ie - not
	# a binary file.
	# @method isText
	# @return {Boolean}
	###
	isText: ->
		return @get('encoding') isnt 'binary'

	###*
	# Is this a binary file?
	# @method isBinary
	# @return {Boolean}
	###
	isBinary: ->
		return @get('encoding') is 'binary'

	###*
	# Set the url for the file
	# @method setUrl
	# @param {String} url
	###
	setUrl: (url) ->
		@addUrl(url)
		@set({url})
		@

	###*
	# A file can have multiple urls.
	# This method adds either a single url
	# or an array of urls to the file model.
	# @method addUrl
	# @param {String or Array} url
	###
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

	###*
	# Removes a url from the file
	# model (files can have more than one url).
	# @method removeUrl
	# @param {Object} userUrl the url to be removed
	###
	removeUrl: (userUrl) ->
		urls = @get('urls')
		for url,index in urls
			if url is userUrl
				urls.splice(index,1)
				break
		@

	###*
	# Get a file path.
	# If the relativePath parameter starts with `.` then we get the
	# path in relation to the document that is calling it.
	# Otherwise we just return it as normal
	# @method getPath
	# @param {String} relativePath
	# @param {String} parentPath
	# @return {String}
	###
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

	###*
	# The action runner instance bound to DocPad
	# @private
	# @property {Object} actionRunnerInstance
	###
	actionRunnerInstance: null
	###*
	# Get the action runner instance bound to DocPad
	# @method getActionRunner
	# @return {Object}
	###
	getActionRunner: -> @actionRunnerInstance
	###*
	# Apply an action with the supplied arguments.
	# @method action
	# @param {Object} args...
	###
	action: (args...) => docpadUtil.action.apply(@, args)

	###*
	# Initialize the file model with the passed
	# attributes and options. Emits the init event.
	# @method initialize
	# @param {Object} attrs the file model attributes
	# @param {Object} [opts={}] the file model options
	###
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
		@actionRunnerInstance = new @TaskGroup("file action runner", {abortOnError: false, destroyOnceDone: false}).whenDone (err) ->
			file.emit('error', err)  if err

		# Apply
		@emit('init')

		# Chain
		@

	###*
	# Load the file from the file system.
	# If the fullPath exists, load the file.
	# If it doesn't, then parse and normalize the file.
	# Optionally pass file options as a parameter.
	# @method load
	# @param {Object} [opts={}]
	# @param {Function} next callback
	###
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
		tasks = new @TaskGroup("load tasks for file: #{filePath}", {next})
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

	###*
	# Parse our buffer and extract meaningful data from it.
	# next(err).
	# @method parse
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
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

	###*
	# Normalize any parsing we have done, because if a value has
	# updates it may have consequences on another value.
	# This will ensure everything is okay.
	# next(err)
	# @method normalize
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
	normalize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		changes = {}
		meta = @getMeta()
		locale = @getLocale()

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

	###*
	# Contextualize the data. In other words,
	# put our data into the perspective of the bigger picture of the data.
	# For instance, generate the url for it's rendered equivalant.
	# next(err)
	# @method contextualize
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
	contextualize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Forward
		next()
		@

	###*
	# Render this file. The file model output content is
	# returned to the passed callback in the
	# result (2nd) parameter. The file model itself is returned
	# in the callback's document (3rd) parameter.
	# next(err,result,document)
	# @method render
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
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

	###*
	# Write the out file. The out file
	# may be different from the input file.
	# Often the input file is transformed in some way
	# and saved as another file format. A common example
	# is transforming a markdown input file to a HTML
	# output file.
	# next(err)
	# @method write
	# @param {Object} opts
	# @param {Function} next callback
	###
	write: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		locale = @getLocale()

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

	###*
	# Write the source file. Optionally pass
	# the opts parameter to modify or set the file's
	# path, content or type.
	# next(err)
	# @method writeSource
	# @param {Object} [opts]
	# @param {Object} next callback
	###
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

	###*
	# Delete the out file, perhaps ahead of regeneration.
	# Optionally pass the opts parameter to set the file path or type.
	# next(err)
	# @method delete
	# @param {Object} [opts]
	# @param {Object} next callback
	###
	'delete': (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		locale = @getLocale()

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

	###*
	# Delete the source file.
	# Optionally pass the opts parameter to set the file path or type.
	# next(err)
	# @method deleteSource
	# @param {Object} [opts]
	# @param {Object} next callback
	###
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
