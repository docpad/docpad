# Requires
balUtil = require('bal-util')
fs = require('fs')
path = require('path')
_ = require('underscore')
EventSystem = balUtil.EventSystem
coffee = null
yaml = null
js2coffee = null


# ---------------------------------
# File Model

class FileModel extends EventSystem


	# ---------------------------------
	# Configuration

	# The available layouts in our DocPad instance
	layouts: null

	# The out directory path to put the file
	outDirPath: null

	# Logger
	logger: null


	# ---------------------------------
	# Automaticly set variables

	# Model Type
	type: 'file'

	# The unique document identifier
	id: null
	
	# The file's name without the extension
	basename: null

	# The file's last extension
	# "hello.md.eco" -> "eco"
	extension: null

	# The file's extensions as an array
	# "hello.md.eco" -> ["md","eco"]
	extensions: []

	# The final extension used for our rendered file
	# Takes into accounts layouts
	# "layout.html", "post.md.eco" -> "html"
	extensionRendered: null

	# The file's name with the extension
	filename: null

	# The file's name with the rendered extension
	filenameRendered: null

	# The full path of our file, only necessary if called by @load
	fullPath: null

	# The final rendered path of our file
	outPath: null

	# The relative path of our source file (with extensions)
	relativePath: null

	# The relative base of our source file (no extension)
	relativeBase: null


	# ---------------------------------
	# Content variables

	# The contents of the file, includes the the meta data (header) and the content (body)
	data: null

	# The file meta data (header) in string format before it has been parsed
	header: null

	# The parser to use for the file's meta data (header)
	parser: null

	# The parsed file meta data (header)
	meta: {}

	# The file content (body) before rendering, excludes the meta data (header)
	body: null

	# The file content (body) during rendering, represents the current state of the content
	content: null

	# Have we been rendered yet?
	rendered: false

	# The rendered content (after it has been wrapped in the layouts)
	contentRendered: false

	# The rendered content (before being passed through the layouts)
	contentRenderedWithoutLayouts: null


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
	constructor: ({@layouts,@logger,@outDirPath,meta}) ->
		# Delete prototype references
		@extensions = []
		@meta = {}
		@urls = []
		@tags = []
		@relatedDocuments = []

		# Copy over meta data
		for own key, value of meta
			@[key] = value
	
	# Get Attributes
	getAttributes: ->
		# Prepare
		attributes = {}
		attributeNames = '''
			id basename extension extensions extensionRendered filename filenameRendered fullPath outPath relativePath relativeBase
			
			data header parser meta body content rendered contentRendered contentRenderedWithoutLayouts

			dynamic title name date slug url urls ignore tags
			'''.split(/\s+/g)
		
		# Discover
		for attributeName in attributeNames
			value = @[attributeName]
			unless typeof value is 'function'
				attributes[attributeName] = value
		
		# Return
		attributes
	
	# Get Simple Attributes
	# Without content references
	getSimpleAttributes: ->
		# Prepare
		attributes = {}
		attributeNames = '''
			id basename extension extensions extensionRendered filename filenameRendered fullPath outPath relativePath relativeBase
			
			parser
			
			dynamic title date slug url urls ignore tags
			'''.split(/\s+/g)
		
		# Discover
		for attributeName in attributeNames
			value = @[attributeName]
			unless typeof value is 'function'
				attributes[attributeName] = value
		
		# Return
		attributes
	
	# To JSON
	toJSON: ->
		@getAttributes()

	# Load
	# If the @fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (next) ->
		# Prepare
		filePath = @relativePath or @fullPath or @filename
		logger = @logger

		# Log
		logger.log 'debug', "Loading the file #{filePath}"
		
		# Handler
		complete = (err) ->
			return next?(err)  if err
			logger.log 'debug', "Loaded the file #{filePath}"
			next?()

		# Exists?
		path.exists @fullPath, (exists) =>
			# Read the file
			if exists
				@read(complete)
			else
				@parse @data, (err) =>
					return next?(err)  if err
					@normalize (err) =>
						return next?(err)  if err
						complete()
		
		# Chain
		@

	# Read
	# Reads in the source file and parses it
	# next(err)
	read: (next) ->
		# Prepare
		logger = @logger

		# Log
		logger.log 'debug', "Reading the file #{@relativePath}"

		# Async
		tasks = new balUtil.Group (err) =>
			if err
				logger.log 'err', "Failed to read the file #{@relativePath}"
				return next?(err)
			else
				@normalize (err) =>
					return next?(err)  if err
					logger.log 'debug', "Read the file #{@relativePath}"
					next?()
		tasks.total = 2

		# Stat the file
		if @date
			tasks.complete()
		else
			balUtil.openFile => fs.stat @fullPath, (err,fileStat) =>
				balUtil.closeFile()
				return next?(err)  if err
				@date = new Date(fileStat.ctime)  unless @date
				tasks.complete()

		# Read the file
		balUtil.openFile => fs.readFile @fullPath, (err,data) =>
			balUtil.closeFile()
			return next?(err)  if err
			@parse data.toString(), tasks.completer()
		
		# Chain
		@
	
	# Parse data
	# Parses some data, and loads the meta data and content from it
	# next(err)
	parse: (fileData,next) ->
		# Prepare
		fileData = (fileData or '').replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')

		# Reset
		@data = fileData
		@header = null
		@parser = null
		@meta = {}
		@body = null
		@content = null
		@rendered = false
		@contentRendered = null
		@contentRenderedWithoutLayouts = null
		@extensionRendered = null
		@filenameRendered = null
	
		# Meta Data
		match = /^\s*([\-\#][\-\#][\-\#]+) ?(\w*)\s*/.exec(@data)
		if match
			# Positions
			seperator = match[1]
			a = match[0].length
			b = @data.indexOf("\n#{seperator}",a)+1
			c = b+3

			# Parts
			@header = @data.substring(a,b)
			@body = @data.substring(c)
			@parser = match[2] or 'yaml'

			# Language
			try
				switch @parser
					when 'coffee', 'cson'
						coffee = require('coffee-script')  unless coffee
						@meta = coffee.eval @header, filename: @fullPath
					
					when 'yaml'
						yaml = require('yaml')  unless yaml
						@meta = yaml.eval(@header)
					
					else
						@meta = {}
						err = new Error("Unknown meta parser [#{@parser}]")
						return next?(err)
			catch err
				return next?(err)
		else
			@body = @data
		
		# Update meta data
		@body = @body.replace(/^\n+/,'')
		@meta or= {}
		@content = @body
		@name = @name or @title or @basename
	
		# Correct meta data
		@meta.date = new Date(@meta.date)  if @meta.date? and @meta.date
		
		# Handle urls
		@addUrl @meta.urls  if @meta.urls?
		@addUrl @meta.url  if @meta.url?

		# Apply user meta
		for own key, value of @meta
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
		logger = @logger
		
		# Log
		logger.log 'debug', "Writing the rendered file #{filePath}"

		# Write data
		balUtil.openFile => fs.writeFile filePath, @contentRendered, (err) =>
			balUtil.closeFile()
			return next?(err)  if err
			
			# Log
			logger.log 'debug', "Wrote the rendered file #{filePath}"

			# Next
			next?()
		
		# Chain
		@

	
	# Write the file
	# next(err)
	write: (next) ->
		# Prepare
		fullPath = @fullPath
		logger = @logger
		js2coffee = require(path.join 'js2coffee', 'lib', 'js2coffee.coffee')  unless js2coffee
		
		# Log
		logger.log 'debug', "Writing the file #{filePath}"

		# Prepare data
		header = 'var a = '+JSON.stringify(@meta)
		header = js2coffee.build(header).replace(/a =\s+|^  /mg,'')
		body = @body.replace(/^\s+/,'')
		data = "### #{@parser}\n#{header}\n###\n\n#{body}"

		# Apply
		@header = header
		@body = body
		@data = data

		# Write data
		balUtil.openFile => fs.writeFile @fullPath, @data, (err) =>
			balUtil.closeFile()
			return next?(err)  if err
			
			# Log
			logger.log 'info', "Wrote the file #{fullPath}"

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
		@extension = @extensions[@extensions.length-1]
		@extensionRendered = @extensions[0]

		# Paths
		fullDirPath = path.dirname(@fullPath) or ''
		relativeDirPath = path.dirname(@relativePath).replace(/^\.$/,'') or ''
		@relativeBase =
			if relativeDirPath.length
				path.join relativeDirPath, @basename
			else
				@basename
		@id = @relativeBase

		# Next
		next?()
		@
	
	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (next) ->
		@getEve (err,eve) =>
			return next?(err)  if err
			@extensionRendered = eve.extensionRendered
			@filenameRendered = "#{@basename}.#{@extensionRendered}"
			@url or= "/#{@relativeBase}.#{@extensionRendered}"
			@slug or= balUtil.generateSlugSync @relativeBase
			@name or= @filenameRendered
			@outPath = if @outDirPath then path.join(@outDirPath,@url) else null
			@addUrl @url
			next?()
		
		# Chain
		@
	
	# Get Layout
	# The the layout object that this file references (if any)
	# next(err,layout)
	getLayout: (next) ->
		# Prepare
		layoutName = @layout

		# Check
		unless layoutName
			return next?(
				new Error('This document does not have a layout')
			)

		# Find parent
		@layouts.findOne {relativeBase:layoutName}, (err,layout) ->
			# Check
			if err
				return next?(err)
			else if not layout
				err = new Error "Could not find the layout: #{layoutName}"
				return next?(err)
			else
				return next?(null, layout)

		# Chain
		@
	
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
	# next(err,result)
	render: (templateData,next) ->
		# Prepare
		file = @
		logger = @logger

		# Log
		logger.log 'debug', "Rendering the file #{@relativePath}"

		# Prepare reset
		reset = ->
			file.rendered = false
			file.content = file.body
			file.contentRendered = file.body
			file.contentRenderedWithoutLayouts = file.body

		# Reset everything
		reset()
		rendering = file.body

		# Prepare complete
		finish = (err) ->
			# Apply rendering if we are a document
			if file.type in ['document','partial']
				file.content = file.body
				file.contentRendered = rendering
				file.rendered = true

			# Error
			return next(err)  if err
			
			# Log
			logger.log 'debug', "Rendering completed for #{file.relativePath}"
			
			# Success
			return next(null,rendering)
		

		# Render plugins
		# next(err)
		renderPlugins = (file,eventData,next) =>
			# Render through plugins
			file.emitSync eventData.name, eventData, (err) ->
				# Error?
				if err
					logger.log 'warn', 'Something went wrong while rendering:', file.relativePath
					return next(err)
				# Forward
				return next(err)

		# Prepare render layouts
		# next(err)
		renderLayouts = (next) ->
			# Skip ahead if we don't have a layout
			return next()  unless file.layout
			
			# Grab the layout
			file.getLayout (err,layout) ->
				# Error
				return next(err)  if err

				# Apply rendering without layouts if we are a document
				if file.type in ['document','partial']
					file.contentRenderedWithoutLayouts = rendering

				# Check if we have a layout
				if layout
					# Assign the current rendering to the templateData.content
					templateData.content = rendering

					# Render the layout with the templateData
					layout.render templateData, (err,result) ->
						return next(err)  if err
						rendering = result
						return next()
				
				# We don't have a layout, nothing to do here
				else
					return next()

		# Render the document
		# next(err)
		renderDocument = (next) ->
			# Prepare event data
			eventData =
				name: 'renderDocument'
				extension: file.extensions[0]
				templateData: templateData
				file: file
				content: rendering

			# Render via plugins
			renderPlugins file, eventData, (err) ->
				return next(err)  if err
				rendering = eventData.content
				return next()

		# Render extensions
		# next(err)
		renderExtensions = (next) ->
			# If we only have one extension, then skip ahead to rendering layouts
			return next()  if file.extensions.length <= 1

			# Prepare the tasks
			tasks = new balUtil.Group(next)

			# Clone extensions
			extensions = []
			for extension in file.extensions
				extensions.unshift extension

			# Cycle through all the extension groups
			_.each extensions[1..], (extension,index) ->
				# Render through the plugins
				tasks.push (complete) ->
					# Prepare
					eventData = 
						name: 'render'
						inExtension: extensions[index]
						outExtension: extension
						templateData: templateData
						file: file
						content: rendering

					# Render
					renderPlugins file, eventData, (err) ->
						return complete(err)  if err
						rendering = eventData.content
						return complete()

			# Run tasks synchronously
			return tasks.sync()

		# Render the extensions
		renderExtensions (err) ->
			return finish(err)  if err
			# Then the document
			renderDocument (err) ->
				return finish(err)  if err
				# Then the layouts
				renderLayouts (err) ->
					return finish(err)

		# Chain
		@

# Export
module.exports = FileModel
