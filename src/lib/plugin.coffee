# ---------------------------------
# Requires

# External
{extendOnClass} = require('extendonclass')
extendr = require('extendr')
typeChecker = require('typechecker')
ambi = require('ambi')
eachr = require('eachr')


# ---------------------------------
# Classes

# Define Plugin
class BasePlugin

	# Add support for BasePlugin.extend(proto)
	@extend: extendOnClass

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
	instanceConfig: {}

	# Plugin priority
	priority: 500

	# Constructor
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

	# Set Instance Configuration
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config
		@

	# Set Configuration
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

	# Get Configuration
	getConfig: =>
		return @config

	# Alias for b/c
	bindEvents: -> @addListeners()

	# Bind Listeners
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

	# Add Listeners
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

	# Remove Listeners
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

	# Destroy
	destroy: ->
		@removeListeners()
		@

	# Is Enabled?
	isEnabled: ->
		return @config.enabled isnt false


# ---------------------------------
# Export Plugin
module.exports = BasePlugin
