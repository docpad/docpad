# Requires
_ = require('underscore')

# Define Plugin
class BasePlugin

	# ---------------------------------
	# Inherited

	# DocPad Instance
	docpad: null

	# Logger Instance
	docpad: null


	# ---------------------------------
	# Variables

	# Plugin name
	name: null

	# Plugin config
	config: {}

	# Plugin priority
	priority: 500

	# Event Listing
	events: [
		'generateBefore',
		'generateAfter',
		'cleanBefore',
		'cleanAfter',
		'parseBefore',
		'parseAfter',
		'renderBefore',
		'render',
		'renderDocument',
		'renderAfter',
		'writeBefore',
		'writeAfter',
		'serverBefore',
		'serverAfter'
	]

	# Constructor
	constructor: (config={}) ->
		# Prepare
		me = @
		@events = _.extend([],@events)
		@config = _.extend({},@config,config)
		@docpad = @config.docpad
		@logger = @docpad.logger
		@name or= @config.name  if @config.name
		if !@name
			throw new Error 'Plugin must have a name'

		# Bind events
		_.each @events, (eventName) ->
			if typeof me[eventName] is 'function'
				me.docpad.on eventName, (args...) ->
					me[eventName](args...)


# Export Plugin
module.exports = BasePlugin