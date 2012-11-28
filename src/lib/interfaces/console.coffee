# Requires
{cliColor} = require('caterpillar')
pathUtil = require('path')

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: (opts,next) ->
		# Prepare
		consoleInterface = @
		@docpad = docpad = opts.docpad
		@commander = commander = require('commander')
		locale = docpad.getLocale()

		# Version information
		version = require(__dirname+'/../../../package.json').version

		# -----------------------------
		# Global config

		commander
			.version(version)
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
				'-f, --force'
				locale.consoleOptionForce
			)
			###
			.option(
				'--profile'
				locale.consoleOptionProfile
			)
			###

		# -----------------------------
		# Commands

		# run
		commander
			.command('run')
			.description(locale.consoleDescriptionRun)
			.option(
				'-s, --skeleton <skeleton>'
				locale.consoleOptionSkeleton
			)
			.option(
				'-p, --port <port>'
				locale.consoleOptionPort
				parseInt
			)
			.action(consoleInterface.wrapAction(consoleInterface.run))

		# server
		commander
			.command('server')
			.description(locale.consoleDescriptionServer)
			.option(
				'-p, --port <port>'
				locale.consoleOptionPort
				parseInt
			)
			.action(consoleInterface.wrapAction(consoleInterface.server))

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
			.action (command) ->
				# Disable anything uncessary or that could cause extra output we don't want
				commander.debug ?= 5
				commander.checkVersion = false
				commander.welcome = false
				commander.prompts = false

				# Perform the render
				consoleInterface.performAction(command,consoleInterface.render)

		# generate
		commander
			.command('generate')
			.description(locale.consoleDescriptionGenerate)
			.action(consoleInterface.wrapAction(consoleInterface.generate))

		# watch
		commander
			.command('watch')
			.description(locale.consoleDescriptionWatch)
			.action(consoleInterface.wrapAction(consoleInterface.watch))

		# install
		commander
			.command('install')
			.description(locale.consoleDescriptionInstall)
			.action(consoleInterface.wrapAction(consoleInterface.install))

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
			.action ->
				commander.emit('help', [])


		# -----------------------------
		# DocPad Listeners

		# Welcome
		docpad.on 'welcome', (data,next) ->
			return consoleInterface.welcomeCallback(data,next)


		# -----------------------------
		# Finish Up

		# Plugins
		docpad.emitSync 'consoleSetup', {consoleInterface,commander}, (err) ->
			return consoleInterface.handleError(err)  if err
			next(null,consoleInterface)

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

	# Handle Error
	handleError: (err) =>
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Handle
		docpad.log('error', locale.consoleError)
		docpad.error(err)
		process.exit(1)

		# Chain
		@

	# Wrap Action
	wrapAction: (action) =>
		consoleInterface = @
		return (command) -> consoleInterface.performAction(command,action)

	# Perform Action
	performAction: (command,action) =>
		# Create
		instanceConfig = @extractConfig(command)
		@docpad.action 'load ready', instanceConfig, (err) =>
			return @completeAction(err)  if err
			action(@completeAction)

		# Chain
		@

	# Complete Action
	completeAction: (err) =>
		# Prepare
		docpad = @docpad
		locale = docpad.getLocale()

		# Handle the error
		if err
			@handleError(err)
		else
			docpad.log('info', locale.consoleSuccess)

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
		commander = @commander
		docpad = @docpad
		locale = docpad.getLocale()
		skeletonNames = []

		# Show
		console.log cliColor.bold locale.skeletonSelectionIntroduction+'\n'
		skeletonsCollection.forEach (skeletonModel) ->
			skeletonName = skeletonModel.get('name')
			skeletonDescription = skeletonModel.get('description').replace(/\n/g,'\n\t')
			skeletonNames.push(skeletonName)
			console.log """
				\t#{cliColor.bold(skeletonName)}
				\t#{skeletonDescription}

				"""

		# Select
		console.log cliColor.bold locale.skeletonSelectionPrompt
		commander.choose skeletonNames, (i) ->
			process.stdin.destroy()
			return next(null, skeletonsCollection.at(i))

		# Chain
		@

	# Welcome Callback
	welcomeCallback: (opts,next) =>
		# Reuqires
		balUtil = require('bal-util')

		# Prepare
		consoleInterface = @
		commander = @commander
		docpad = @docpad
		locale = docpad.getLocale()
		userConfig = docpad.userConfig
		welcomeTasks = new balUtil.Group(next)

		# TOS
		welcomeTasks.push (complete) ->
			return complete()  if docpad.config.prompts is false or userConfig.tos is true

			# Ask the user if they agree to the TOS
			consoleInterface.confirm locale.tosPrompt, true, (ok) ->  docpad.track 'tos', {ok}, (err) ->
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
		welcomeTasks.push (complete) ->
			return complete()  if docpad.config.prompts is false or userConfig.subscribed? or (userConfig.subscribeTryAgain? and (new Date()) > (new Date(userConfig.subscribeTryAgain)))

			# Ask the user if they want to subscribe to the newsletter
			consoleInterface.confirm locale.subscribePrompt, true, (ok) ->  docpad.track 'subscribe', {ok}, (err) ->
				# If they don't want to, that's okay
				unless ok
					# Inform the user that we received their preference
					console.log locale.subscribeIgnore

					# Save their preference in the user configuration
					userConfig.subscribed = false
					docpad.updateUserConfig (err) ->
						return complete(err)  if err
						balUtil.wait(5000,complete)
					return

				# Scan configuration to speed up the process
				commands = [
					['config','--get','user.name']
					['config','--get','user.email']
					['config','--get','github.user']
				]
				balUtil.gitCommands commands, (err,results) ->
					# Ignore error as it just means a config value wasn't defined
					# return next(err)  if err

					# Fetch
					# The or to '' is there because otherwise we will get "undefined" as a string if the value doesn't exist
					userConfig.name or= String(results?[0]?[1] or '').trim() or null
					userConfig.email or= String(results?[1]?[1] or '').trim() or null
					userConfig.username or= String(results?[2]?[1] or '').trim() or null

					# Let the user know we scanned their configuration if we got anything useful
					if userConfig.name or userConfig.email or userConfig.username
						console.log locale.subscribeConfigNotify

					# Tasks
					subscribeTasks = new balUtil.Group (err) ->
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
						docpad.updateUserConfig(userConfig,complete)

					# Name Fallback
					subscribeTasks.push (complete) ->
						consoleInterface.prompt locale.subscribeNamePrompt, userConfig.name, (result) ->
							userConfig.name = result
							complete()

					# Email Fallback
					subscribeTasks.push (complete) ->
						consoleInterface.prompt locale.subscribeEmailPrompt, userConfig.email, (result) ->
							userConfig.email = result
							complete()

					# Username Fallback
					subscribeTasks.push (complete) ->
						consoleInterface.prompt locale.subscribeUsernamePrompt, userConfig.username, (result) ->
							userConfig.username = result
							complete()

					# Save the details
					subscribeTasks.push (complete) ->
						docpad.updateUserConfig(complete)

					# Perform the subscribe
					subscribeTasks.push (complete) ->
						# Inform the user
						console.log locale.subscribeProgress

						# Prepare our connection
						requestUrl = docpad.config.helperUrl+'?'+require('querystring').stringify(
							method: 'add-subscriber'
							name: userConfig.name
							email: userConfig.email
							username: userConfig.username
						)

						# Innitialize our request
						balUtil.readPath requestUrl, (err,body) ->
							# Check
							if err
								docpad.log 'debug', locale.subscribeRequestError, err.message
								return complete(err)

							# Log it to debug console
							docpad.log 'debug', locale.subscribeRequestData, body

							# Inform the user know of the success or not
							try
								data = JSON.parse(body)
								if data.success is false
									complete(new Error(data.error or 'unknown error'))
								else
									complete()
							catch err
								complete(err)

					# Run
					subscribeTasks.sync()

		# Run
		welcomeTasks.sync()

		# Chain
		@

	# Prompt for input
	prompt: (message,fallback,next) ->
		# Prepare
		consoleInterface = @
		commander = @commander

		# Fallback
		message += " [#{fallback}]"  if fallback

		# Log
		commander.prompt message+' ', (result) ->
			# Parse
			unless result.trim() # no value
				if fallback? # has default value
					result = fallback # set to default value
				else # otherwise try again
					return consoleInterface.prompt(message,fallback,next)

			# Forward
			return next(result)

		# Chain
		@

	# Confirm an option
	confirm: (message,fallback,next) ->
		# Prepare
		consoleInterface = @
		commander = @commander

		# Fallback
		if fallback is true
			message += " [Y/n]"
		else if fallback is false
			message += " [y/N]"

		# Log
		commander.prompt message+' ', (ok) ->
			# Parse
			unless ok.trim() # no value
				if fallback? # has default value
					ok = fallback # set to default value
				else # otherwise try again
					return consoleInterface.confirm(message,fallback,next)
			else # parse the value
				ok = /^y|yes|ok|true$/i.test(ok)

			# Forward
			return next(ok)

		# Chain
		@


	# =================================
	# Actions

	generate: (next) =>
		@docpad.action('generate',next)
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

	install: (next) =>
		@docpad.action('install',next)
		@

	render: (next) =>
		# Prepare
		docpad = @docpad
		commander = @commander
		balUtil = require('bal-util')
		opts = {}

		# Prepare filename
		filename = commander.args[0] or null
		basename = pathUtil.basename(filename)
		opts.filename = filename
		opts.renderSingleExtensions = 'auto'

		# Prepare text
		data = ''

		# Render
		useStdin = true
		renderDocument = ->
			# Perform the render
			docpad.action 'render', opts, (err,result) ->
				return docpad.fatal(err)  if err
				# Path
				if commander.out?
					balUtil.writeFile(commander.out, result, next)
				# Stdout
				else
					process.stdout.write(result)
					next()

		# Timeout if we don't have stdin
		timeout = setTimeout(
			->
				# Clear timeout
				timeout = null
				# Skip if we are using stdin
				return  if data.replace(/\s+/,'')
				# Close stdin as we are not using it
				useStdin = false
				stdin.pause()
				# Render the document
				renderDocument()
			,1000
		)

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
			opts.data = data
			renderDocument()

		@

	run: (next) =>
		@docpad.action(
			'run'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)
		@

	server: (next) =>
		@docpad.action('server',next)
		@

	clean: (next) =>
		@docpad.action('clean',next)
		@

	skeleton: (next) =>
		@docpad.action(
			'skeleton'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)
		@

	watch: (next) =>
		@docpad.action('watch',next)
		@


# =================================
# Export

module.exports = ConsoleInterface
