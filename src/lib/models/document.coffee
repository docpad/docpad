# Necessary
pathUtil = require('path')
balUtil = require('bal-util')
_ = require('underscore')
mime = require('mime')

# Optional
CSON = null
YAML = null

# Local
FileModel = require(__dirname+'/file')


# ---------------------------------
# Document Model

class DocumentModel extends FileModel

	# Model Type
	type: 'document'


	# ---------------------------------
	# Attributes

	defaults:

		# ---------------------------------
		# Special variables

		# outExtension
		# The final extension used for our file
		# Takes into accounts layouts
		# "layout.html", "post.md.eco" -> "html"
		# already defined in file.coffee

		# Whether or not we reference other doucments
		referencesOthers: false


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
		contentRendered: null

		# The rendered content (before being passed through the layouts)
		contentRenderedWithoutLayouts: null


		# ---------------------------------
		# User set variables

		# Whether or not this file should be re-rendered on each request
		dynamic: false

		# The tags for this document
		tags: null  # Array

		# Whether or not we want to render single extensions
		renderSingleExtensions: false


	# ---------------------------------
	# Functions

	# Initialize
	initialize: (attrs,opts) ->
		# Prepare
		{meta} = opts

		# Forward
		super

	# Get Meta
	getMeta: ->
		return @meta

	# Prepare
	getOutContent: (next) ->
		outContent = @get('contentRendered')
		if outContent
			next(null,outContent)
		else
			@getContent(next)
		@

	# Clean
	# Wipe any unnecessary data
	clean: (next) ->
		###
		@set({
			header: null
			parser: null
			body: null
			rendered: false
			contentRendered: null
			contentRenderedWithoutLayouts: null
		})
		###
		super
		@

	# To JSON
	toJSON: ->
		data = super
		data.meta = @getMeta().toJSON()
		return data

	# References Others
	referencesOthers: (flag) ->
		flag ?= true
		@set({referencesOthers:flag})
		@

	# Parse
	# Parse our buffer and extract meaningful data from it
	# next(err)
	parse: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		buffer = @buffer
		meta = @getMeta()

		# Wipe any meta attributes that we've copied over to our file
		reset = {}
		for own key,value of meta.attributes
			reset[key] = @defaults[key]
		reset = balUtil.dereference(reset)
		@set(reset)

		# Then wipe the layout and clear the meta attributes from the meta model
		@layout = null
		meta.clear()

		# Reparse the data and extract the content
		# With the content, fetch the new meta data, header, and body
		super buffer, =>
			# Content
			content = @get('content')

			# Meta Data
			match = /^\s*([^\s\d\w]{3,})(?: *([a-z]+))?([\s\S]*?)\1/.exec(content)
			if match
				# Extract
				seperator = match[1]
				parser = match[2] or 'yaml'
				header = match[3].trim()
				body = content.substring(match[0].length).trim()

				# Parse
				try
					switch parser
						when 'cson', 'coffee', 'coffeescript', 'coffee-script'
							CSON = require('cson')  unless CSON
							meta = CSON.parseSync(header)
							@meta.set(meta)

						when 'yaml'
							YAML = require('yamljs')  unless YAML
							meta = YAML.parse(header)
							@meta.set(meta)

						else
							err = new Error("Unknown meta parser: #{parser}")
							return next(err)
				catch err
					return next(err)
			else
				body = content

			# Update meta data
			body = body.replace(/^\n+/,'')
			@set(
				source: content
				content: body
				header: header
				body: body
				parser: parser
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
			next()

		# Chain
		@

	# Write the rendered file
	# next(err)
	writeRendered: (next) ->
		# Prepare
		file = @
		@getOutContent (err,contentRendered) =>
			# Prepare
			return next(err)  if err
			fileOutPath = @get('outPath')
			encoding = @get('encoding')

			# Log
			file.log 'debug', "Writing the rendered file: #{fileOutPath} #{encoding}"

			# Write data
			balUtil.writeFile fileOutPath, contentRendered, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'debug', "Wrote the rendered file: #{fileOutPath} #{encoding}"

				# Next
				return next()

		# Chain
		@

	# Write the file
	# next(err)
	writeSource: (next) ->
		# Prepare
		file = @
		CSON = require('cson')  unless CSON

		# Fetch
		@getContent (err,content) =>
			# Prepare
			return next(err)  if err
			fullPath = @get('fullPath')
			content = @get('content')
			parser = 'cson'
			seperator = '---'

			# Log
			file.log 'debug', "Writing the source file: #{fullPath}"

			# Adjust
			header = CSON.stringifySync(@meta.toJSON())
			content = body = content.replace(/^\s+/,'')
			source = "#{seperator} #{parser}\n#{header}\n#{seperator}\n\n#{body}"

			# Apply
			@set({parser,header,body,content,source})

			# Write content
			balUtil.writeFile fileOutPath, source, (err) ->
				# Check
				return next(err)  if err

				# Log
				file.log 'info', "Wrote the source file: #{fullPath}"

				# Next
				next()

		# Chain
		@

	# Normalize data
	# Normalize any parsing we have done, as if a value has updates it may have consequences on another value. This will ensure everything is okay.
	# next(err)
	normalize: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)

		# Super
		super =>
			# Extract
			extensions = @get('extensions')

			# Extension Rendered
			if extensions? and extensions.length
				outExtension = extensions[0]
				@set({outExtension})

			# Next
			next()

		# Chain
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)

		# Super
		super =>
			# Get our highest ancestor
			@getEve (err,eve) =>
				# Check
				return next(err)  if err

				# Prepare
				changes = {}

				# Fetch
				meta = @getMeta()
				fullPath = @get('fullPath')
				basename = @get('basename')
				relativeDirPath = @get('relativeDirPath')
				extensions = @get('extensions')
				outExtension = @get('outExtension')
				url = meta.get('url') or null
				name = meta.get('name') or null
				outPath = meta.get('outPath') or null
				outFilename = null

				# Use our eve's rendered extension if it exists
				if eve?
					outExtension = eve.get('outExtension')

				# Figure out the rendered filename
				if basename and outExtension
					if basename[0] is '.' and outExtension is extensions[0]
						outFilename = basename
					else
						outFilename = "#{basename}.#{outExtension}"
					changes.outFilename = outFilename

				# Figure out the rendered url
				if outFilename
					if relativeDirPath
						relativeOutPath = "#{relativeDirPath}/#{outFilename}"
					else
						relativeOutPath = "#{outFilename}"
					changes.relativeOutPath = relativeOutPath
					unless url
						changes.url = url = "/#{relativeOutPath}"

				# Set name if it doesn't exist already
				if !name and outFilename?
					changes.name = name = outFilename

				# Create the outPath if we have a outpute directory
				if @outDirPath
					changes.outPath = outPath = pathUtil.join(@outDirPath,relativeOutPath)

				# Update the URL
				if url
					@removeUrl(@get('url'))
					@setUrl(url)

				# Content Types
				if outPath or fullPath
					changes.outContentType = outContentType = mime.lookup(outPath or fullPath)

				# Apply
				@set(changes)

				# Forward
				next()

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
			return next(null,null)

		# Cached layout
		else if @layout and layoutId is @layout.id
			# Forward
			return next(null,@layout)

		# Uncached layout
		else
			# Find parent
			@emit 'getLayout', {layoutId}, (err,opts) ->
				# Prepare
				{layout} = opts

				# Error
				if err
					return next(err)
				# Not Found
				else unless layout
					err = new Error "Could not find the specified layout: #{layoutId}"
					return next(err)
				# Found
				else
					# Update our layout id with the definitive correct one
					file.set('layout': layout.id)

					# Cache our layout
					file.layout = layout

					# Forward
					return next(null,layout)

		# Chain
		@

	# Get Eve
	# Get the most ancestoral layout we have (the very top one)
	# next(err,layout)
	getEve: (next) ->
		if @hasLayout()
			@getLayout (err,layout) ->
				if err
					return next(err,null)
				else
					layout.getEve(next)
		else
			next(null,@)
		@


	# Render extensions
	# next(err,result)
	renderExtensions: (opts,next) ->
		# Prepare
		file = @
		extensions = @get('extensions')
		filename = @get('filename')
		{content,templateData,renderSingleExtensions} = opts
		content ?= @get('body')
		templateData ?= {}
		renderSingleExtensions ?= @get('renderSingleExtensions')

		# Prepare result
		result = content

		# Prepare extensions
		extensionsReversed = []
		if extensions.length is 0 and filename
			extensionsReversed.push(filename)
		for extension in extensions
			extensionsReversed.unshift(extension)

		# If we want to allow rendering of single extensions, then add null to the extension list
		if renderSingleExtensions and extensionsReversed.length is 1
			if renderSingleExtensions isnt 'auto' or filename.replace(/^\./,'') is extensionsReversed[0]
				extensionsReversed.push(null)

		# If we only have one extension, then skip ahead to rendering layouts
		return next(null,result)  if extensionsReversed.length <= 1

		# Prepare the tasks
		tasks = new balUtil.Group (err) ->
			# Forward with result
			return next(err,result)

		# Cycle through all the extension groups and render them
		for extension,index in extensionsReversed[1..]
			# Push the task
			context =
				inExtension: extensionsReversed[index]
				outExtension: extension
			tasks.push context, (complete) ->
				# Prepare
				eventData =
					inExtension: @inExtension
					outExtension: @outExtension
					templateData: templateData
					file: file
					content: result

				# Render
				file.trigger 'render', eventData, (err) ->
					# Check
					return complete(err)  if err

					# Check if the render did anything
					# and only check if we actually have content to render!
					# if this check fails, error with a suggestion
					if result and result is eventData.content
						message = "\n  Rendering the extension \"#{eventData.inExtension}\" to \"#{eventData.outExtension}\" on \"#{file.attributes.relativePath or file.attributes.fullPath}\" didn't do anything.\n  Explanation here: http://docpad.org/extension-not-rendering"
						file.log('warn', message)
						return complete()

					# The render did something, so apply and continue
					result = eventData.content
					return complete()

		# Run tasks synchronously
		tasks.sync()

		# Chain
		@


	# Render Document
	# next(err,result)
	renderDocument: (opts,next) ->
		# Prepare
		file = @
		extension = @get('extensions')[0]
		{opts,next} = @getActionArgs(opts,next)
		{content,templateData} = opts
		content ?= @get('body')
		templateData ?= {}

		# Prepare event data
		eventData = {extension,templateData,file,content}

		# Render via plugins
		file.trigger 'renderDocument', eventData, (err) ->
			# Forward
			return next(err,eventData.content)

		# Chain
		@


	# Render Layouts
	# next(err,result)
	renderLayouts: (opts,next) ->
		# Prepare
		file = @
		{opts,next} = @getActionArgs(opts,next)
		{content,templateData} = opts
		content ?= @get('body')
		templateData ?= {}

		# Grab the layout
		file.getLayout (err,layout) ->
			# Check
			return next(err,content)  if err

			# Check if we have a layout
			if layout
				# Assign the current rendering to the templateData.content
				templateData.content = content

				# Merge in the layout meta data into the document JSON
				# and make the result available via documentMerged
				# templateData.document.metaMerged = _.extend({}, layout.getMeta().toJSON(), file.getMeta().toJSON())

				# Render the layout with the templateData
				layout.render {templateData}, (err,result) ->
					return next(err,result)

			# We don't have a layout, nothing to do here
			else
				return next(null,content)


	# Render
	# Render this file
	# next(err,result,document)
	render: (opts={},next) ->
		# Prepare
		file = @
		contentRenderedWithoutLayouts = null
		fullPath = @get('fullPath')

		# Prepare options
		{opts,next} = @getActionArgs(opts,next)
		opts = _.clone(opts or {})
		opts.actions ?= ['renderExtensions','renderDocument','renderLayouts']

		# Prepare content
		opts.content ?= @get('body')

		# Prepare templateData
		opts.templateData = _.clone(opts.templateData or {})
		opts.templateData.document ?= file.toJSON()
		opts.templateData.documentModel ?= file

		# Prepare result
		# file.set({contentRendered:null, contentRenderedWithoutLayouts:null, rendered:false})

		# Log
		file.log 'debug', "Rendering the file: #{fullPath}"

		# Prepare the tasks
		tasks = new balUtil.Group (err) ->
			# Error?
			if err
				file.log 'warn', "Something went wrong while rendering: #{fullPath}"
				return next(err, opts.content, file)

			# Apply
			contentRendered = opts.content
			contentRenderedWithoutLayouts ?= contentRendered
			rendered = true
			file.set({contentRendered, contentRenderedWithoutLayouts, rendered})

			# Log
			file.log 'debug', "Rendering completed for: #{fullPath}"

			# Success
			return next(null, opts.content, file)

		# Render Extensions Task
		if 'renderExtensions' in opts.actions
			tasks.push (complete) ->
				file.renderExtensions opts, (err,result) ->
					# Check
					return complete(err)  if err
					# Apply the result
					opts.content = result
					# Done
					return complete()

		# Render Document Task
		if 'renderDocument' in opts.actions
			tasks.push (complete) ->
				file.renderDocument opts, (err,result) ->
					# Check
					return complete(err)  if err
					# Apply the result
					opts.content = result
					contentRenderedWithoutLayouts = result
					# Done
					return complete()

		# Render Layouts Task
		if 'renderLayouts' in opts.actions
			tasks.push (complete) ->
				file.renderLayouts opts, (err,result) ->
					# Check
					return complete(err)  if err
					# Apply the result
					opts.content = result
					# Done
					return complete()

		# Fire the tasks
		tasks.sync()

		# Chain
		@

# Export
module.exports = DocumentModel
