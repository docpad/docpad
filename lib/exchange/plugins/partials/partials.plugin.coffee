# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')
	path = require('path')

	# Define Plugin
	class PartialsPlugin extends BasePlugin
		# Plugin Name
		name: 'partials'

		# Default Configuration
		config:
			partialsPath: 'partials'

		# A list of all the partials to render
		partialsToRender: null  # Object

		# Prepare our Configuration
		constructor: ->
			# Prepare
			super
			docpad = @docpad
			config = @config

			# Resolve our partialsPath
			config.partialsPath = path.resolve(docpad.config.srcPath, config.partialsPath)


		# -----------------------------
		# Helpers

		# Render Partial Sync
		# Mapped to templateData.partial
		# Takes in a partialId and it's data and returns a temporary container
		# which will be replaced later when we've finished rendering our partial 
		renderPartialSync: (name,data) ->
			# Prepare
			config = @config

			# Prepare our partials entry
			id = Math.random()
			partial =
				id: id
				name: name
				data: data
				path: path.join config.partialsPath, name
				container: "[partial:#{id}]"

			# Store it for later
			@partialsToRender[id] = partial

			# Return the partial's container
			return partial.container


		# Render Partial
		# Render a partial asynchronously
		# next(err,details)
		renderPartial: (partial,next) ->
			# Prepare
			docpad = @docpad
			
			# Render
			document = docpad.createPartial()
			document.filename = partial.name
			document.fullPath = partial.path
			docpad.prepareAndRender document, partial.data, (err) ->
				return next?(err)  if err
				return next?(null,document.contentRendered)

			# Chain
			@


		# -----------------------------
		# Events

		# Render Before
		# Map the templateData functions
		renderBefore: ({templateData}, next) ->
			# Prepare
			me = @
			@partialsToRender = {}
			
			# Apply
			templateData.partial = (name,data) ->
				return me.renderPartialSync(name,data)

			# Next
			next?()

			# Chain
			@


		# Write After
		# Store all our files to be cached
		renderDocument: (opts,next) ->
			# Prepare
			{templateData,file} = opts

			# Prepare
			me = @
			docpad = @docpad
			config = @config
			partialsToRender = @partialsToRender

			# Ensure we are a document
			return next?()  if file.type is 'partial'

			# Async
			tasks = new balUtil.Group (err) ->
				# Forward
				return next(err)

			# Store all our files to be cached
			balUtil.each partialsToRender, (partial) ->
				tasks.push (complete) ->
					docpad.logger.log 'debug', "Partials rendering [#{partial.name}]"
					me.renderPartial partial, (err,contentRendered) ->
						# Check
						if err
							docpad.logger.log 'warn', "Partials failed to render [#{partial.name}]"
							docpad.error(err)
						
						# Replace container with the rendered content
						else
							opts.content = opts.content.replace(partial.container,contentRendered)
						
						# Done
						return complete()
			
			# Fire the tasks together
			tasks.async()

			# Chain
			@