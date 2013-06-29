# Necessary
pathUtil = require('path')
extendr = require('extendr')
eachr = require('eachr')
{TaskGroup} = require('taskgroup')
mime = require('mime')

# Optional
CSON = null
YAML = null

# Local
FileModel = require('./file')


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
	# Helpers

	# Get Out Content
	getOutContent: ->
		content = @get('contentRendered') or @get('content') or @getBuffer()
		return content

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


	# ---------------------------------
	# Actions

	# Parse
	# Parse our buffer and extract some meaningful data from it
	# next(err)
	parse: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		buffer = @getBuffer()
		meta = @getMeta()

		# Wipe any meta attributes that we've copied over to our file
		reset = {}
		for own key,value of meta.attributes
			reset[key] = @defaults[key]
		reset = extendr.dereference(reset)
		@set(reset)

		# Then clear the meta attributes from the meta model
		meta.clear()

		# Reparse the data and extract the content
		# With the content, fetch the new meta data, header, and body
		super opts, =>
			# Content
			content = @get('content')
				.replace(/\r\n?/gm,'\n')  # normalise line endings for the web, just for convience, if it causes problems we can remove

			# Meta Data
			regex = ///
				# allow some space
				^\s*

				# discover our seperator
				(
					([^\s\d\w])\2{2,} # match a symbol character repeated 3 or more times
				) #\1

				# discover our parser
				(?:
					\x20* # allow zero or more space characters, see https://github.com/jashkenas/coffee-script/issues/2668
					(
						[a-z]+  # parser must be lowercase alpha
					) #\3
				)?

				# discover our meta content
				(
					[\s\S]*? # match anything/everything lazily
				) #\4

				# match our seperator (the first group) exactly
				\1
				///

			# Extract Meta Data
			match = regex.exec(content)
			metaData = {}
			if match
				# Prepare
				seperator = match[1]
				parser = match[3] or 'yaml'
				header = match[4].trim()
				body = content.substring(match[0].length).trim()

				# Parse
				try
					switch parser
						when 'cson', 'coffee', 'coffeescript', 'coffee-script'
							CSON = require('cson')  unless CSON
							metaData = CSON.parseSync(header)
							meta.set(metaData)

						when 'yaml'
							YAML = require('yamljs')  unless YAML
							metaData = YAML.parse(
								header.replace(/\t/g,'    ')  # YAML doesn't support tabs that well
							)
							meta.set(metaData)

						else
							err = new Error("Unknown meta parser: #{parser}")
							return next(err)
				catch err
					return next(err)
			else
				body = content

			# Incorrect encoding detection?
			# If so, re-parse with the correct encoding conversion
			if metaData.encoding and metaData.encoding isnt @get('encoding')
				@setMeta({encoding:metaData.encoding})
				opts.reencode = true
				return @parse(opts, next)

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
			metaDate = meta.get('date')
			if metaDate
				metaDate = new Date(metaDate)
				meta.set({date:metaDate})

			# Correct ignore
			ignored = meta.get('ignored') or meta.get('ignore') or meta.get('skip') or meta.get('draft') or (meta.get('published') is false)
			meta.set({ignored:true})  if ignored

			# Handle urls
			metaUrls = meta.get('urls')
			metaUrl = meta.get('url')
			@addUrl(metaUrls)  if metaUrls
			@addUrl(metaUrl)   if metaUrl

			# Apply meta to us
			@set(meta.toJSON())

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
		changes = {}
		meta = @getMeta()

		# Extract
		outExtension = opts.outExtension or meta.get('outExtension') or null
		filename = opts.filename or @get('filename') or null
		extensions = @getExtensions({filename}) or null

		# Extension Rendered
		if !outExtension
			changes.outExtension = outExtension = extensions[0] or null

		# Forward
		super(extendr.extend(opts, changes), next)

		# Chain
		@

	# Contextualize data
	# Put our data into perspective of the bigger picture. For instance, generate the url for it's rendered equivalant.
	# next(err)
	contextualize: (opts={},next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)

		# Get our highest ancestor
		@getEve (err,eve) =>
			# Prepare
			return next(err)  if err
			changes = {}
			meta = @getMeta()

			# User specified
			outFilename = opts.outFilename or meta.get('outFilename') or null
			outPath = opts.outPath or meta.get('outPath') or null
			outExtension = opts.outExtension or meta.get('outExtension') or null
			extensions = @getExtensions({filename:outFilename}) or null

			# outExtension
			if !outExtension
				if !outFilename and !outPath
					if eve?
						changes.outExtension = outExtension = eve.get('outExtension') or extensions[0] or null
					else
						changes.outExtension = extensions[0] or null

			# Forward onto normalize to adjust for the outExtension change
			return @normalize(extendr.extend(opts, changes), next)

		# Chain
		@


	# ---------------------------------
	# Layouts

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
		layoutSelector = @get('layout')

		# Check
		return next(null,null)  unless layoutSelector

		# Find parent
		@emit 'getLayout', {selector:layoutSelector}, (err,opts) ->
			# Prepare
			{layout} = opts

			# Error
			if err
				file.set('layoutId': null)
				return next(err)

			# Not Found
			else unless layout
				file.set('layoutId': null)
				err = new Error("Could not find the specified layout: #{layoutSelector}")
				return next(err)

			# Found
			else
				file.set('layoutId': layout.id)
				return next(null,layout)

			# We update the layoutId as it is used for finding what documents are used by a layout for when a layout changes

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


	# ---------------------------------
	# Rendering

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
		tasks = new TaskGroup().once 'complete', (err) ->
			# Forward with result
			return next(err,result)

		# Cycle through all the extension groups and render them
		eachr extensionsReversed[1..], (extension,index) -> tasks.addTask (complete) ->
			# Prepare
			eventData =
				inExtension: extensionsReversed[index]
				outExtension: extension
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
		tasks.run()

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
				# templateData.document.metaMerged = extendr.extend({}, layout.getMeta().toJSON(), file.getMeta().toJSON())

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
		opts = extendr.clone(opts or {})
		opts.actions ?= ['renderExtensions','renderDocument','renderLayouts']

		# Prepare content
		opts.content ?= @get('body')

		# Prepare templateData
		opts.templateData = extendr.clone(opts.templateData or {})  # deepClone may be more suitable
		opts.templateData.document ?= file.toJSON()
		opts.templateData.documentModel ?= file

		# Prepare result
		# file.set({contentRendered:null, contentRenderedWithoutLayouts:null, rendered:false})

		# Log
		file.log 'debug', "Rendering the file: #{fullPath}"

		# Prepare the tasks
		tasks = new TaskGroup().once 'complete', (err) ->
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
			tasks.addTask (complete) ->
				file.renderExtensions opts, (err,result) ->
					# Check
					return complete(err)  if err
					# Apply the result
					opts.content = result
					# Done
					return complete()

		# Render Document Task
		if 'renderDocument' in opts.actions
			tasks.addTask (complete) ->
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
			tasks.addTask (complete) ->
				file.renderLayouts opts, (err,result) ->
					# Check
					return complete(err)  if err
					# Apply the result
					opts.content = result
					# Done
					return complete()

		# Fire the tasks
		tasks.run()

		# Chain
		@


	# ---------------------------------
	# CRUD

	# Write the rendered file
	# next(err)
	writeRendered: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		file = @

		# Fetch
		opts.content or= @getOutContent()
		opts.type    or= 'rendered document'

		# Write data
		@write(opts,next)

		# Chain
		@

	# Write the file
	# next(err)
	writeSource: (opts,next) ->
		# Prepare
		{opts,next} = @getActionArgs(opts,next)
		file = @
		meta = @getMeta()
		CSON = require('cson')  unless CSON

		# Fetch
		fullPath = @get('fullPath')
		content = (@getContent() or '').toString()
		parser = 'cson'
		seperator = '---'

		# Log
		file.log 'debug', "Writing the source file: #{fullPath}"

		# Adjust
		metaData = meta.toJSON()
		header = CSON.stringifySync(metaData)
		content = body = content.replace(/^\s+/,'')
		source = "#{seperator} #{parser}\n#{header}\n#{seperator}\n\n#{body}"

		# Apply
		@set({parser,header,body,content,source})

		# Fetch
		opts.path    or= fullPath
		opts.content or= content
		opts.type    or= 'source document'

		# Write data
		@write(opts,next)

		# Chain
		@

# Export
module.exports = DocumentModel
