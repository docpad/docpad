# ---------------------------------
# Requires

# External
extendr = require('extendr')
typeChecker = require('typechecker')
ambi = require('ambi')
eachr = require('eachr')


# ---------------------------------
# Classes

# Define Plugin
###*
# The base class for all DocPad plugins
# @class BasePlugin
# @constructor
###
class BasePlugin

	###*
	# Add support for BasePlugin.extend(proto)
	# @private
	# @property {Object} @extend
	###
	@extend: require('csextends')

	# ---------------------------------
	# Inherited

	###*
	# The DocPad Instance
	# @private
	# @property {Object} docpad
	###
	docpad: null

	# ---------------------------------
	# Variables

	###*
	# The plugin name
	# @property {String}
	###
	name: null

	###*
	# The plugin config
	# @property {Object}
	###
	config: {}
	
	###*
	# The instance config.
	# @property {Object}
	###
	instanceConfig: {}

	###*
	# Plugin priority
	# @private
	# @property {Number}
	###
	priority: 500

	###*
	# Constructor method for the plugin
	# @method constructor
	# @param {Object} opts
	###
	constructor: (opts) ->
		# Prepare
		me = @
		{docpad,config} = opts
		@docpad = docpad

		# Bind listeners
		@bindListeners()

		# Swap out our configuration
		@config = extendr.deepClone(@config)
		@instanceConfig = extendr.deepClone(@instanceConfig)
		@initialConfig = @config
		@setConfig(config)

		# Return early if we are disabled
		return @  if @isEnabled() is false

		# Listen to events
		@addListeners()

		# Chain
		@

	###*
	# Set Instance Configuration
	# @private
	# @method setInstanceConfig
	# @param {Object} instanceConfig
	###
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config
		@

	###*
	# Set Configuration
	# @private
	# @method {Object} setConfig
	# @param {Object} [instanceConfig=null]
	###
	setConfig: (instanceConfig=null) =>
		# Prepare
		docpad = @docpad
		userConfig = @docpad.config.plugins[@name]
		@config = @docpad.config.plugins[@name] = {}

		# Instance config
		@setInstanceConfig(instanceConfig)  if instanceConfig

		# Merge configurations
		configPackages = [@initialConfig, userConfig, @instanceConfig]
		configsToMerge = [@config]
		docpad.mergeConfigurations(configPackages, configsToMerge)

		# Remove listeners if we are disabled
		@removeListeners()  unless @isEnabled()

		# Chain
		@

	###*
	# Get the Configuration
	# @private
	# @method {Object}
	###
	getConfig: =>
		return @config

	###*
	# Alias for b/c
	# @private
	# @method bindEvents
	###
	bindEvents: -> @addListeners()


	###*
	# Bind Listeners
	# @private
	# @method bindListeners
	###
	bindListeners: ->
		# Prepare
		pluginInstance = @
		docpad = @docpad
		events = docpad.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Bind the listener to the plugin
				pluginInstance[eventName] = eventHandler.bind(pluginInstance)

		# Chain
		@


	###*
	# Add Listeners
	# @private
	# @method addListeners
	###
	addListeners: ->
		# Prepare
		pluginInstance = @
		docpad = @docpad
		events = docpad.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Apply the priority
				eventHandlerPriority = pluginInstance[eventName+'Priority'] or pluginInstance.priority or null
				eventHandler.priority ?= eventHandlerPriority
				eventHandler.name = "#{pluginInstance.name}: {eventName}"
				eventHandler.name += "(priority eventHandler.priority})"  if eventHandler.priority?

				# Wrap the event handler, and bind it to docpad
				docpad
					.off(eventName, eventHandler)
					.on(eventName, eventHandler)

		# Chain
		@


	###*
	# Remove Listeners
	# @private
	# @method removeListeners
	###
	removeListeners: ->
		# Prepare
		pluginInstance = @
		docpad = @docpad
		events = docpad.getEvents()

		# Bind events
		eachr events, (eventName) ->
			# Fetch the event handler
			eventHandler = pluginInstance[eventName]

			# Check it exists and is a function
			if typeChecker.isFunction(eventHandler)
				# Wrap the event handler, and unbind it from docpad
				docpad.off(eventName, eventHandler)

		# Chain
		@

	###*
	# Destructor. Calls removeListeners
	# @private
	# @method destroy
	###
	destroy: ->
		@removeListeners()
		@


	###*
	# Is Enabled?
	# @method isEnabled
	# @return {Boolean}
	###
	isEnabled: ->
		return @config.enabled isnt false


# ---------------------------------
# Export Plugin
module.exports = BasePlugin
