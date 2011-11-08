# Define Plugin
class DocpadPlugin

	# ---------------------------------
	# Inherited

	# Docpad
	docpad: null


	# ---------------------------------
	# Variables

	# Plugin name
	name: null

	# Plugin config
	config: {}

	# Plugin priority
	priority: 500

	# Constructor
	constructor: (@config={}) ->
		@docpad = @config.docpad
		@name or= @config.name  if @config.name
		if !@name
			throw new Error 'Plugin must have a name'

	# Trigger Event
	triggerEvent: (eventName, data={}, next) ->
		# Here only for legacy reasons
		data.docpad = @docpad
		data.logger = @docpad.logger

		# Trigger
		@[eventName](data, next)

		
	# ---------------------------------
	# Events

	# Generate is starting
	generateBefore: ({},next) ->
		next()

	# Generate has finished
	generateAfter: ({},next) ->
		next()


	# Cleaning is starting
	cleanBefore: ({},next) ->
		next()

	# Cleaning has finished
	cleanAfter: ({},next) ->
		next()


	# Parsing all files is starting
	parseBefore: ({},next) ->
		next()
	
	# Parsing all files has finished
	parseAfter: ({},next) ->
		next()
	

	# Rendering all files has started
	renderBefore: ({templateData},next) ->
		next()
	
	# Render a file
	render: ({inExtension,outExtension,templateData,file}, next) ->
		next()
	
	# Rendering all files has finished
	renderAfter: ({},next) ->
		next()


	# Writing all files is starting
	writeBefore: ({},next) ->
		next()

	# Writing all files has finished
	writeAfter: ({},next) ->
		next()

	
	# Setting up the server is starting
	serverBefore: ({},next) ->
		next()
	
	# Setting up the server has finished
	serverAfter: ({server},next) ->
		next()


# Export Plugin
module.exports = DocpadPlugin