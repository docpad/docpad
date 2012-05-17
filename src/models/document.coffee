# Necessary
pathUtil = require('path')
balUtil = require('bal-util')
_ = require('underscore')
mime = require('mime')

# Optional
CSON = null
yaml = null

# Local
{Model} = require(__dirname+'/../base')
FileModel = require(__dirname+'/file')


# ---------------------------------
# Document Model

class DocumentModel extends FileModel

	# Model Type
	type: 'document'

	# The parsed file meta data (header)
	# Is a Backbone.Model instance
	meta: null


	# ---------------------------------
	# Attributes

	defaults:

		# ---------------------------------
		# Automaticly set variables

		# The final extension used for our rendered file
		# Takes into accounts layouts
		# "layout.html", "post.md.eco" -> "html"
		extensionRendered: null

		# The file's name with the rendered extension
		filenameRendered: null

		# The MIME content-type for the out document
		contentTypeRendered: null


		# ---------------------------------
		# Content variables

		# The file meta data (header) in string format before it has been parsed
		header: null

		# The parser to use for the file's meta data (header)
		parser: null

		# The file content (body) before rendering, excludes the meta data (header)
		body: null

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

		# The tags for this document
		tags: null  # Array


	# ---------------------------------
	# Functions

	# Initialize
	initialize: (data,options) ->
		# Prepare
		{@layouts,meta} = options

		# Apply meta
		@meta = new Model()
		@meta.set(meta)  if meta

		# Forward
		super

	# Get Meta
	getMeta: ->
		return @meta

	# To JSON
	toJSON: ->
		data = super
		data.meta = @getMeta().toJSON()
		return data

	# Parse data
	# Parses some data, and loads the meta data and content from it
	# next(err)
	parseData: (data,next) ->
		# Reset
		@layout = null
		@getMeta().clear()

		# Super
		super data, =>
			# Content
			content = @get('content')

			# Meta Data
			match = /^\s*([\-\#][\-\#][\-\#]+) ?(\w*)\s*/.exec(content)
			if match
				# Positions
				seperator = match[1]
				a = match[0].length
				b = content.indexOf("\n#{seperator}",a)+1
				c = b+3

				# Parts
				fullPath = @get('fullPath')
				header = content.substring(a,b)
				body = content.substring(c)
				parser = match[2] or 'yaml'

				# Language
				try
					switch parser
						when 'coffee', 'cson'
							CSON = require('cson')  unless CSON
							meta = CSON.parseSync(header)
							@meta.set(meta)

						when 'yaml'
							yaml = require('yaml')  unless yaml
							meta = yaml.eval(header)
							@meta.set(meta)

						else
							err = new Error("Unknown meta parser: #{parser}")
							return next?(err)
				catch err
					return next?(err)
			else
				body = content

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
			ignored = @meta.get('ignored') or @meta.get('ignore') or @meta.get('skip') or @meta.get('draft') or (@meta.get('published') is false)
			@meta.set({ignored:true})  if ignored

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

	# Write the rendered file
	# next(err)
	writeRendered: (next) ->
		# Prepare
		fileOutPath = @get('outPath')
		contentRendered = @get('contentRendered')
		logger = @logger

		# Log
		logger.log 'debug', "Writing the rendered file: #{fileOutPath}"

		# Write data
		balUtil.writeFile fileOutPath, contentRendered, (err) ->
			# Check
			return next?(err)  if err

			# Log
			logger.log 'debug', "Wrote the rendered file: #{fileOutPath}"

			# Next
			next?()

		# Chain
		@

	# Write the file
	# next(err)
	writeSource: (next) ->
		# Prepare
		logger = @logger
		CSON = require('cson')  unless CSON

		# Fetch
		fullPath = @get('fullPath')
		relativePath = @get('relativePath')
		content = @get('content')
		body = @get('body')
		parser = @get('parser')

		# Log
		logger.log 'debug', "Writing the source file: #{relativePath}"

		# Adjust
		header = CSON.stringifySync(@meta.toJSON())
		body = body.replace(/^\s+/,'')
		content = "### #{parser}\n#{header}\n###\n\n#{body}"

		# Apply
		@set({header,body,content})

		# Write content
		balUtil.writeFile fileOutPath, content, (err) ->
			# Check
			return next?(err)  if err

			# Log
			logger.log 'info', "Wrote the source file: #{relativePath}"

			# Next
			next?()

		# Chain
		@

	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (next) ->
		# Super
		super =>
			# Extract
			extensions = @get('extensions')

			# Rendered
			extensionRendered = if extensions.length then extensions[0] else null

			# Apply
			@set({extensionRendered})

			# Next
			next?()

		# Chain
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (next) ->
		# Super
		super =>
			# Get our highest ancestor
			@getEve (err,eve) =>
				# Check
				return next?(err)  if err

				# Fetch
				meta = @getMeta()
				fullPath = @get('fullPath')
				basename = @get('basename')
				relativeBase = @get('relativeBase')
				extensions = @get('extensions')
				extensionRendered = @get('extensionRendered')
				url = meta.get('url') or null
				slug = meta.get('slug') or null
				name = meta.get('name') or null
				outPath = meta.get('outPath') or null

				# Adjust
				extensionRendered = eve.get('extensionRendered')  if eve
				filenameRendered = if extensionRendered then "#{basename}.#{extensionRendered}" else "#{basename}"
				url or= if extensionRendered then "/#{relativeBase}.#{extensionRendered}" else "/#{relativeBase}"
				slug or= @get('slug')
				name or= filenameRendered
				outPath or= if @outDirPath then pathUtil.join(@outDirPath,url) else null
				@addUrl(url)
				@removeUrl(if extensions.length then "/#{relativeBase}.#{extensions.join('.')}" else "/#{relativeBase}")

				# Content Types
				contentTypeRendered = mime.lookup(outPath or fullPath)

				# Apply
				@set({extensionRendered,filenameRendered,url,slug,name,outPath,contentTypeRendered})

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

		# No layout
		unless layoutId
			return next?(null,null)

		# Cached layout
		else if @layout and layoutId is @layout.id
			return next?(null,@layout)

		# Uncached layout
		else
			# Find parent
			layout = @layouts.findOne {id: layoutId}
			# Error
			if err
				return next?(err)
			# Not Found
			else unless layout
				debugger
				err = new Error "Could not find the specified layout: #{layoutId}"
				return next?(err)
			# Found
			else
				#file.layout = layout
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
					return next?(err,null)
				else
					layout.getEve(next)
		else
			next?(null,@)
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
		logger.log 'debug', "Rendering the file: #{relativePath}"

		# Prepare reset
		reset = ->
			file.set(
				rendered: false
				contentRendered: body
				contentRenderedWithoutLayouts: body
			)
			rendering = body

		# Reset everything
		reset()

		# Prepare complete
		finish = (err) ->
			# Apply rendering if we are a document
			file.set(
				contentRendered: rendering
				rendered: true
			)

			# Error
			return next(err)  if err

			# Log
			logger.log 'debug', 'Rendering completed for:', file.get('relativePath')

			# Success
			return next(null,rendering)


		# Render plugins
		# next(err)
		renderPlugins = (eventData,next) =>
			# Render through plugins
			file.trigger eventData.name, eventData, (err) ->
				# Error?
				if err
					logger.log 'warn', 'Something went wrong while rendering:', file.get('relativePath')
					return next(err)
				# Forward
				return next(err)

		# Prepare render layouts
		# next(err)
		renderLayouts = (next) ->
			# Apply rendering without layouts if we are a document
			file.set(
				contentRenderedWithoutLayouts: rendering
			)

			# Grab the layout
			file.getLayout (err,layout) ->
				# Check
				return next(err)  if err

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
module.exports = DocumentModel
