# Requires
extendr = require('extendr')
typeChecker = require('typechecker')
ambi = require('ambi')
eachr = require('eachr')

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
	instanceConfig: {}

	# Plugin priority
	priority: 500

	# Constructor
	constructor: (opts) ->
		# Prepare
		me = @
		{docpad,config} = opts
		@docpad = docpad

		# Swap out our configuration
		@config = extendr.deepClone(@config)
		@instanceConfig = extendr.deepClone(@instanceConfig)
		@initialConfig = @config
		@setConfig(config)

		# Return early if we are disabled
		return @  if @isEnabled() is false

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

		# Chain
		@

	# Get Configuration
	getConfig: =>
		return @config

	# Bind Events
	bindEvents: ->
		# Prepare
		pluginInstance = @
		docpad = @docpad
		events = docpad.getEvents()

		# Bind events
		eachr events, (eventName) ->
			if typeChecker.isFunction(pluginInstance[eventName])
				# Fetch the event handler
				eventHandler = pluginInstance[eventName]
				# Wrap the event handler, and bind it to docpad
				docpad.on eventName, (opts,next) ->
					# Finish right away if we are disabled
					return next()  if pluginInstance.isEnabled() is false
					# Fire the function, treating the callback as optional
					ambi(eventHandler.bind(pluginInstance), opts, next)

		# Chain
		@

	# Is Enabled?
	isEnabled: ->
		return @config.enabled isnt false

# Export Plugin
module.exports = BasePlugin
