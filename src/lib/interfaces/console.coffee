# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
safefs = require('safefs')
safeps = require('safeps')
{TaskGroup} = require('taskgroup')
extendr = require('extendr')
promptly = require('promptly')


# =====================================
# Classes

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: (opts,next) ->
		# Prepare
		consoleInterface = @
		@docpad = docpad = opts.docpad
		@commander = commander = require('commander')
		locale = docpad.getLocale()


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
				'-p, --port <port>'
				locale.consoleOptionPort
				parseInt
			)
			.option(
				'--cache'
				locale.consoleOptionCache
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
				'--profile'
				locale.consoleOptionProfile
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

		# server
		commander
			.command('server')
			.description(locale.consoleDescriptionServer)
			.action(consoleInterface.wrapAction(consoleInterface.server, {
				_stayAlive: true
			}))

		# skeleton
		commander
			.command('skeleton')
			.description(locale.consoleDescriptionSkeleton)
			.option(
				'-s, --skeleton <skeleton>'
				locale.consoleOptionSkeleton
			)
			.action(consoleInterface.wrapAction(consoleInterface.skeleton))

		# render
		commander
			.command('render [path]')
			.description(locale.consoleDescriptionRender)
			.action(consoleInterface.wrapAction(consoleInterface.render, {
				# Disable anything unnecessary or that could cause extra output we don't want
				logLevel: 3  # errors and above
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
		# DocPad Listeners

		# Welcome
		docpad.on 'welcome', (data,next) ->
			return consoleInterface.welcomeCallback(data,next)


		# -----------------------------
		# Finish Up

		# Plugins
		docpad.emitSerial 'consoleSetup', {consoleInterface,commander}, (err) ->
			return consoleInterface.destroyWithError(err)  if err
			return next(null, consoleInterface)

		# Chain
		@


	# =================================
	# Helpers

	# Start the CLI
	start: (argv) =>
		@commander.parse(argv or process.argv)
		@

	# Get the commander
	getCommander: =>
		@commander

	# Destroy with Error
	destroyWithError: (err) =>
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Handle
		docpad.log('error', locale.consoleError)
		docpad.error(err, 'err', @destroy)

		# Chain
		@

	# Destroy
	destroy: (err) =>
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Error?
		process.stderr.write(require('util').inspect(err.stack or err.message or err))  if err
		# ^ @TODO document we we use process.stderr.write instead of console.log here

		# Log Shutdown
		docpad.log('info', locale.consoleShutdown)

		# Destroy docpad
		docpad.destroy (err) ->
			# Error?
			process.stderr.write(require('util').inspect(err.stack or err.message or err))  if err
			# ^ @TODO document we we use process.stderr.write instead of console.log here

			# don't force exit, it should occur naturally

		# Chain
		@

	# Wrap Action
	wrapAction: (action,config) =>
		consoleInterface = @
		return (args...) ->
			consoleInterface.performAction(action, args, config)

	# Perform Action
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
		opts.instanceConfig = extendr.safeDeepExtendPlainObjects({}, @extractConfig(opts.commander), config)

		# Complete Action
		completeAction = (err) ->
			# Prepare
			locale = docpad.getLocale()

			# Handle the error
			return consoleInterface.destroyWithError(err)  if err

			# Success
			docpad.log('info', locale.consoleSuccess)

			# Shutdown
			return consoleInterface.destroy()  if stayAlive is false

		# Load
		docpad.action 'load ready', opts.instanceConfig, (err) =>
			# Check
			return completeAction(err)  if err

			# Action
			return action(completeAction, opts)  # this order for interface actions for b/c

		# Chain
		@


	# Extract Configuration
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

		# cache -> databaseCache
		if commanderConfig.silent?
			commanderConfig.databaseCache = commanderConfig.cache

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

	# Select a skeleton
	selectSkeletonCallback: (skeletonsCollection,next) =>
		# Prepare
		consoleInterface = @
		commander = @commander
		docpad = @docpad
		locale = docpad.getLocale()
		skeletonNames = []

		# Show
		docpad.log 'info', locale.skeletonSelectionIntroduction+'\n'
		skeletonsCollection.forEach (skeletonModel) ->
			skeletonName = skeletonModel.get('name')
			skeletonDescription = skeletonModel.get('description').replace(/\n/g,'\n\t')
			skeletonNames.push(skeletonName)
			console.log "  #{skeletonModel.get('position')+1}.\t#{skeletonName}\n  \t#{skeletonDescription}\n"

		# Select
		consoleInterface.choose locale.skeletonSelectionPrompt, skeletonNames, null, (err, choice) ->
			return next(err)  if err
			index = skeletonNames.indexOf(choice)
			return next(null, skeletonsCollection.at(index))

		# Chain
		@

	# Welcome Callback
	welcomeCallback: (opts,next) =>
		# Prepare
		consoleInterface = @
		commander = @commander
		docpad = @docpad
		locale = docpad.getLocale()
		userConfig = docpad.userConfig
		welcomeTasks = new TaskGroup('welcome tasks').done(next)

		# TOS
		welcomeTasks.addTask 'tos', (complete) ->
			return complete()  if docpad.config.prompts is false or userConfig.tos is true

			# Ask the user if they agree to the TOS
			consoleInterface.confirm locale.tosPrompt, {default:true}, (err, ok) ->
				# Check
				return complete(err)  if err

				# Track
				docpad.track 'tos', {ok}, (err) ->
					# Check
					if ok
						userConfig.tos = true
						console.log locale.tosAgree
						docpad.updateUserConfig(complete)
						return
					else
						console.log locale.tosDisagree
						process.exit()
						return

		# Newsletter
		welcomeTasks.addTask (complete) ->
			return complete()  if docpad.config.prompts is false or userConfig.subscribed? or (userConfig.subscribeTryAgain? and (new Date()) > (new Date(userConfig.subscribeTryAgain)))

			# Ask the user if they want to subscribe to the newsletter
			consoleInterface.confirm locale.subscribePrompt, {default:true}, (err, ok) ->
				# Check
				return complete(err)  if err

				# Track
				docpad.track 'subscribe', {ok}, (err) ->
					# If they don't want to, that's okay
					unless ok
						# Inform the user that we received their preference
						console.log locale.subscribeIgnore

						# Save their preference in the user configuration
						userConfig.subscribed = false
						docpad.updateUserConfig (err) ->
							return complete(err)  if err
							setTimeout(complete, 2000)
						return

					# Scan configuration to speed up the process
					commands = [
						['config','--get','user.name']
						['config','--get','user.email']
						['config','--get','github.user']
					]
					safeps.spawnCommands 'git', commands, (err,results) ->
						# Ignore error as it just means a config value wasn't defined

						# Fetch
						# The or to '' is there because otherwise we will get "undefined" as a string if the value doesn't exist
						userConfig.name = String(results?[0]?[1] or '').trim() or null
						userConfig.email = String(results?[1]?[1] or '').trim() or null
						userConfig.username = String(results?[2]?[1] or '').trim() or null

						# Let the user know we scanned their configuration if we got anything useful
						if userConfig.name or userConfig.email or userConfig.username
							console.log locale.subscribeConfigNotify

						# Tasks
						subscribeTasks = new TaskGroup('subscribe tasks').done (err) ->
							# Error?
							if err
								# Inform the user
								console.log locale.subscribeError

								# Save a time when we should try to subscribe again
								userConfig.subscribeTryAgain = new Date().getTime() + 1000*60*60*24  # tomorrow

							# Success
							else
								# Inform the user
								console.log locale.subscribeSuccess

								# Save the updated subscription status, and continue to what is next
								userConfig.subscribed = true
								userConfig.subscribeTryAgain = null

							# Save the new user configuration changes, and forward to the next task
							docpad.updateUserConfig(userConfig, complete)

						# Name Fallback
						subscribeTasks.addTask 'name fallback', (complete) ->
							consoleInterface.prompt locale.subscribeNamePrompt, {default: userConfig.name}, (err, result) ->
								return complete(err)  if err
								userConfig.name = result
								return complete()

						# Email Fallback
						subscribeTasks.addTask 'email fallback', (complete) ->
							consoleInterface.prompt locale.subscribeEmailPrompt, {default: userConfig.email}, (err, result) ->
								return complete(err)  if err
								userConfig.email = result
								return complete()

						# Username Fallback
						subscribeTasks.addTask 'username fallback', (complete) ->
							consoleInterface.prompt locale.subscribeUsernamePrompt, {default: userConfig.username}, (err, result) ->
								return complete(err)  if err
								userConfig.username = result
								return complete()

						# Save the details
						subscribeTasks.addTask 'save defaults', (complete) ->
							return docpad.updateUserConfig(complete)

						# Perform the subscribe
						subscribeTasks.addTask 'subscribe', (complete) ->
							# Inform the user
							console.log locale.subscribeProgress

							# Forward
							docpad.subscribe (err,res) ->
								# Check
								if err
									docpad.log 'debug', locale.subscribeRequestError, err.message
									return complete(err)

								# Success
								docpad.log 'debug', locale.subscribeRequestData, res.text
								return complete()

						# Run
						subscribeTasks.run()

		# Run
		welcomeTasks.run()

		# Chain
		@

	# Prompt for input
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

	# Confirm an option
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

	# Choose an option
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

	action: (next,opts) =>
		actions = opts.args[0]
		@docpad.log 'info', 'Performing the actions:', actions
		@docpad.action(actions, next)
		@

	init: (next) =>
		@docpad.action('init', next)
		@

	generate: (next) =>
		@docpad.action('generate', next)
		@

	help: (next) =>
		help = @commander.helpInformation()
		console.log(help)
		next()
		@

	info: (next) =>
		info = require('util').inspect(@docpad.config)
		console.log(info)
		next()
		@

	update: (next,opts) =>
		# Act
		@docpad.action('clean update', next)

		# Chain
		@

	upgrade: (next,opts) =>
		# Act
		@docpad.action('upgrade', next)

		# Chain
		@

	install: (next,opts) =>
		# Extract
		plugin = opts.args[0] or null

		# Act
		@docpad.action('install', {plugin}, next)

		# Chain
		@

	uninstall: (next,opts) =>
		# Extract
		plugin = opts.args[0] or null

		# Act
		@docpad.action('uninstall', {plugin}, next)

		# Chain
		@

	render: (next,opts) =>
		# Prepare
		docpad = @docpad
		commander = @commander
		renderOpts = {}

		# Extract
		filename = opts.args[0] or null
		basename = pathUtil.basename(filename)
		renderOpts.filename = filename
		renderOpts.renderSingleExtensions = 'auto'

		# Prepare text
		data = ''

		# Render
		useStdin = true
		renderDocument = ->
			# Perform the render
			docpad.action 'render', renderOpts, (err,result) ->
				return docpad.fatal(err)  if err
				# Path
				if commander.out?
					safefs.writeFile(commander.out, result, next)
				# Stdout
				else
					process.stdout.write(result)
					return next()

		# Timeout if we don't have stdin
		timeoutFunction = ->
			# Clear timeout
			timeout = null
			# Skip if we are using stdin
			return  if data.replace(/\s+/,'')
			# Close stdin as we are not using it
			useStdin = false
			stdin.pause()
			# Render the document
			renderDocument()
		timeout = setTimeout(timeoutFunction, 1000)

		# Read stdin
		stdin = process.stdin
		stdin.resume()
		stdin.setEncoding('utf8')
		stdin.on 'data', (_data) ->
			data += _data.toString()
		process.stdin.on 'end', ->
			return  unless useStdin
			if timeout
				clearTimeout(timeout)
				timeout = null
			renderOpts.data = data
			renderDocument()

		@

	run: (next) =>
		@docpad.action('run', {
			selectSkeletonCallback: @selectSkeletonCallback
			next: next
		})
		@

	server: (next) =>
		@docpad.action('server generate', next)
		@

	clean: (next) =>
		@docpad.action('clean', next)
		@

	skeleton: (next) =>
		@docpad.action('skeleton', {
			selectSkeletonCallback: @selectSkeletonCallback
			next: next
		})
		@

	watch: (next) =>
		@docpad.action('generate watch', next)
		@


# =====================================
# Export
module.exports = ConsoleInterface
