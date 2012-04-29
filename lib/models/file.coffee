# Requires
path = require('path')
fs = require('fs')
balUtil = require('bal-util')
_ = require('underscore')
Backbone = require('backbone')
mime = require('mime')

# Optionals
coffee = null
yaml = null
js2coffee = null

# Base Model
{Model} = require(path.join __dirname, 'base.coffee')


# ---------------------------------
# File Model

class FileModel extends Model

	# ---------------------------------
	# Properties

	# The out directory path to put the file
	outDirPath: null

	# Model Type
	type: 'file'

	# Logger
	logger: null

	# Stat Object
	stat: null


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

		# The file's extensions as an array
		# "hello.md.eco" -> ["md","eco"]
		extensions: null  # Array

		# The file's name with the extension
		filename: null

		# The full path of our file, only necessary if called by @load
		fullPath: null

		# The final rendered path of our file
		outPath: null

		# The relative path of our source file (with extensions)
		relativePath: null

		# The relative base of our source file (no extension)
		relativeBase: null

		# The MIME content-type for the source document
		contentType: null


		# ---------------------------------
		# Content variables

		# The contents of the file, stored as a Buffer
		data: null

		# The encoding of the file
		encoding: null

		# The contents of the file, stored as a String
		content: null


		# ---------------------------------
		# User set variables

		# The title for this document
		title: null

		# The date object for this document
		date: null

		# The generated slug (url safe seo title) for this document
		slug: null

		# The url for this document
		url: null

		# Alternative urls for this document
		urls: null  # Array

		# Whether or not we ignore this document (do not render it)
		ignored: false



	# ---------------------------------
	# Functions

	# Initialize
	initialize: (data,options) ->
		# Prepare
		{@logger,@outDirPath,@stat} = options

		# Advanced attributes
		@set(
			extensions: []
			urls: []
		)

		# Super
		super

	# Get Attributes
	getAttributes: ->
		return @toJSON()

	# Get Meta
	getMeta: ->
		return @meta

	# Load
	# If the fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (next) ->
		# Prepare
		filePath = @get('relativePath') or @get('fullPath') or @get('filename')
		fullPath = @get('fullPath')
		data = @get('data')
		logger = @logger

		# Log
		logger.log('debug', "Loading the file: #{filePath}")

		# Handler
		complete = (err) ->
			return next?(err)  if err
			logger.log('debug', "Loaded the file: #{filePath}")
			next?()

		# Exists?
		path.exists fullPath, (exists) =>
			# Read the file
			if exists
				@readFile(fullPath, complete)
			else
				@parseData data, (err) =>
					return next?(err)  if err
					@normalize (err) =>
						return next?(err)  if err
						complete()

		# Chain
		@

	# Read File
	# Reads in the source file and parses it
	# next(err)
	readFile: (fullPath,next) ->
		# Prepare
		logger = @logger
		file = @
		fullPath = @get('fullPath')
		relativePath = @get('relativePath')

		# Log
		logger.log('debug', "Reading the file: #{relativePath}")

		# Async
		tasks = new balUtil.Group (err) =>
			if err
				logger.log('err', "Failed to read the file: #{relativePath}")
				return next?(err)
			else
				@normalize (err) =>
					return next?(err)  if err
					logger.log('debug', "Read the file: #{relativePath}")
					next?()
		tasks.total = 2

		# Stat the file
		if file.stat
			tasks.complete()
		else
			balUtil.openFile -> fs.stat fullPath, (err,fileStat) ->
				balUtil.closeFile()
				return next?(err)  if err
				file.stat = fileStat
				tasks.complete()

		# Read the file
		balUtil.openFile -> fs.readFile fullPath, (err,data) ->
			balUtil.closeFile()
			return next?(err)  if err
			file.parseData(data, tasks.completer())

		# Chain
		@

	# Get the encoding of a buffer
	getEncoding: (buffer) ->
		# Prepare
		contentStartBinary = buffer.toString('binary',0,24)
		contentStartUTF8 = buffer.toString('utf8',0,24)
		encoding = 'utf8'

		# Detect encoding
		for i in [0...contentStartUTF8.length]
			charCode = contentStartUTF8.charCodeAt(i)
			if charCode is 65533 or charCode <= 8
				# 8 and below are control characters (e.g. backspace, null, eof, etc.)
				# 65533 is the unknown character
				encoding = 'binary'
				break

		# Return encoding
		return encoding

	# Parse data
	# Parses some data, and loads the meta data and content from it
	# next(err)
	parseData: (data,next) ->
		# Wipe everything
		backup = @toJSON()
		@meta.clear()
		@clear()
		encoding = 'utf8'

		# Reset the file properties back to their originals
		@set(
			data: data
			basename: backup.basename
			extension: backup.extension
			extensions: backup.extensions
			filename: backup.filename
			fullPath: backup.fullPath
			outPath: backup.outPath
			relativePath: backup.relativePath
			relativeBase: backup.relativeBase
			contentType: backup.contentType
			urls: []
		)

		# Extract content from data
		if data instanceof Buffer
			encoding = @getEncoding(data)
			if encoding is 'binary'
				content = ''
			else
				content = data.toString(encoding)
		else if typeof data is 'string'
			content = data
		else
			content = ''

		# Trim the content
		content = content.replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')

		# Apply
		@set({content,encoding})

		# Next
		next?()
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


	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (next) ->
		# Prepare
		basename = @get('basename')
		filename = @get('filename')
		fullPath = @get('fullPath')
		relativePath = @get('relativePath')
		id = @get('id')
		date = @get('date')

		# Adjust
		fullPath or= filename
		relativePath or= fullPath

		# Paths
		basename = path.basename(fullPath)
		filename = basename
		basename = filename.replace(/\..*/, '')

		# Extension
		extensions = filename.split(/\./g)
		extensions.shift()
		extension = if extensions.length then extensions[extensions.length-1] else null

		# Paths
		fullDirPath = path.dirname(fullPath) or ''
		relativeDirPath = path.dirname(relativePath).replace(/^\.$/,'') or ''
		relativeBase =
			if relativeDirPath.length
				path.join(relativeDirPath, basename)
			else
				basename
		id or= relativeBase

		# Date
		date or= new Date(@stat.mtime)  if @stat

		# Mime type
		contentType = mime.lookup(fullPath)

		# Apply
		@set({basename,filename,fullPath,relativePath,id,relativeBase,extensions,extension,contentType,date})

		# Next
		next?()
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (next) ->
		# Fetch
		relativeBase = @get('relativeBase')
		extension = @get('extension')
		filename = @get('filename')
		url = @meta.get('url') or null
		slug = @meta.get('slug') or null
		name = @meta.get('name') or null
		outPath = @meta.get('outPath') or null

		# Adjust
		url or= if extension then "/#{relativeBase}.#{extension}" else "/#{relativeBase}"
		slug or= balUtil.generateSlugSync(relativeBase)
		name or= filename
		outPath = if @outDirPath then path.join(@outDirPath,url) else null
		@addUrl(url)

		# Apply
		@set({url,slug,name,outPath})

		# Forward
		next?()
		@

	# Write Data
	writeFile: (fullPath,data,next) ->
		# Prepare
		file = @

		# Write data
		balUtil.openFile -> fs.writeFile fullPath, data, (err) ->
			balUtil.closeFile()
			return next?(err)

		# Chain
		@

	# Write the rendered file
	# next(err)
	write: (next) ->
		# Prepare
		logger = @logger
		fileOutPath = @get('outPath')
		content = @get('content') or @get('data')

		# Log
		logger.log 'debug', "Writing the file #{fileOutPath}"

		# Write data
		@writeFile fileOutPath, content, (err) ->
			# Check
			return next?(err)  if err

			# Log
			logger.log 'debug', "Wrote the file #{fileOutPath}"

			# Next
			next?()

		# Chain
		@

# Export
module.exports = FileModel
