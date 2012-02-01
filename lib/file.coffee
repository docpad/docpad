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
	
	# The file's name without the extension
	basename: null

	# The file's last extension
	# "hello.md.eco" -> "eco"
	extension: null

	# The file's extensions as an array, in reverse order
	# "hello.md.eco" -> ["eco","md"]
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

	# The stages of the content rendering
	# [{layout:String,content:String,extension:String}]
	contentRenderings: []

	# The stages of the content rendering indexed by the layout
	# layoutName: {[content:String,extension:String]}
	contentRenderingsByLayout: {}


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
		@meta = {}
		@contentRenderings = []
		@contentRenderingsByLayout = {}
		@urls = []
		@tags = []
		@relatedDocuments = []

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
		@contentRenderings = []
		@contentRenderingsByLayout = {}
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
		@title = @title or @basename or @filename
	
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
		fullPath = @fullPath
		js2coffee = require('js2coffee/lib/js2coffee.coffee')  unless js2coffee
		
		# Log
		@logger.log 'debug', "Writing the file #{filePath}"

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
		fs.writeFile @fullPath, @data, (err) =>
			return next?(err)  if err
			
			# Log
			@logger.log 'info', "Wrote the file #{fullPath}"

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
		# Prepare
		docpad = @docpad
		logger = @logger
		file = @

		# Log
		logger.log 'debug', "Rendering the file #{@relativePath}"

		# Prepare reset
		reset = ->
			file.rendered = false
			file.content = file.body
			file.contentRendered = file.body
			file.contentRenderedWithoutLayouts = file.body
			file.contentRenderings = [{
				content: file.content
				extension: file.extension
			}]
			file.contentRenderingsByLayout = {
				none: [
					content: file.content
					extension: file.extension
				]
			}

		# Prepare complete
		finish = (err) ->
			# Reset the content to it's original value
			file.content = file.body

			# Error
			return next?(err)  if err
			
			# Log
			logger.log 'debug', "Rendering completed for #{file.relativePath}"
			
			# Success
			file.rendered = true
			return next?()
		
		# Prepare render layouts
		# next(err)
		renderLayouts = (next) ->
			# Store the content without any layout rendering
			file.contentRenderedWithoutLayouts = file.content

			# Skip ahead if we don't have a layout
			return next?()  unless file.layout
			
			# Grab the layout
			file.getLayout (err,layout) ->
				# Error
				return next?(err)  if err

				# Assign the rendered file content to the templateData.content
				templateData.content = file.contentRendered

				# Render the layout with the templateData
				layout.render templateData, (err) ->
					# Error
					return next?(err)  if err

					# Apply the rendering
					file.contentRendered = layout.contentRendered
					for own key,value of layout.contentRenderingsByLayout
						if key is 'none'
							file.contentRenderingsByLayout[layout.relativeBase] = value
						else
							file.contentRenderingsByLayout[key] = value

					# Success
					return next?()
		
		# Prepare render extensions
		# next(err)
		renderExtensions = (next) =>
			# If we only have one extension, then skip ahead to rendering layouts
			return next?()  if file.extensions.length <= 1

			# Prepare the tasks
			tasks = new util.Group next

			# Clone extensions
			extensions = []
			for extension in file.extensions
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
						file: file
					
					# Create a task to run
					tasks.push ((file,eventData) -> ->
						# Render through plugins
						docpad.triggerPluginEvent 'render', eventData, (err) ->
							# Error?
							if err
								logger.log 'warn', 'Something went wrong while rendering:', file.relativePath
								return tasks.exit(err)

							# Update rendered content
							file.contentRendered = file.content
							file.contentRenderings.push(
								content: file.contentRendered
								extension: eventData.outExtension
							)
							file.contentRenderingsByLayout.none.push(
								content: file.contentRendered
								extension: eventData.outExtension
							)

							# Complete
							return tasks.complete(err)
					
					)(file,eventData)

				# Cycle
				previousExtension = extension
			
			# Run tasks synchronously
			return tasks.sync()

		# Reset everything
		reset()

		# Render the extensions, then the layouts, then finish
		renderExtensions (err) ->
			return finish(err)  if err
			renderLayouts (err) ->
				return finish(err)

		# Chain
		@

# Export
module.exports = File
