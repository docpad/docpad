# Requires
balUtil = require('bal-util')

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
	constructor: (opts) ->
		# Prepare
		me = @
		{docpad,config} = opts
		@docpad = docpad
		envs = @docpad.getEnvironments()

		# Merge configurations
		configPackages = [@config, config]
		configsToMerge = [{}]
		for configPackage in configPackages
			configsToMerge.push(configPackage)
			for env in envs
				envConfig = configPackage.environments?[env]
				configsToMerge.push(envConfig)  if envConfig
		@config = balUtil.deepExtendPlainObjects(configsToMerge...)

		# Return early if we are disabled
		return @  if @isEnabled() is false

		# Bind Events
		@bindEvents()

		# Chain
		@

	# Bind Events
	bindEvents: ->
		# Prepare
		pluginInstance = @
		docpad = @docpad
		events = docpad.getEvents()

		# Bind events
		balUtil.each events, (eventName) ->
			if balUtil.isFunction(pluginInstance[eventName])
				# Fetch the event handler
				eventHandler = pluginInstance[eventName]
				# Wrap the event handler, and bind it to docpad
				docpad.on eventName, (opts,next) ->
					# Finish right away if we are disabled
					return next()  if pluginInstance.isEnabled() is false
					# Fire the function, treating the callback as optional
					balUtil.fireWithOptionalCallback(eventHandler, [opts,next], pluginInstance)

		# Chain
		@

	# Is Enabled?
	isEnabled: ->
		return @config.enabled isnt false

# Export Plugin
module.exports = BasePlugin
