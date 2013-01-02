# Requires
pathUtil = require('path')
balUtil = require('bal-util')
mime = require('mime')

# Local
{Backbone,Model} = require(__dirname+'/../base')


# ---------------------------------
# File Model

class FileModel extends Model

	# ---------------------------------
	# Properties

	# The out directory path to put the file
	outDirPath: null

	# Model Type
	type: 'file'

	# Stat Object
	stat: null

	# File data
	# When we do not have a path to scan
	# we can just pass over some data instead
	data: null

	# File buffer
	buffer: null

	# The parsed file meta data (header)
	# Is a Backbone.Model instance
	meta: null


	# ---------------------------------
	# Attributes

	defaults:

		# ---------------------------------
		# Automaticly set variables

		# The unique document identifier
		id: null

		# The file's name without the extension
		basename: null

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
		# @TODO: rename to `path` in next major breaking version
		path: null

		# The output path of our file
		outPath: null

		# The full directory path of our source file
		# @TODO: rename to `dirPath` in next major breaking version
		dirPath: null

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

		# The title for this document
		# Useful for page headings
		title: null

		# The name for this document, defaults to the filename
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

	# Set Data
	setData: (data) ->
		@data = data
		@

	# Get Data
	getData: ->
		return @data

	# Set Buffer
	setBuffer: (buffer) ->
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
		return @toJSON()

	# Get Meta
	getMeta: ->
		@meta = new Model()  if @meta is null
		return @meta

	# Set Meta
	setMeta: (attrs) ->
		@getMeta().set(attrs)
		@set(attrs)
		return @

	# Set Meta Defaults
	setMetaDefaults: (defaults) ->
		@getMeta().setDefaults(defaults)
		@setDefaults(defaults)
		return @

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
			for own existingUrl in urls
				if existingUrl is url
					found = true
					break
			urls.push(url)  if not found

		# Chain
		@

	# Remove a url
	# Removes a url from our file
	removeUrl: (userUrl) ->
		urls = @get('urls')
		for url,index in urls
			if url is userUrl
				urls.remove(index)
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
		# Prepare
		{outDirPath,stat,data,meta} = opts

		# Special
		@outDirPath = outDirPath  if outDirPath

		# Defaults
		defaults =
			extensions: []
			urls: []
			id: @cid

		# Stat
		if stat
			@setStat(stat)
		else
			defaults.ctime = new Date()
			defaults.mtime = new Date()

		# Defaults
		@set(defaults)

		# Data
		if attrs.data?
			data = attrs.data
			delete attrs.data
			delete @attributes.data
		if data
			@setData(data)

		# Meta
		if attrs.meta?
			@setMeta(attrs.meta)
			delete attrs.meta
		if meta
			@setMeta(meta)

		# Super
		super

	# Get the arguments for the action
	# Using this contains the transparency with using opts, and not using opts
	getActionArgs: (opts,next) ->
		if balUtil.isFunction(opts) and next? is false
			next = opts
			opts = {}
		else
			opts or= {}
		next or= opts.next or null
		return {next,opts}

	# Load
	# If the fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		file = @
		exists = opts.exists ? false

		# Normalize
		fullPath = @get('fullPath')
		unless fullPath
			filePath = @get('relativePath') or @get('fullPath') or @get('filename')
			fullPath = @get('fullPath') or filePath or null
			file.set({fullPath})

		# Log
		file.log('debug', "Loading the file: #{fullPath}")

		# Async
		tasks = new balUtil.Group (err) =>
			return next(err)  if err
			file.log('debug', "Loaded the file: #{fullPath}")
			file.parse (err) ->
				return next(err)  if err
				file.normalize (err) ->
					return next(err)  if err
					return next(null,file.buffer)

		# If data is set, use that as the buffer
		data = file.getData()
		if data
			buffer = new Buffer(data)
			file.setBuffer(buffer)

		# If stat is set, use that
		if opts.stat
			file.setStat(opts.stat)

		# If buffer is set, use that
		if opts.buffer
			file.setBuffer(opts.buffer)

		# Stat the file and cache the result
		tasks.push (complete) ->
			# Otherwise fetch new stat
			if fullPath and exists and opts.stat? is false
				return balUtil.stat fullPath, (err,fileStat) ->
					return complete(err)  if err
					file.setStat(fileStat)
					return complete()
			else
				return complete()

		# Read the file and cache the result
		tasks.push (complete) ->
			# Otherwise fetch new buffer
			if fullPath and exists and opts.buffer? is false
				return balUtil.readFile fullPath, (err,buffer) ->
					return complete(err)  if err
					file.setBuffer(buffer)
					return complete()
			else
				return complete()

		# Run the tasks
		if fullPath
			balUtil.exists fullPath, (_exists) ->
				exists = _exists
				file.set({exists:true})
				tasks.async()
		else
			tasks.async()

		# Chain
		@

	# Parse
	# Parse our buffer and extract meaningful data from it
	# next(err)
	parse: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		buffer = @getBuffer()
		fullPath = @get('fullPath')
		encoding = @get('encoding')

		# Detect encoding
		unless encoding
			isText = balUtil.isTextSync(fullPath,buffer)
			if isText
				encoding = 'utf8'
			else
				encoding = 'binary'

		# Fetch source with encoding
		if encoding is 'utf8'
			source = buffer.toString(encoding)
		else
			source = ''

		# Trim the content
		content = source.replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')

		# Apply
		@set({source,content,encoding})

		# Next
		next()
		@

	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		changes = {}

		# Fetch
		meta = @getMeta()
		basename = @get('basename')
		filename = @get('filename')
		fullPath = @get('fullPath')
		extensions = @get('extensions')
		relativePath = @get('relativePath')
		mtime = @get('mtime')
		date = meta.get('date') or null

		# Filename
		if fullPath
			changes.filename = filename = pathUtil.basename(fullPath)
			changes.outFilename = filename

		# Basename, extensions, extension
		if filename
			if filename[0] is '.'
				basename = filename.replace(/^(\.[^\.]+)\..*$/, '$1')
			else
				basename = filename.replace(/\..*$/, '')
			changes.basename = basename

			# Extensions
			if extensions? is false or extensions.length is 0
				extensions = filename.split(/\./g)
				extensions.shift() # ignore the first result, as that is our filename
			changes.extensions = extensions

			# determine the single extension that determine this file
			if extensions.length
				extension = extensions[extensions.length-1]
			else
				extension = null
			changes.extension = extension
			changes.outExtension = extension

		# fullDirPath, contentType
		if fullPath
			changes.fullDirPath = fullDirPath = pathUtil.dirname(fullPath) or ''
			changes.contentType = contentType = mime.lookup(fullPath)
			changes.outContentType = contentType

		# relativeDirPath, relativeBase
		if relativePath
			changes.relativeDirPath = relativeDirPath = pathUtil.dirname(relativePath).replace(/^\.$/,'') or ''
			changes.relativeBase = relativeBase =
				if relativeDirPath
					pathUtil.join(relativeDirPath, basename)
				else
					basename
			changes.id = id = relativePath

		# Date
		if !date and mtime
			changes.date = date = mtime

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
		{opts,next} = @getActionArgs(opts,next)
		changes = {}

		# Fetch
		meta = @getMeta()
		relativePath = @get('relativePath')
		relativeDirPath = @get('relativeDirPath')
		relativeBase = @get('relativeBase')
		filename = @get('filename')
		outPath = @get('outPath')
		outDirPath = @get('outDirPath')
		name = meta.get('name') or null
		slug = meta.get('slug') or null
		url = meta.get('url') or null

		# Create the URL for the file
		if !url and relativePath
			url = "/#{relativePath}"
			@setUrl(url)

		# Create a slug for the file
		if !slug and relativeBase
			changes.slug = slug = balUtil.generateSlugSync(relativeBase)

		# Set name if it doesn't exist already
		if !name and filename
			changes.name = name = filename

		# Create the outPath if we have a outpute directory
		if @outDirPath and relativePath
			changes.relativeOutDirPath = relativeOutDirPath = relativeDirPath  if  relativeDirPath?
			changes.relativeOutPath = relativeOutPath = relativePath
			changes.outPath = outPath = pathUtil.join(@outDirPath,relativePath)
			if outPath
				changes.outDirPath = outDirPath = pathUtil.dirname(outPath)

		# Apply
		@set(changes)

		# Forward
		next()
		@


	# ---------------------------------
	# CRUD

	# Write the rendered file
	# next(err)
	write: (next) ->
		# Prepare
		file = @
		fileOutPath = @get('outPath')
		encoding = @get('encoding')
		content = @getContent()

		# Check
		# Sometimes the out path could not be set if we are early on in the process
		unless fileOutPath
			next()
			return @

		# Log
		file.log 'debug', "Writing the file: #{fileOutPath} #{encoding}"

		# Write data
		balUtil.writeFile fileOutPath, content, encoding, (err) ->
			# Check
			return next(err)  if err

			# Log
			file.log 'debug', "Wrote the file: #{fileOutPath} #{encoding}"

			# Next
			next()

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
		balUtil.exists fileOutPath, (exists) ->
			# Exit if it doesn't exist
			return next()  unless exists
			# If it does exist delete it
			balUtil.unlink fileOutPath, (err) ->
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
