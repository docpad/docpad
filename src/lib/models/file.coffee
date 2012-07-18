# Requires
pathUtil = require('path')
balUtil = require('bal-util')
_ = require('underscore')
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

		# The full path of our source file, only necessary if called by @load
		fullPath: null

		# The full directory path of our source file
		fullDirPath: null

		# The final rendered path of our file
		outPath: null

		# The final rendered path of our file's directory
		outDirPath: null

		# The relative path of our source file (with extensions)
		relativePath: null

		# The relative directory path of our source file
		relativeDirPath: null

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
		{outDirPath,stat} = options

		# Apply
		@outDirPath = outDirPath  if outDirPath
		@setStat(stat)  if stat
		@set({extensions:[], urls:[]},{silent:true})

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

	# Load
	# If the fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		file = @
		filePath = @get('relativePath') or @get('fullPath') or @get('filename')
		fullPath = @get('fullPath') or filePath or null
		data = @get('data')

		# Apply

		# Log
		file.log('debug', "Loading the file: #{filePath}")

		# Handler
		complete = (err) ->
			return next(err)  if err
			file.log('debug', "Loaded the file: #{filePath}")
			next()
		handlePath = ->
			file.set({fullPath},{silent:true})
			file.readFile(fullPath, complete)
		handleData = ->
			file.set({fullPath:null},{silent:true})
			file.parseData data, (err) =>
					return next(err)  if err
					file.normalize (err) =>
						return next(err)  if err
						complete()
		# Exists?
		if fullPath
			balUtil.exists fullPath, (exists) ->
				# Read the file
				if exists
					handlePath()
				else
					handleData()
		else
			handleData()

		# Chain
		@

	# Read File
	# Reads in the source file and parses it
	# next(err)
	readFile: (fullPath,next) ->
		# Prepare
		file = @
		fullPath = @get('fullPath')

		# Log
		file.log('debug', "Reading the file: #{fullPath}")

		# Async
		tasks = new balUtil.Group (err) =>
			if err
				file.log('err', "Failed to read the file: #{fullPath}")
				return next(err)
			else
				@normalize (err) =>
					return next(err)  if err
					file.log('debug', "Read the file: #{fullPath}")
					next()
		tasks.total = 2

		# Stat the file
		if file.stat
			tasks.complete()
		else
			balUtil.stat fullPath, (err,fileStat) ->
				return next(err)  if err
				file.stat = fileStat
				tasks.complete()

		# Read the file
		balUtil.readFile fullPath, (err,data) ->
			return next(err)  if err
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
		# Prepare
		encoding = 'utf8'

		# Reset the file properties back to their originals
		backup = @attributes
		reset = balUtil.dereference balUtil.extend({},@defaults,{
			data: data
			basename: backup.basename
			extension: backup.extension
			extensions: backup.extensions
			filename: backup.filename
			fullPath: backup.fullPath
			outPath: backup.outPath
			outDirPath: backup.outDirPath
			relativePath: backup.relativePath
			relativeBase: backup.relativeBase
			contentType: backup.contentType
			urls: []
		})
		@set(reset)

		# Extract content from data
		if data instanceof Buffer
			encoding = @getEncoding(data)
			if encoding is 'binary'
				content = ''
			else
				content = data.toString(encoding)
		else if balUtil.isString(data)
			content = data
		else
			content = ''

		# Trim the content
		content = content.replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')

		# Apply
		@set({content,encoding})

		# Next
		next()
		@

	# Set the url for the file
	setUrl: (url) ->
		@addUrl(url)
		@set(url: url)
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

	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		basename = @get('basename') or null
		filename = @get('filename') or null
		fullPath = @get('fullPath') or null
		relativePath = @get('relativePath') or null
		id = @get('id') or null
		date = @get('date') or null
		fullDirPath = @get('fullDirPath') or null
		relativeDirPath = @get('relativeDirPath') ? ''
		relativeBase = @get('relativeBase') or null
		extension = @get('extension') or null
		extensions = @get('extensions') or null
		contentType = @get('contentType') or null


		# Filename
		if fullPath?
			filename = pathUtil.basename(fullPath)
		if filename?
			if filename[0] is '.'
				basename = filename.replace(/^(\.[^\.]+)\..*$/, '$1')
			else
				basename = filename.replace(/\..*$/, '')

			# Extensions
			if extensions? is false or extensions.length is 0
				extensions = filename.split(/\./g)
				extensions.shift() # ignore the first result, as that is our filename

			# determine the single extension that determine this file
			if extensions.length
				extension = extensions[extensions.length-1]
			else
				extension = null

		# Paths
		if fullPath?
			fullDirPath = pathUtil.dirname(fullPath) or ''
			contentType = mime.lookup(fullPath)
		if relativePath?
			relativeDirPath = pathUtil.dirname(relativePath).replace(/^\.$/,'') or ''
			relativeBase =
				if relativeDirPath
					pathUtil.join(relativeDirPath, basename)
				else
					basename

		# ID
		id or= relativePath or fullPath or @cid

		# Date
		if @stat?
			date or= new Date(@stat.mtime)

		# Apply
		@set({basename,filename,fullPath,relativePath,fullDirPath,relativeDirPath,id,relativeBase,extensions,extension,contentType,date})

		# Next
		next()
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (opts={},next) ->
		# Fetch
		{opts,next} = @getActionArgs(opts,next)
		relativeBase = @get('relativeBase') or null
		extensions = @get('extensions') or null
		filename = @get('filename') or null
		url = @get('url') or null
		slug = @get('slug') or null
		name = @get('name') or null
		outPath = @get('outPath') or null
		outDirPath = @get('outDirPath') or null

		# Adjust
		if relativeBase?
			if extensions? and extensions.length and filename?
				if filename[0] is '.'
					extensions = extensions.slice(1)
				url = "/#{relativeBase}.#{extensions.join('.')}"
			else
				url = "/#{relativeBase}"
			slug or= balUtil.generateSlugSync(relativeBase)
		if filename?
			name or= filename
		if @outDirPath?
			outPath = pathUtil.join(@outDirPath,url)
			outDirPath = pathUtil.dirname(outPath)  if outPath
		if url?
			@addUrl(url)

		# Apply
		@set({url,slug,name,outPath,outDirPath})

		# Forward
		next()
		@

	# Write the rendered file
	# next(err)
	write: (next) ->
		# Prepare
		file = @
		fileOutPath = @get('outPath')
		contentOrData = @get('content') or @get('data')

		# Log
		file.log 'debug', "Writing the file: #{fileOutPath}"

		# Write data
		balUtil.writeFile fileOutPath, contentOrData, (err) ->
			# Check
			return next(err)  if err

			# Log
			file.log 'debug', "Wrote the file: #{fileOutPath}"

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
