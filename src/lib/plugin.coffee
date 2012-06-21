# Requires
_ = require('underscore')

# Define Plugin
class BasePlugin

	# ---------------------------------
	# Inherited

	# DocPad Instance
	docpad: null

	# Logger Instance
	logger: null


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
		'docpadReady'
		'consoleSetup'
		'generateBefore'
		'generateAfter'
		'cleanBefore'
		'cleanAfter'
		'parseBefore'
		'parseAfter'
		'renderBefore'
		'render'
		'renderDocument'
		'renderAfter'
		'writeBefore'
		'writeAfter'
		'serverBefore'
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
		for eventName in @events
			if typeof me[eventName] is 'function'
				# Ensure the event handle always runs on the local scope
				_.bindAll(me, eventName)
				# Bind hte event handler to the event
				me.docpad.on(eventName, me[eventName])

# Export Plugin
module.exports = BasePlugin
