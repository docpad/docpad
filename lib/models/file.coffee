# Requires
path = require('path')
balUtil = require('bal-util')
fs = require('fs')
_ = require('underscore')
Backbone = require('backbone')

# Optionals
coffee = null
yaml = null
js2coffee = null

# Base Model
BaseModel = require(path.join __dirname, 'base.coffee')


# ---------------------------------
# File Model

FileModel = BaseModel.extend
#class FileModel extends BaseModel

	# ---------------------------------
	# Properties

	# The out directory path to put the file
	outDirPath: null

	# The available layouts in our DocPad instance
	layouts: null

	# Model Type
	type: 'file'

	# Logger
	logger: null

	# Layout
	layout: null

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

		# The file's extensions as an array
		# "hello.md.eco" -> ["md","eco"]
		extensions: null  # Array

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
		urls: null  # Array

		# Whether or not we ignore this document (do not render it)
		ignore: false

		# The tags for this document
		tags: null  # Array


	# ---------------------------------
	# Functions

	# Initialize
	initialize: (data,options) ->
		# Prepare
		{@layouts,@logger,@outDirPath,meta} = options

		# Apply meta
		@meta = new Backbone.Model()
		@meta.set(meta)  if meta

		# Advanced attributes
		@set(
			extensions: []
			urls: []
			tags: []
		)

	# Get Attributes
	getAttributes: ->
		return @toJSON()

	# Get Meta
	getMeta: ->
		return @meta
	
	# To JSON
	toJSON: ->
		data = Backbone.Model::toJSON.call(@)
		data.meta = @getMeta().toJSON()
		return data

	# Load
	# If the @fullPath exists, load the file
	# If it doesn't, then parse and normalize the file
	load: (next) ->
		# Prepare
		filePath = @get('relativePath') or @get('fullPath') or @get('filename')
		fullPath = @get('fullPath')
		data = @get('data')
		logger = @logger

		# Log
		logger.log('debug', "Loading the file #{filePath}")
		
		# Handler
		complete = (err) ->
			return next?(err)  if err
			logger.log('debug', "Loaded the file #{filePath}")
			next?()

		# Exists?
		path.exists fullPath, (exists) =>
			# Read the file
			if exists
				@read(complete)
			else
				@parse data, (err) =>
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
		file = @
		date = @get('date')
		fullPath = @get('fullPath')

		# Log
		logger.log('debug', "Reading the file #{@relativePath}")

		# Async
		tasks = new balUtil.Group (err) =>
			if err
				logger.log('err', "Failed to read the file #{@relativePath}")
				return next?(err)
			else
				@normalize (err) =>
					return next?(err)  if err
					logger.log('debug', "Read the file #{@relativePath}")
					next?()
		tasks.total = 2

		# Stat the file
		if date
			tasks.complete()
		else
			balUtil.openFile -> fs.stat fullPath, (err,fileStat) ->
				balUtil.closeFile()
				return next?(err)  if err
				unless date
					date = new Date(fileStat.ctime)
					file.set({date})
				tasks.complete()

		# Read the file
		balUtil.openFile -> fs.readFile fullPath, (err,data) ->
			balUtil.closeFile()
			return next?(err)  if err
			file.parse(data.toString(), tasks.completer())
		
		# Chain
		@
	
	# Parse data
	# Parses some data, and loads the meta data and content from it
	# next(err)
	parse: (fileData,next) ->
		# Prepare
		data = (fileData or '').replace(/\r\n?/gm,'\n').replace(/\t/g,'    ')

		# Reset
		@meta = new Backbone.Model()
		@layout = null
		@set(
			data: fileData
			header: null
			parser: null
			body: null
			content: null
			rendered: false
			contentRendered: null
			contentRenderedWithoutLayouts: null
			extensionRendered: null
			filenameRendered: null
		)
	
		# Meta Data
		match = /^\s*([\-\#][\-\#][\-\#]+) ?(\w*)\s*/.exec(data)
		if match
			# Positions
			seperator = match[1]
			a = match[0].length
			b = data.indexOf("\n#{seperator}",a)+1
			c = b+3

			# Parts
			fullPath = @get('fullPath')
			header = data.substring(a,b)
			body = data.substring(c)
			parser = match[2] or 'yaml'

			# Language
			try
				switch parser
					when 'coffee', 'cson'
						coffee = require('coffee-script')  unless coffee
						meta = coffee.eval(header, {filename:fullPath})
						@meta.set(meta)
					
					when 'yaml'
						yaml = require('yaml')  unless yaml
						meta = yaml.eval(header)
						@meta.set(meta)
					
					else
						err = new Error("Unknown meta parser [#{parser}]")
						return next?(err)
			catch err
				return next?(err)
		else
			body = data
		
		# Update meta data
		body = body.replace(/^\n+/,'')
		@set(
			header: header
			body: body
			parser: parser
			content: body
			name: @get('name') or @get('title') or @get('basename')
		)
	
		# Correct data format
		metaDate = @meta.get('date')
		if metaDate
			metaDate = new Date(metaDate)
			@meta.set({date:metaDate})

		# Correct ignore
		ignore = @meta.get('ignore') or @meta.get('ignored') or @meta.get('skip') or @meta.get('published') is false or @meta.get('draft') is true
		@meta.set({ignore})  if ignore

		# Handle urls
		metaUrls = @meta.get('urls')
		metaUrl = @meta.get('url')
		@addUrl(metaUrls)  if metaUrls
		@addUrl(metaUrl)   if metaUrl

		# Apply meta to us
		@set(@meta.toJSON())
		
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

	# Write the rendered file
	# next(err)
	writeRendered: (next) ->
		# Prepare
		fileOutPath = @get('outPath')
		contentRendered = @get('contentRendered')
		logger = @logger
		
		# Log
		logger.log 'debug', "Writing the rendered file #{fileOutPath}"

		# Write data
		balUtil.openFile -> fs.writeFile fileOutPath, contentRendered, (err) ->
			balUtil.closeFile()
			return next?(err)  if err
			
			# Log
			logger.log 'debug', "Wrote the rendered file #{fileOutPath}"

			# Next
			next?()
		
		# Chain
		@

	
	# Write the file
	# next(err)
	write: (next) ->
		# Prepare
		logger = @logger
		js2coffee = require(path.join 'js2coffee', 'lib', 'js2coffee.coffee')  unless js2coffee
		
		# Fetch
		fullPath = @get('fullPath')
		data = @get('data')
		body = @get('body')
		parser = @get('parser')

		# Log
		logger.log 'debug', "Writing the file #{filePath}"

		# Adjust
		header = 'var a = '+JSON.stringify(@meta.toJSON())
		header = js2coffee.build(header).replace(/a =\s+|^  /mg,'')
		body = body.replace(/^\s+/,'')
		data = "### #{parser}\n#{header}\n###\n\n#{body}"

		# Apply
		@set({header,body,data})

		# Write data
		balUtil.openFile -> fs.writeFile fullPath, data, (err) ->
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
		basename = @get('basename')
		filename = @get('filename')
		fullPath = @get('fullPath')
		relativePath = @get('relativePath')
		id = @get('id')

		# Adjust
		fullPath or= filename
		relativePath or= fullPath

		# Names
		basename = path.basename(fullPath)
		filename = basename
		basename = filename.replace(/\..*/, '')

		# Extension
		extensions = filename.split(/\./g)
		extensions.shift()
		extension = extensions[extensions.length-1]
		extensionRendered = extensions[0]

		# Paths
		fullDirPath = path.dirname(fullPath) or ''
		relativeDirPath = path.dirname(relativePath).replace(/^\.$/,'') or ''
		relativeBase =
			if relativeDirPath.length
				path.join(relativeDirPath, basename)
			else
				basename
		id or= relativeBase

		# Apply
		@set({basename,filename,fullPath,relativePath,id,relativeBase,extensions,extension,extensionRendered})

		# Next
		next?()
		@
	
	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (next) ->
		@getEve (err,eve) =>
			return next?(err)  if err
			
			# Fetch
			basename = @get('basename')
			relativeBase = @get('relativeBase')
			extensionRendered = @get('extensionRendered')
			filenameRendered = @get('filenameRendered')
			url = @get('url')
			name = @get('name')
			slug = @get('slug')

			# Adjust
			extensionRendered = eve.get('extensionRendered')  if eve
			filenameRendered = "#{basename}.#{extensionRendered}"
			url or= "/#{relativeBase}.#{extensionRendered}"
			slug or= balUtil.generateSlugSync(relativeBase)
			name or= filenameRendered
			outPath = if @outDirPath then path.join(@outDirPath,url) else null
			@addUrl(url)

			# Apply
			@set({extensionRendered,filenameRendered,url,slug,name,outPath})

			# Forward
			next?()
		
		# Chain
		@

	# Has Layout
	# Checks if the file has a layout
	hasLayout: ->
		return @get('layout')?
	
	# Get Layout
	# The the layout object that this file references (if any)
	# next(err,layout)
	getLayout: (next) ->
		# Prepare
		file = @
		layoutId = @get('layout')

		# No layout id
		unless layoutId
			err = new Error('This document does not have a layout')
			next?(err)
		
		# Cached layout
		else if @layout and layoutId is @layout.id
			# Already got it
			next?(null,@layout)
		
		# Uncached layout
		else
			# Find parent
			layout = @layouts.findOne {id:layoutId}
			# Check
			if err
				return next?(err)
			else unless layout
				err = new Error "Could not find the layout: #{layoutId}"
				return next?(err)
			else
				file.layout = layout
				return next?(null,layout)

		# Chain
		@
	
	# Get Eve
	# Get the most ancestoral layout we have (the very top one)
	# next(err,layout)
	getEve: (next) ->
		if @hasLayout()
			@getLayout (err,layout) ->
				if err
					return next?(err)
				else
					layout.getEve(next)
		else
			next?()
		@
	
	# Render
	# Render this file
	# next(err,result)
	render: (templateData,next) ->
		# Prepare
		file = @
		logger = @logger
		rendering = null

		# Fetch
		relativePath = @get('relativePath')
		body = @get('body')
		extensions = @get('extensions')
		extensionsReversed = []
		
		# Reverse extensions
		for extension in extensions
			extensionsReversed.unshift(extension)


		# Log
		logger.log 'debug', "Rendering the file #{relativePath}"

		# Prepare reset
		reset = ->
			file.set(
				rendered: false
				content: body
				contentRendered: body
				contentRenderedWithoutLayouts: body
			)
			rendering = body

		# Reset everything
		reset()

		# Prepare complete
		finish = (err) ->
			# Apply rendering if we are a document
			if file.type in ['document','partial']
				file.set(
					content: body
					contentRendered: rendering
					rendered: true
				)

			# Error
			return next(err)  if err
			
			# Log
			logger.log 'debug', 'Rendering completed for', file.get('relativePath')
			
			# Success
			return next(null,rendering)
		

		# Render plugins
		# next(err)
		renderPlugins = (eventData,next) =>
			# Render through plugins
			file.emitSync eventData.name, eventData, (err) ->
				# Error?
				if err
					logger.log 'warn', 'Something went wrong while rendering:', file.get('relativePath')
					return next(err)
				# Forward
				return next(err)

		# Prepare render layouts
		# next(err)
		renderLayouts = (next) ->
			# Skip ahead if we don't have a layout
			return next()  unless file.hasLayout()
			
			# Grab the layout
			file.getLayout (err,layout) ->
				# Error
				return next(err)  if err

				# Apply rendering without layouts if we are a document
				if file.type in ['document','partial']
					file.set(
						contentRenderedWithoutLayouts: rendering
					)

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
				extension: extensions[0]
				templateData: templateData
				file: file
				content: rendering

			# Render via plugins
			renderPlugins eventData, (err) ->
				return next(err)  if err
				rendering = eventData.content
				return next()

		# Render extensions
		# next(err)
		renderExtensions = (next) ->
			# If we only have one extension, then skip ahead to rendering layouts
			return next()  if extensions.length <= 1

			# Prepare the tasks
			tasks = new balUtil.Group(next)

			# Cycle through all the extension groups
			_.each extensionsReversed[1..], (extension,index) ->
				# Render through the plugins
				tasks.push (complete) ->
					# Prepare
					eventData = 
						name: 'render'
						inExtension: extensionsReversed[index]
						outExtension: extension
						templateData: templateData
						file: file
						content: rendering

					# Render
					renderPlugins eventData, (err) ->
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
