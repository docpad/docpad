# Define Plugin
class BasePlugin

	# ---------------------------------
	# Inherited

	# DocPad Instance
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
	
	# Bind to an event
	bind: (eventName,handler) ->
		handler or= @[eventName]
		if handler
			@docpad.on eventName, handler
		@
	
	# Bind all
	bindAll: (eventNames) ->
		if eventNames is 'string'
			eventNames = eventNames.split /[,\s]+/g
		for eventName in eventNames
			handler = @[eventName]
			if handler
				@docpad.on eventName, handler
		@
	
	###
	# ---------------------------------
	# Events

	# Generate is starting
	generateBefore: ({},next) ->
		next?()

	# Generate has finished
	generateAfter: ({},next) ->
		next?()


	# Cleaning is starting
	cleanBefore: ({},next) ->
		next?()

	# Cleaning has finished
	cleanAfter: ({},next) ->
		next?()


	# Parsing all files is starting
	parseBefore: ({},next) ->
		next?()
	
	# Parsing all files has finished
	parseAfter: ({},next) ->
		next?()
	

	# Rendering all files has started
	renderBefore: ({templateData},next) ->
		next?()
	
	# Render a file
	render: ({inExtension,outExtension,templateData,file}, next) ->
		next?()
	
	# Rendering all files has finished
	renderAfter: ({},next) ->
		next?()


	# Writing all files is starting
	writeBefore: ({},next) ->
		next?()

	# Writing all files has finished
	writeAfter: ({},next) ->
		next?()

	
	# Setting up the server is starting
	serverBefore: ({},next) ->
		next?()
	
	# Setting up the server has finished
	serverAfter: ({server},next) ->
		next?()
	###


# Export Plugin
module.exports = BasePlugin