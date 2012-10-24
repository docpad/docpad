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

	# Model type
	type: 'file'

	# Stat object
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
	# Functions

	# Initialize
	initialize: (attrs,opts) ->
		# Prepare
		{outDirPath,stat,data,meta} = opts
		if attrs.data?
			data = attrs.data
			delete attrs.data
			delete @attributes.data

		# Apply
		@outDirPath = outDirPath  if outDirPath
		@setStat(stat)  if stat
		@setData(data)  if data
		@set({
			extensions: []
			urls: []
			id: @cid
		})

		# Meta
		@meta = new Model()
		if meta
			@meta.set(meta)
			@set(meta)

		# Super
		super

	# Set Data
	setData: (data) ->
		@data = data
		@

	# Get Data
	getData: (data) -> @data

	# Set Buffer
	setBuffer: (buffer) ->
		@buffer = buffer
		@

	# Get buffer
	getBuffer: (next) ->
		# Check our cache
		return next(null,@buffer)  if @buffer

		# Load the data fresh
		@load (err) =>
			next(err,@buffer)

		# Chain
		@

	# Clean
	# Wipe any unnecessary data
	clean: (next) ->
		@setBuffer(null)
		###
		@set({
			content:null
			source:null
		})
		###
		next?()
		@

	# Get Content
	getContent: (next) ->
		content = @get('content')
		if content
			next(null,content)
		else
			@getBuffer(next)
		@

	# Get Out Content
	getOutContent: (next) ->
		@getContent(next)
		@

	# Set Stat
	setStat: (stat) ->
		@stat = stat
		@set(
			ctime: new Date(stat.ctime)
			mtime: new Date(stat.mtime)
		)
		@

	# Get Attributes
	getAttributes: ->
		return @toJSON()

	# Get Meta
	getMeta: ->
		return @meta

	# Is Text?
	isText: ->
		return @get('encoding') isnt 'binary'

	# Is Binary?
	isBinary: ->
		return @get('encoding') is 'binary'

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


	# Load
	# If data exists, use that for the buffer
	# If data doesn't exist, load the buffer from the file
	# next(err,buffer)
	load: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		file = @

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

		# Read the data if it is set
		tasks.push (complete) ->
			if file.data
				buffer = new Buffer(file.data)
				file.setBuffer(buffer)
				tasks.exit()
			else
				complete()

		# Stat the file and cache the result
		tasks.push (complete) ->
			return complete()  if file.stat
			balUtil.stat fullPath, (err,fileStat) ->
				return complete(err)  if err
				file.setStat(fileStat)
				tasks.complete()

		# Read the file and cache the result
		tasks.push (complete) ->
			return complete()  if file.buffer
			balUtil.readFile fullPath, (err,buffer) ->
				return complete(err)  if err
				file.setBuffer(buffer)
				return complete()

		# Run the tasks
		tasks.sync()

		# Chain
		@

	# Parse
	# Parse our buffer and extract meaningful data from it
	# next(err)
	parse: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		buffer = @buffer
		fullPath = @get('fullPath')
		encoding = @get('encoding')

		# Extract content
		if buffer instanceof Buffer
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

		# Data is a string
		else if balUtil.isString(buffer)
			encoding = 'utf8'  unless encoding
			source = buffer

		# Data is invalid
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

	# Write the rendered file
	# next(err)
	write: (next) ->
		# Prepare
		file = @
		fileOutPath = @get('outPath')
		@getContent (err,content) =>
			# Prepare
			return next(err)  if err
			encoding = @get('encoding')

			# Log
			file.log 'debug', "Writing the file: #{fileOutPath} #{encoding}"

			# Write data
			balUtil.writeFile fileOutPath, content, encoding, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'debug', "Wrote the file: #{fileOutPath} #{encoding}"

				# Next
				return next()

		# Chain
		@

	# Delete the file
	# next(err)
	delete: (next) ->
		# Prepare
		file = @
		fileOutPath = @get('outPath')

		# Log
		file.log 'debug', "Delete the file: #{fileOutPath}"

		# Write data
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
