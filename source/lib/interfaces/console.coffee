# =====================================
# Requires

# Standard
pathUtil = require('path')

# External
Errlop = require('errlop')
safefs = require('safefs')
safeps = require('safeps')
{TaskGroup} = require('taskgroup')
extendr = require('extendr')
promptly = require('promptly')

# Local
docpadUtil = require('../util')


# =====================================
# Classes

###*
# Console Interface
# @constructor
###
class ConsoleInterface


	###*
	# Constructor method. Setup the CLI
	# @private
	# @method constructor
	# @param {Object} opts
	# @param {Function} next
	###
	constructor: (opts,next) ->
		# Prepare
		consoleInterface = @
		@docpad = docpad = opts.docpad
		@commander = commander = require('commander')
		locale = docpad.getLocale()

		# -----------------------------
		# Exit handler

		process.once('exit', @onExit)


		# -----------------------------
		# Global config

		commander
			.version(
				docpad.getVersionString()
			)
			.option(
				'-o, --out <outPath>'
				locale.consoleOptionOut
			)
			.option(
				'-c, --config <configPath>'
				locale.consoleOptionConfig
			)
			.option(
				'-e, --env <environment>'
				locale.consoleOptionEnv
			)
			.option(
				'-d, --debug [logLevel]'
				locale.consoleOptionDebug
				parseInt
			)
			.option(
				'-g, --global'
				locale.consoleOptionGlobal
			)
			.option(
				'-f, --force'
				locale.consoleOptionForce
			)
			.option(
				'--no-color'  # commander translates this to the `color` option for us
				locale.consoleOptionNoColor
			)
			.option(
				'--silent'
				locale.consoleOptionSilent
			)
			.option(
				'--skeleton <skeleton>'
				locale.consoleOptionSkeleton
			)
			.option(
				'--offline'
				locale.consoleOptionOffline
			)

		# -----------------------------
		# Commands

		# actions
		commander
			.command('action <actions>')
			.description(locale.consoleDescriptionRun)
			.action(consoleInterface.wrapAction(consoleInterface.action))

		# init
		commander
			.command('init')
			.description(locale.consoleDescriptionInit)
			.action(consoleInterface.wrapAction(consoleInterface.init))

		# run
		commander
			.command('run')
			.description(locale.consoleDescriptionRun)
			.action(consoleInterface.wrapAction(consoleInterface.run, {
				_stayAlive: true
			}))

		# render
		commander
			.command('render [path]')
			.description(locale.consoleDescriptionRender)
			.action(consoleInterface.wrapAction(consoleInterface.render, {
				# Disable anything unnecessary or that could cause extra output we don't want
				logLevel: 3  # 3:error, 2:critical, 1:alert, 0:emergency
				checkVersion: false
				welcome: false
				prompts: false
			}))

		# generate
		commander
			.command('generate')
			.description(locale.consoleDescriptionGenerate)
			.action(consoleInterface.wrapAction(consoleInterface.generate))

		# watch
		commander
			.command('watch')
			.description(locale.consoleDescriptionWatch)
			.action(consoleInterface.wrapAction(consoleInterface.watch, {
				_stayAlive: true
			}))

		# update
		commander
			.command('update')
			.description(locale.consoleDescriptionUpdate)
			.action(consoleInterface.wrapAction(consoleInterface.update))

		# upgrade
		commander
			.command('upgrade')
			.description(locale.consoleDescriptionUpgrade)
			.action(consoleInterface.wrapAction(consoleInterface.upgrade))

		# install
		commander
			.command('install [pluginName]')
			.description(locale.consoleDescriptionInstall)
			.action(consoleInterface.wrapAction(consoleInterface.install))

		# uninstall
		commander
			.command('uninstall <pluginName>')
			.description(locale.consoleDescriptionUninstall)
			.action(consoleInterface.wrapAction(consoleInterface.uninstall))

		# clean
		commander
			.command('clean')
			.description(locale.consoleDescriptionClean)
			.action(consoleInterface.wrapAction(consoleInterface.clean))

		# info
		commander
			.command('info')
			.description(locale.consoleDescriptionInfo)
			.action(consoleInterface.wrapAction(consoleInterface.info))

		# help
		commander
			.command('help')
			.description(locale.consoleDescriptionHelp)
			.action(consoleInterface.wrapAction(consoleInterface.help))

		# unknown
		commander
			.command('*')
			.description(locale.consoleDescriptionUnknown)
			.action(consoleInterface.wrapAction(consoleInterface.help))

		# -----------------------------
		# Finish Up

		# Plugins
		docpad.emitSerial 'consoleSetup', {consoleInterface,commander}, (err) ->
			return next(err, consoleInterface)

		# Chain
		@


	# =================================
	# Helpers

	###*
	# Get the commander
	# @method getCommander
	# @return the commander instance
	###
	getCommander: =>
		@commander

	###*
	# Start the CLI
	# @method start
	# @param {Array} argv
	###
	start: (argv) =>
		@commander.parse(argv or process.argv)
		@

	###*
	# Finish the CLI and destroy DocPad.
	# @method destroy
	# @param {Object} err
	###
	finish: =>
		# Prepare
		docpad = @docpad

		# Log
		docpad.log('debug', docpad.getLocale().consoleFinish)

		# Destroy docpad
		docpad.destroy (err) ->
			# We don't care about logging the error, as it would have already been done
			process.exit(process.exitCode or (err and 1) or 0)

		# Chain
		@

	###*
	# Handler for the process.exit event
	# @method onExit
	# @param {number} exitCode
	###
	onExit: (exitCode) ->
		# Handle any errors that occur when stdin is closed
		# https://github.com/docpad/docpad/pull/1049
		process.stdin?.on? 'error', (stdinError) ->
			# ignore ENOTCONN as it means stdin was already closed when we called stdin.end
			# node v8 and above have stdin.destroy to avoid emitting this error
			if stdinError.toString().indexOf('ENOTCONN') is -1
				err = new Errlop(
					"closing stdin encountered an error",
					stdinError
				)
				docpad.fatal(err)

		# Close stdin
		# https://github.com/docpad/docpad/issues/1028
		# https://github.com/docpad/docpad/pull/1029
		process.stdin?.destroy?() or process.stdin?.end?()

		# Wait a moment before outputting things that are preventing closure
		docpadUtil.setImmediate ->
			# Note any requests that are still active
			activeRequests = process._getActiveRequests?()
			if activeRequests?.length
				docpadUtil.writeStderr """
					Waiting on these #{activeRequests.length} requests to close:
					#{docpadUtil.inspect activeRequests}
					"""

			# Note any handles that are still active
			activeHandles = process._getActiveHandles?()
			if activeHandles?.length
				docpadUtil.writeStderr """
					Waiting on these #{activeHandles.length} handles to close:
					#{docpadUtil.inspect activeHandles}
					"""

		# Chain
		@

	###*
	# Wrap Action
	# @method wrapAction
	# @param {Object} action
	# @param {Object} config
	###
	wrapAction: (action,config) =>
		consoleInterface = @
		return (args...) ->
			consoleInterface.performAction(action, args, config)

	###*
	# Perform Action
	# @method performAction
	# @param {Object} action
	# @param {Object} args
	# @param {Object} [config={}]
	###
	performAction: (action,args,config={}) =>
		# Prepare
		consoleInterface = @
		docpad = @docpad

		# Special Opts
		stayAlive = false
		if config._stayAlive
			stayAlive = config._stayAlive
			delete config._stayAlive

		# Create
		opts = {}
		opts.commander = args[-1...][0]
		opts.args = args[...-1]
		opts.instanceConfig = extendr.deepDefaults({}, @extractConfig(opts.commander), config)

		# Complete Action
		completeAction = (err) ->
			# Prepare
			locale = docpad.getLocale()

			# Handle the error
			return docpad.fatal(err)  if err

			# Success
			docpad.log('info', locale.consoleSuccess)

			# Shutdown
			return consoleInterface.finish()  if stayAlive is false

		# Load
		docpad.action 'load ready', opts.instanceConfig, (err) ->
			# Check
			return completeAction(err)  if err

			# Action
			return action(completeAction, opts)  # this order for interface actions for b/c

		# Chain
		@

	###*
	# Extract Configuration
	# @method extractConfig
	# @param {Object} [customConfig={}]
	# @return {Object} the DocPad config
	###
	extractConfig: (customConfig={}) =>
		# Prepare
		config = {}
		commanderConfig = @commander
		sourceConfig = @docpad.initialConfig

		# debug -> logLevel
		if commanderConfig.debug
			commanderConfig.debug = 7  if commanderConfig.debug is true
			commanderConfig.logLevel = commanderConfig.debug

		# silent -> prompt
		if commanderConfig.silent?
			commanderConfig.prompts = !(commanderConfig.silent)

		# config -> configPaths
		if commanderConfig.config
			configPath = pathUtil.resolve(process.cwd(),commanderConfig.config)
			commanderConfig.configPaths = [configPath]

		# out -> outPath
		if commanderConfig.out
			outPath = pathUtil.resolve(process.cwd(),commanderConfig.out)
			commanderConfig.outPath = outPath

		# Apply global configuration
		for own key, value of commanderConfig
			if typeof sourceConfig[key] isnt 'undefined'
				config[key] = value

		# Apply custom configuration
		for own key, value of customConfig
			if typeof sourceConfig[key] isnt 'undefined'
				config[key] = value

		# Return config object
		config

	###*
	# Select a skeleton
	# @method selectSkeletonCallback
	# @param {Object} skeletonsCollection
	# @param {Function} next
	###
	selectSkeletonCallback: (skeletonsCollection,next) =>
		# Prepare
		consoleInterface = @
		commander = @commander
		docpad = @docpad
		locale = docpad.getLocale()
		skeletonNames = []

		# Already selected?
		if @commander.skeleton
			skeletonModel = skeletonsCollection.get(@commander.skeleton)
			if skeletonModel
				next(null, skeletonModel)
			else
				err = new Errlop("Couldn't fetch the skeleton with id #{@commander.skeleton}")
				next(err)
			return @

		# Show
		docpad.log 'info', locale.skeletonSelectionIntroduction+'\n'
		skeletonsCollection.forEach (skeletonModel) ->
			skeletonName = skeletonModel.get('name')
			skeletonDescription = skeletonModel.get('description').replace(/\n/g,'\n\t')
			skeletonNames.push(skeletonName)
			console.log "  #{skeletonModel.get('position')+1}.\t#{skeletonName}\n  \t#{skeletonDescription}\n"

		# Select
		consoleInterface.choose locale.skeletonSelectionPrompt, skeletonNames, {}, (err, choice) ->
			return next(err)  if err
			index = skeletonNames.indexOf(choice)
			return next(null, skeletonsCollection.at(index))

		# Chain
		@

	###*
	# Prompt for input
	# @method prompt
	# @param {String} message
	# @param {Object} [opts={}]
	# @param {Function} next
	###
	prompt: (message, opts={}, next) ->
		# Default
		message += " [#{opts.default}]"  if opts.default

		# Options
		opts = extendr.extend({
			trim: true
			retry: true
			silent: false
		}, opts)

		# Log
		promptly.prompt(message, opts, next)

		# Chain
		@

	###*
	# Confirm an option
	# @method confirm
	# @param {String} message
	# @param {Object} [opts={}]
	# @param {Function} next
	###
	confirm: (message, opts={}, next) ->
		# Default
		if opts.default is true
			message += " [Y/n]"
		else if opts.default is false
			message += " [y/N]"

		# Options
		opts = extendr.extend({
			trim: true
			retry: true
			silent: false
		}, opts)

		# Log
		promptly.confirm(message, opts, next)

		# Chain
		@

	###*
	# Choose something
	# @method choose
	# @param {String} message
	# @param {Object} choices
	# @param {Object} [opts={}]
	# @param {Function} next
	###
	choose: (message, choices, opts={}, next) ->
		# Default
		message += " [1-#{choices.length}]"
		indexes = []
		for choice,i in choices
			index = i+1
			indexes.push(index)
			message += "\n  #{index}.\t#{choice}"

		# Options
		opts = extendr.extend({
			trim: true
			retry: true
			silent: false
		}, opts)

		# Prompt
		prompt = '> '
		prompt += " [#{opts.default}]"  if opts.default

		# Log
		console.log(message)
		promptly.choose prompt, indexes, opts, (err, index) ->
			return next(err)  if err
			choice = choices[index-1]
			return next(null, choice)

		# Chain
		@


	# =================================
	# Actions

	###*
	# Do action
	# @method action
	# @param {Function} next
	# @param {Object} opts
	###
	action: (next,opts) =>
		actions = opts.args[0]
		@docpad.log 'info', 'Performing the actions:', actions
		@docpad.action(actions, next)
		@

	###*
	# Action initialise
	# @method init
	# @param {Function} next
	###
	init: (next) =>
		@docpad.action('init', next)
		@

	###*
	# Generate action
	# @method generate
	# @param {Function} next
	###
	generate: (next) =>
		@docpad.action('generate', next)
		@

	###*
	# Help method
	# @method help
	# @param {Function} next
	###
	help: (next) =>
		help = @commander.helpInformation()
		console.log(help)
		next()
		@

	###*
	# Info method
	# @method info
	# @param {Function} next
	###
	info: (next) =>
		docpad = @docpad
		info = docpad.inspector(docpad.config)
		console.log(info)
		next()
		@

	###*
	# Update method
	# @method update
	# @param {Function} next
	# @param {Object} opts
	###
	update: (next,opts) =>
		# Act
		@docpad.action('clean update', next)

		# Chain
		@
	###*
	# Upgrade method
	# @method upgrade
	# @param {Function} next
	# @param {Object} opts
	###
	upgrade: (next,opts) =>
		# Act
		@docpad.action('upgrade', next)

		# Chain
		@

	###*
	# Install method
	# @method install
	# @param {Function} next
	# @param {Object} opts
	###
	install: (next,opts) =>
		# Extract
		plugin = opts.args[0] or null

		# Act
		@docpad.action('install', {plugin}, next)

		# Chain
		@

	###*
	# Uninstall method
	# @method uninstall
	# @param {Function} next
	# @param {Object} opts
	###
	uninstall: (next,opts) =>
		# Extract
		plugin = opts.args[0] or null

		# Act
		@docpad.action('uninstall', {plugin}, next)

		# Chain
		@

	###*
	# Render method
	# @method render
	# @param {Function} next
	# @param {Object} opts
	###
	render: (next,opts) =>
		# Prepare
		docpad = @docpad
		commander = @commander

		# Prepare
		data = ''
		renderOpts = {
			renderSingleExtensions: 'auto'
		}

		# Extract
		renderOpts.filename = opts.args[0] or null

		# Render
		useStdin = true
		renderDocument = (complete) ->
			# Perform the render
			docpad.action 'render', renderOpts, (err,result) ->
				return complete(err)  if err

				# Path
				if commander.out?
					safefs.writeFile(commander.out, result, complete)

				# Stdout
				else
					process.stdout.write(result)
					return complete()

		# Timeout if we don't have stdin
		docpad.timer 'console.render', 'timeout', 1005, ->
			# Skip if we are using stdin
			return next()  if data.replace(/\s+/,'')

			# Close stdin as we are no longer using using it
			useStdin = false
			stdin.pause()

			# Render the document
			renderDocument(next)

		# Read stdin
		stdin = process.stdin
		stdin.resume()
		stdin.setEncoding('utf8')
		stdin.on 'data', (_data) ->
			data += _data.toString()
		process.stdin.on 'end', ->
			return  unless useStdin
			docpad.timer('console.render')
			renderOpts.data = data
			renderDocument(next)

		@

	###*
	# Run method
	# @method run
	# @param {Function} next
	###
	run: (next) =>
		@docpad.action('run', {
			selectSkeletonCallback: @selectSkeletonCallback
			next: next
		})
		@

	###*
	# Clean method
	# @method clean
	# @param {Function} next
	###
	clean: (next) =>
		@docpad.action('clean', next)
		@

	###*
	# Watch method
	# @method watch
	# @param {Function} next
	###
	watch: (next) =>
		@docpad.action('generate watch', next)
		@


# =====================================
# Export
module.exports = ConsoleInterface
