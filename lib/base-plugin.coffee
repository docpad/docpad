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

# Export Plugin
module.exports = BasePlugin