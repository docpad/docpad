# =====================================
# Requires

# Standard Library
util = require('util')
pathUtil = require('path')
docpadUtil = require('../util')

# External
CSON = require('cson')
extendr = require('extendr')
eachr = require('eachr')
{TaskGroup} = require('taskgroup')
extractOptsAndCallback = require('extract-opts')

# Local
FileModel = require('./file')

# Optional
YAML = null


# =====================================
# Classes

###*
# The DocumentModel class is DocPad's representation
# of a website or project's content files. This can be
# individual web pages or blog posts etc. Generally, this
# is not other website files such as css files, images, or scripts -
# unless there is a requirement to have DocPad do transformation on
# these files.
# Extends the DocPad FileModel class
# https://github.com/docpad/docpad/blob/master/src/lib/models/file.coffee
# DocumentModel primarily handles the rendering and parsing of document files.
# This includes merging the document with layouts and managing the rendering
# from one file extension to another. The class inherits many of the file
# specific operations and DocPad specific attributes from the FileModel class.
# However, it also overrides some parsing and file output operations contained
# in the FileModel class.
#
# Typically we do not need to create DocumentModels ourselves as DocPad handles
# all of that. Most of the time when we encounter DocumentModels is when
# querying DocPad's document collections either in the docpad.coffee file or
# from within a template.
#
# 	indexDoc = @getCollection('documents').findOne({relativeOutPath: 'index.html'})
#
# A plugin, however, may need to create a DocumentModel depending on its requirements.
# In such a case it is wise to use the built in DocPad methods to do so, in particular
# docpad.createModel
#
# 	#check to see if the document alread exists ie its an update
# 	docModel = @docpad.getCollection('posts').findOne({slug: 'some-slug'})
#
# 	#if so, load the existing document ready for regeneration
# 	if docModel
# 		docModel.load()
# 	else
# 		#if document doesn't already exist, create it and add to database
# 		docModel = @docpad.createModel({fullPath:'file/path/to/somewhere'})
# 		docModel.load()
# 		@docpad.getDatabase().add(docModel)
#
# @class DocumentModel
# @constructor
# @extends FileModel
###
class DocumentModel extends FileModel

	# ---------------------------------
	# Properties

	###*
	# The document model class.
	# @private
	# @property {Object} klass
	###
	klass: DocumentModel

	###*
	# String name of the model type.
	# In this case, 'document'.
	# @private
	# @property {String} type
	###
	type: 'document'


	# ---------------------------------
	# Attributes

	###*
	# The default attributes for any document model.
	# @private
	# @property {Object}
	###
	defaults: extendr.extend({}, FileModel::defaults, {

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

		# Whether or not we should render this file
		render: true

		# Whether or not we want to render single extensions
		renderSingleExtensions: false
	})


	# ---------------------------------
	# Helpers

	###*
	# Get the file content for output. This
	# will be the text content AFTER it has
	# been through the rendering process. If
	# this has been called before the rendering
	# process, then the raw text content will be returned,
	# or, if early enough in the process, the file buffer object.
	# @method getOutContent
	# @return {String or Object}
	###
	getOutContent: ->
		content = @get('contentRendered') or @getContent()
		return content

	###*
	# Set flag to indicate if the document
	# contains references to other documents.
	# Used in the rendering process to decide
	# on whether to render this document when
	# another document is updated.
	# @method referencesOthers
	# @param {Boolean} [flag=true]
	###
	referencesOthers: (flag) ->
		flag ?= true
		@set({referencesOthers:flag})
		@


	# ---------------------------------
	# Actions

	###*
	# Parse our buffer and extract meaningful data from it.
	# next(err).
	# @method parse
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
	parse: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		buffer = @getBuffer()
		locale = @getLocale()
		filePath = @getFilePath()

		# Reparse the data and extract the content
		# With the content, fetch the new meta data, header, and body
		super opts, =>
			# Prepare
			meta = @getMeta()
			metaDataChanges = {}
			parser = header = body = content = null

			# Content
			content = @get('content').replace(/\r\n?/gm,'\n')  # normalise line endings for the web, just for convience, if it causes problems we can remove

			# Header
			regex = ///
				# allow some space
				^\s*

				# allow potential comment characters in seperator
				[^\n]*?

				# discover our seperator characters
				(
					([^\s\d\w])  #\2
					\2{2,}  # match the above (the first character of our seperator), 2 or more times
				) #\1

				# discover our parser (optional)
				(?:
					\x20*  # allow zero or more space characters, see https://github.com/jashkenas/coffee-script/issues/2668
					(
						[a-z]+  # parser must be lowercase alpha
					)  #\3
				)?

				# discover our meta content
				(
					[\s\S]*?  # match anything/everything lazily
				) #\4

				# allow potential comment characters in seperator
				[^\n]*?

				# match our seperator (the first group) exactly
				\1

				# allow potential comment characters in seperator
				[^\n]*
				///

			# Extract Meta Data
			match = regex.exec(content)
			if match
				# TODO: Wipe the old meta data

				# Prepare
				seperator = match[1]
				parser = match[3] or 'yaml'
				header = match[4].trim()
				body = content.substring(match[0].length).trim()

				# Parse
				try
					switch parser
						when 'cson', 'json', 'coffee', 'coffeescript', 'coffee-script', 'js', 'javascript'
							switch parser
								when 'coffee', 'coffeescript', 'coffee-script'
									parser = 'coffeescript'
								when 'js', 'javascript'
									parser = 'javascript'

							csonOptions =
								format: parser
								json: true
								cson: true
								coffeescript: true
								javascript: true

							metaParseResult = CSON.parseString(header, csonOptions)
							if metaParseResult instanceof Error
								metaParseResult.context = "Failed to parse #{parser} meta header for the file: #{filePath}"
								return next(metaParseResult)

							extendr.extend(metaDataChanges, metaParseResult)

						when 'yaml'
							YAML = require('yamljs')  unless YAML
							metaParseResult = YAML.parse(
								header.replace(/\t/g,'    ')  # YAML doesn't support tabs that well
							)
							extendr.extend(metaDataChanges, metaParseResult)

						else
							err = new Error(util.format(locale.documentMissingParserError, parser, filePath))
							return next(err)
				catch err
					err.context = util.format(locale.documentParserError, parser, filePath)
					return next(err)
			else
				body = content

			# Incorrect encoding detection?
			# If so, re-parse with the correct encoding conversion
			if metaDataChanges.encoding and metaDataChanges.encoding isnt @get('encoding')
				@set({
					encoding: metaDataChanges.encoding
				})
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
			metaDataChanges.date = new Date(metaDataChanges.date)   if metaDataChanges.date

			# Correct ignore
			for key in ['ignore','skip','draft']
				if metaDataChanges[key]?
					metaDataChanges.ignored = (metaDataChanges[key] ? false)
					delete metaDataChanges[key]
			for key in ['published']
				if metaDataChanges[key]?
					metaDataChanges.ignored = !(metaDataChanges[key] ? false)
					delete metaDataChanges[key]

			# Handle urls
			@addUrl(metaDataChanges.urls)  if metaDataChanges.urls
			@setUrl(metaDataChanges.url)   if metaDataChanges.url

			# Check if the id was being over-written
			if metaDataChanges.id?
				@log 'warn', util.format(locale.documentIdChangeError, filePath)
				delete metaDataChanges.id

			# Apply meta data
			@setMeta(metaDataChanges)

			# Next
			return next()

		# Chain
		@

	###*
	# Normalize any parsing we have done, because if a value has
	# updates it may have consequences on another value.
	# This will ensure everything is okay.
	# next(err)
	# @method normalize
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
	normalize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
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

	###*
	# Contextualize the data. In other words,
	# put our data into the perspective of the bigger picture of the data.
	# For instance, generate the url for it's rendered equivalant.
	# next(err)
	# @method contextualize
	# @param {Object} [opts={}]
	# @param {Object} next callback
	###
	contextualize: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

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

	###*
	# Checks if the file has a layout.
	# @method hasLayout
	# @return {Boolean}
	###
	hasLayout: ->
		return @get('layout')?

	# Get Layout

	###*
	# Get the layout object that this file references (if any).
	# We update the layoutRelativePath as it is
	# used for finding what documents are used by a
	# layout for when a layout changes.
	# next(err, layout)
	# @method getLayout
	# @param {Function} next callback
	###
	getLayout: (next) ->
		# Prepare
		file = @
		layoutSelector = @get('layout')

		# Check
		return next(null, null)  unless layoutSelector

		# Find parent
		@emit 'getLayout', {selector:layoutSelector}, (err,opts) ->
			# Prepare
			{layout} = opts

			# Error
			if err
				file.set('layoutRelativePath': null)
				return next(err)

			# Not Found
			else unless layout
				file.set('layoutRelativePath': null)
				return next()

			# Found
			else
				file.set('layoutRelativePath': layout.get('relativePath'))
				return next(null, layout)

		# Chain
		@

	###*
	# Get the most ancestoral (root) layout we
	# have - ie, the very top one. Often this
	# will be the base or default layout for
	# a project. The layout where the head and other
	# html on all pages is defined. In some projects,
	# however, there may be more than one root layout
	# so we can't assume there will always only be one.
	# This is used by the contextualize method to determine
	# the output extension of the document. In other words
	# the document's final output extension is determined by
	# the root layout.
	# next(err,layout)
	# @method getEve
	# @param {Function} next
	###
	getEve: (next) ->
		if @hasLayout()
			@getLayout (err,layout) ->
				if err
					return next(err, null)
				else if layout
					layout.getEve(next)
				else
					next(null, null)
		else
			next(null, @)
		@


	# ---------------------------------
	# Rendering

	###*
	# Renders one extension to another depending
	# on the document model's extensions property.
	# Triggers the render event for each extension conversion.
	# This is the point where the various templating systems listen
	# for their extension and perform their conversions.
	# Common extension conversion is from md to html.
	# So the document source file maybe index.md.html.
	# This will be a markdown file to be converted to HTML.
	# However, documents can be rendered through more than
	# one conversion. Index.html.md.eco will be rendered from
	# eco to md and then from md to html. Two conversions.
	# next(err,result)
	# @private
	# @method renderExtensions
	# @param {Object} opts
	# @param {Function} next callback
	###
	renderExtensions: (opts,next) ->
		# Prepare
		file = @
		locale = @getLocale()
		[opts,next] = extractOptsAndCallback(opts, next)
		{content,templateData,renderSingleExtensions} = opts
		extensions = @get('extensions')
		filename = @get('filename')
		filePath = @getFilePath()
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
		return next(null, result)  if extensionsReversed.length <= 1

		# Prepare the tasks
		tasks = new @TaskGroup "renderExtensions: #{filePath}", next:(err) ->
			# Forward with result
			return next(err, result)

		# Cycle through all the extension groups and render them
		eachr extensionsReversed[1..], (extension,index) ->
			# Task
			tasks.addTask "renderExtension: #{filePath} [#{extensionsReversed[index]} => #{extension}]", (complete) ->
				# Prepare
				# eventData must be defined in the task
				# definining it in the above loop will cause eventData to persist between the tasks... very strange, but it happens
				# will cause the jade tests to fail
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
					if result and (result is eventData.content)
						file.log 'warn', util.format(locale.documentRenderExtensionNoChange, eventData.inExtension, eventData.outExtension, filePath)
						return complete()

					# The render did something, so apply and continue
					result = eventData.content
					return complete()

		# Run tasks synchronously
		tasks.run()

		# Chain
		@

	###*
	# Triggers the renderDocument event after
	# all extensions have been rendered. Listeners
	# can use this event to perform transformations
	# on the already rendered content.
	# @private
	# @method renderDocument
	# @param {Object} opts
	# @param {Function} next callback
	###
	renderDocument: (opts,next) ->
		# Prepare
		file = @
		[opts,next] = extractOptsAndCallback(opts, next)
		{content,templateData} = opts
		extension = @get('extensions')[0]
		content ?= @get('body')
		templateData ?= {}

		# Prepare event data
		eventData = {extension,templateData,file,content}

		# Render via plugins
		file.trigger 'renderDocument', eventData, (err) ->
			# Forward
			return next(err, eventData.content)

		# Chain
		@


	###*
	# Render and merge layout content. Merge
	# layout metadata with document metadata.
	# Return the resulting merged content to
	# the callback result parameter.
	# next(err,result)
	# @private
	# @method renderLayouts
	# @param {Object} opts
	# @param {Function} next callback
	###
	renderLayouts: (opts,next) ->
		# Prepare
		file = @
		locale = @getLocale()
		filePath = @getFilePath()
		[opts,next] = extractOptsAndCallback(opts, next)
		{content,templateData} = opts
		content ?= @get('body')
		templateData ?= {}

		# Grab the layout
		file.getLayout (err, layout) ->
			# Check
			return next(err, content)  if err

			# We have a layout to render
			if layout
				# Assign the current rendering to the templateData.content
				templateData.content = content

				# Merge in the layout meta data into the document JSON
				# and make the result available via documentMerged
				# templateData.document.metaMerged = extendr.extend({}, layout.getMeta().toJSON(), file.getMeta().toJSON())

				# Render the layout with the templateData
				layout.clone().action 'render', {templateData}, (err,result) ->
					return next(err, result)

			# We had a layout, but it is missing
			else if file.hasLayout()
				layoutSelector = file.get('layout')
				err = new Error(util.format(locale.documentMissingLayoutError, layoutSelector, filePath))
				return next(err, content)

			# We never had a layout
			else
				return next(null, content)

	###*
	# Triggers the render process for this document.
	# Calls the renderExtensions, renderDocument and
	# renderLayouts methods in sequence. This is the
	# method you want to call if you want to trigger
	# the rendering of a document manually.
	#
	# The rendered content is returned as the result
	# parameter to the passed callback and the DocumentModel
	# instance is returned in the document parameter.
	# next(err,result,document)
	# @method render
	# @param {Object} [opts={}]
	# @param {Function} next callback
	###
	render: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		locale = @getLocale()

		# Prepare variables
		contentRenderedWithoutLayouts = null
		filePath = @getFilePath()
		relativePath = file.get('relativePath')

		# Options
		opts = extendr.clone(opts or {})
		opts.actions ?= ['renderExtensions', 'renderDocument', 'renderLayouts']
		if opts.apply?
			err = new Error(locale.documentApplyError)
			return next(err)

		# Prepare content
		opts.content ?= file.get('body')

		# Prepare templateData
		opts.templateData = extendr.clone(opts.templateData or {})  # deepClone may be more suitable
		opts.templateData.document ?= file.toJSON()
		opts.templateData.documentModel ?= file

		# Ensure template helpers are bound correctly
		for own key, value of opts.templateData
			if value?.bind is Function::bind  # we do this style of check, as underscore is a function that has it's own bind
				opts.templateData[key] = value.bind(opts.templateData)

		# Prepare result
		# file.set({contentRendered:null, contentRenderedWithoutLayouts:null, rendered:false})

		# Log
		file.log 'debug', util.format(locale.documentRender, filePath)

		# Prepare the tasks
		tasks = new @TaskGroup "render tasks for: #{relativePath}", next:(err) ->
			# Error?
			if err
				err.context = util.format(locale.documentRenderError, filePath)
				return next(err, opts.content, file)

			# Attributes
			contentRendered = opts.content
			contentRenderedWithoutLayouts ?= contentRendered
			rendered = true
			file.set({contentRendered, contentRenderedWithoutLayouts, rendered})

			# Log
			file.log 'debug', util.format(locale.documentRendered, filePath)

			# Apply
			file.attributes.rtime = new Date()

			# Success
			return next(null, opts.content, file)
			# ^ do not use super here, even with =>
			# as it causes layout rendering to fail
			# the reasoning for this is that super uses the document's contentRendered
			# where, with layouts, opts.apply is false
			# so that isn't set

		# Render Extensions Task
		if 'renderExtensions' in opts.actions
			tasks.addTask "renderExtensions: #{relativePath}", (complete) ->
				file.renderExtensions opts, (err,result) ->
					# Check
					return complete(err)  if err

					# Apply the result
					opts.content = result

					# Done
					return complete()

		# Render Document Task
		if 'renderDocument' in opts.actions
			tasks.addTask "renderDocument: #{relativePath}", (complete) ->
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
			tasks.addTask "renderLayouts: #{relativePath}", (complete) ->
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

	###*
	# Write the source file. Optionally pass
	# the opts parameter to modify or set the file's
	# path, content or type.
	# next(err)
	# @method writeSource
	# @param {Object} [opts]
	# @param {Object} next callback
	###
	writeSource: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		file = @
		filePath = @getFilePath()

		# Fetch
		opts.content ?= (@getContent() or '').toString('')

		# Adjust
		metaData  = @getMeta().toJSON(true)
		delete metaData.writeSource
		content   = body = opts.content.replace(/^\s+/,'')
		header    = CSON.stringify(metaData)

		if header instanceof Error
			header.context = "Failed to write CSON meta header for the file: #{filePath}"
			return next(header)

		if !header or header is '{}'
			# No meta data
			source    = body
		else
			# Has meta data
			parser    = 'cson'
			seperator = '###'
			source    = "#{seperator} #{parser}\n#{header}\n#{seperator}\n\n#{body}"

		# Apply
		# @set({parser,header,body,content,source})
		# ^ commented out as we probably don't need to do this, it could be handled on the next load
		opts.content = source

		# Write data
		super(opts, next)

		# Chain
		@


# =====================================
# Export
module.exports = DocumentModel
