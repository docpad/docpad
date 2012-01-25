# Requires
util = require 'bal-util'
fs = require 'fs'
path = require 'path'
coffee = null
yaml = null
js2coffee = null

# ---------------------------------
# DocPad File Class

class File

	# ---------------------------------
	# Backreferences to DocPad

	# The DocPad instance
	docpad: null

	# The available layouts in our DocPad instance
	layouts: []

	# The Caterpillar instance to use
	logger: null

	# The out directory path to put the file
	outDirPath: null


	# ---------------------------------
	# Automaticly set variables

	# The unique document identifier
	id: null
	
	# The filename without the extension
	basename: null

	# The filename with the extension
	filename: null

	# The extensions the filename has, in reverse order (.md.eco -> [eco,md])
	extensions: []

	# The original first extension (.md.eco -> eco)
	extension: null

	# The final extension used on our rendered file (takes into accounts layouts)
	extensionRendered: null

	# The full path of our file, only necessary is calling @load
	fullPath: null

	# The final rendered path of our file 
	outPath: null

	# The relative path of our source file (with extensions)
	relativePath: null

	# The relative base of our source file (no extension)
	relativeBase: null

	content: null
	contentSrc: null
	contentRaw: null
	contentRendered: null
	fileMeta: {}
	fileHead: null
	fileBody: null
	fileHeadParser: null


	# ---------------------------------
	# User set variables

	# Whether or not this file should be re-rendered on each request
	dynamic: false

	# The title for this document
	title: null

	# The date object for this document
	date: null

	# The generated slug (url safe seo title) for this document
	slug: null

	# The url for this document
	url: null

	# Alternative urls for this document
	urls: []

	# Whether or not we ignore this document (do not render it)
	ignore: false

	# The tags for this document
	tags: []

	# Any related documents
	relatedDocuments: []


	# ---------------------------------
	# Functions

	# Constructor
	constructor: ({@docpad,@layouts,@logger,@outDirPath,meta}) ->
		# Delete prototype references
		@extensions = []
		@tags = []
		@relatedDocuments = []
		@fileMeta = {}
		@urls = []

		# Copy over meta data
		for own key, value of meta
			@[key] = value

	# Load
	# Loads in the source file and parses it
	# next(err)
	load: (next) ->
		# Log
		@logger.log 'debug', "Reading the file #{@relativePath}"

		# Async
		tasks = new util.Group (err) =>
			if err
				@logger.log 'err', "Failed to read the file #{@relativePath}"
				return next?(err)
			else
				@normalize (err) =>
					return next?(err)  if err
					@logger.log 'debug', "Read the file #{@relativePath}"
					next?()
		tasks.total = 2

		# Stat the file
		if @date
			tasks.complete()
		else
			fs.stat @fullPath, (err,fileStat) =>
				return next?(err)  if err
				@date = new Date(fileStat.ctime)  unless @date
				tasks.complete()

		# Read the file
		fs.readFile @fullPath, (err,data) =>
			return next?(err)  if err
			@parse data.toString(), tasks.completer()
		
		# Chain
		@
	
	# Parse data
	# Parses some data, and loads the meta data and content from it
	# next(err)
	parse: (fileData,next) ->
		# Handle data
		fileData = fileData.replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')
		@fileBody = fileData
		@fileHead = null
		@fileMeta = {}
	
		# Meta Data
		match = /^\s*([\-\#][\-\#][\-\#]+) ?(\w*)\s*/.exec(fileData)
		if match
			# Positions
			seperator = match[1]
			a = match[0].length
			b = fileData.indexOf("\n#{seperator}",a)+1
			c = b+3

			# Parts
			@fileHead = fileData.substring(a,b)
			@fileBody = fileData.substring(c)
			@fileHeadParser = match[2] or 'yaml'

			# Language
			try
				switch @fileHeadParser
					when 'coffee', 'cson'
						coffee = require('coffee-script')  unless coffee
						@fileMeta = coffee.eval @fileHead, filename: @fullPath
					
					when 'yaml'
						yaml = require('yaml')  unless yaml
						@fileMeta = yaml.eval(@fileHead)
					
					else
						@fileMeta = {}
						err = new Error("Unknown meta parser [#{@fileHeadParser}]")
						return next?(err)
			catch err
				return next?(err)
		
		# Update Meta
		@fileMeta or= {}
		@content = @fileBody
		@contentSrc = @fileBody
		@contentRaw = fileData
		@contentRendered = @fileBody
		@title = @title or @basename or @filename
	
		# Correct meta data
		@fileMeta.date = new Date(@fileMeta.date)  if @fileMeta.date? and @fileMeta.date
		
		# Handle urls
		@addUrl @fileMeta.urls  if @fileMeta.urls?
		@addUrl @fileMeta.url  if @fileMeta.url?

		# Apply user meta
		for own key, value of @fileMeta
			@[key] = value
		
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
			for own existingUrl in @urls
				if existingUrl is url
					found = true
					break
			@urls.push(url)  if not found
		
		# Chain
		@

	# Write the rendered file
	# next(err)
	writeRendered: (next) ->
		# Prepare
		filePath = @outPath
		
		# Log
		@logger.log 'debug', "Writing the rendered file #{filePath}"

		# Write data
		fs.writeFile filePath, @contentRendered, (err) =>
			return next?(err)  if err
			
			# Log
			@logger.log 'debug', "Wrote the rendered file #{filePath}"

			# Next
			next?()
		
		# Chain
		@

	
	# Write the file
	# next(err)
	write: (next) ->
		# Prepare
		filePath = @fullPath
		js2coffee = require('js2coffee/lib/js2coffee.coffee')  unless js2coffee
		
		# Log
		@logger.log 'debug', "Writing the file #{filePath}"

		# Prepare data
		fileMetaString = "var a = #{JSON.stringify @fileMeta};"
		@fileHead = js2coffee.build(fileMetaString).replace(/a =\s+|^  /mg,'')
		fileData = "### #{@fileHeadParser}\n#{@fileHead}\n###\n\n" + @fileBody.replace(/^\s+/,'')

		# Write data
		fs.writeFile filePath, fileData, (err) =>
			return next?(err)  if err
			
			# Log
			@logger.log 'info', "Wrote the file #{filePath}"

			# Next
			next?()
		
		# Chain
		@
	
	# Normalize data
	# Normalize any parsing we ahve done, for if a value updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (next) ->
		# Prepare
		@filename = @basename  if !@filename and @basename
		@basename = @filename  if !@basename and @filename
		@fullPath = @basename  if !@fullPath and @basename
		@relativePath = @fullPath  if !@relativePath and @fullPath

		# Names
		@basename = path.basename(@fullPath)
		@filename = @basename
		@basename = @filename.replace(/\..*/, '')

		# Extension
		@extensions = @filename.split /\./g
		@extensions.shift()
		@extension = @extensions[0]

		# Paths
		fullDirPath = path.dirname(@fullPath) or ''
		relativeDirPath = path.dirname(@relativePath).replace(/^\.$/,'') or ''
		@relativeBase = (if relativeDirPath.length then relativeDirPath+'/' else '')+@basename
		@id = @relativeBase

		# Next
		next?()
		@
	
	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (next) ->
		@getEve (err,eve) =>
			return next(err)  if err
			@extensionRendered = eve.extension
			@filenameRendered = "#{@basename}.#{@extensionRendered}"
			@url or= "/#{@relativeBase}.#{@extensionRendered}"
			@slug or= util.generateSlugSync @relativeBase
			@title or= @filenameRendered
			@outPath = if @outDirPath then "#{@outDirPath}/#{@url}" else null
			@addUrl @url
			next?()
		
		# Chain
		@
	
	# Get Layout
	# The the layout object that this file references (if any)
	# next(err,layout)
	getLayout: (next) ->
		# Check
		unless @layout
			return next?(
				new Error('This document does not have a layout')
			)

		# Find parent
		@layouts.findOne {relativeBase:@layout}, (err,layout) =>
			# Check
			if err
				return next?(err)
			else if not layout
				err = new Error "Could not find the layout: #{@layout}"
				return next?(err)
			else
				return next?(null, layout)
	
	# Get Eve
	# Get the most ancestoral layout we have (the very top one)
	# next(err,layout)
	getEve: (next) ->
		if @layout
			@getLayout (err,layout) ->
				return next?(err)  if err
				layout.getEve(next)
		else
			next?(null,@)
	
	# Render
	# Render this file
	# next(err,finalExtension)
	render: (templateData,next) ->
		# Log
		@logger.log 'debug', "Rendering the file #{@relativePath}"

		# Prepare
		@contentRendered = @content
		@content = @contentSrc

		# Async
		tasks = new util.Group (err) =>
			return next?(err)  if err

			# Reset content
			@content = @contentSrc

			# Wrap in layout
			if @layout
				@getLayout (err,layout) =>
					return next?(err)  if err
					templateData.content = @contentRendered
					layout.render templateData, (err) =>
						@contentRendered = layout.contentRendered
						@logger.log 'debug', "Rendering completed for #{@relativePath}"
						next?(err)
			else
				@logger.log 'debug', "Rendering completed for #{@relativePath}"
				next?(err)
		
		# Check tasks
		if @extensions.length <= 1
			# No rendering necessary
			tasks.total = 1
			tasks.complete()
			return
		
		# Clone extensions
		extensions = []
		for extension in @extensions
			extensions.unshift extension

		# Cycle through all the extension groups
		previousExtension = null
		for extension in extensions
			# Has a previous extension
			if previousExtension
				# Event data
				eventData = 
					inExtension: previousExtension
					outExtension: extension
					templateData: templateData
					file: @
				
				# Create a task to run
				tasks.push ((eventData) => =>
					# Render through plugins
					@docpad.triggerPluginEvent 'render', eventData, (err) =>
						# Error?
						if err
							@logger.log 'warn', 'Something went wrong while rendering:', @relativePath
							return tasks.exit(err)

						# Update rendered content
						@contentRendered = @content

						# Complete
						tasks.complete(err)
				
				)(eventData)

			# Cycle
			previousExtension = extension
		
		# Run tasks synchronously
		tasks.sync()

		# Chain
		@

# Export
module.exports = File
