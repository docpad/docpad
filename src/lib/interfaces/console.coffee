# Requires
{cliColor} = require('caterpillar')

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: (opts,next) ->
		# Prepare
		consoleInterface = @
		@docpad = docpad = opts.docpad
		@commander = commander = require('commander')

		# Version information
		version = require(__dirname+'/../../../package.json').version

		# -----------------------------
		# Global config

		commander
			.version(version)
			.option(
				'-e, --env <environment>'
				"the environment name to use for this instance, multiple names can be separated with a comma"
			)
			.option(
				'-d, --debug [logLevel]'
				"the level of debug messages you would like to display, if specified defaults to 7, otherwise 6"
				parseInt
			)
			.option(
				'-f, --force'
				"force a re-install of all modules"
			)

		# -----------------------------
		# Commands

		# run
		commander
			.command('run')
			.description('does everyting: skeleton, generate, watch, server')
			.option(
				'-s, --skeleton <skeleton>'
				"for new projects, instead of being asked for the skeleton, you can specify it here"
			)
			.option(
				'-p, --port <port>'
				"a custom port to use for the server <port>"
				parseInt
			)
			.action(consoleInterface.wrapAction(consoleInterface.run))

		# server
		commander
			.command('server')
			.description('creates a server for your generated project')
			.option(
				'-p, --port <port>'
				"a custom port to use for the server <port>"
				parseInt
			)
			.action(consoleInterface.wrapAction(consoleInterface.server))

		# skeleton
		commander
			.command('skeleton')
			.description('will create a new project in your cwd based off an existing skeleton')
			.option(
				'-s, --skeleton <skeleton>'
				"instead of being asked for the skeleton, you can specify it here"
			)
			.action(consoleInterface.wrapAction(consoleInterface.skeleton))

		# render
		commander
			.command('render [path]')
			.description("render the file at <path> and output its results to stdout")
			.action(consoleInterface.wrapAction(consoleInterface.render))

		# generate
		commander
			.command('generate')
			.description("(re)generates your project")
			.action(consoleInterface.wrapAction(consoleInterface.generate))

		# watch
		commander
			.command('watch')
			.description("watches your project for changes, and (re)generates whenever a change is made")
			.action(consoleInterface.wrapAction(consoleInterface.watch))

		# install
		commander
			.command('install')
			.description("ensure everything is installed correctly")
			.action(consoleInterface.wrapAction(consoleInterface.install))

		# clean
		commander
			.command('clean')
			.description("ensure everything is cleaned correctly (will remove your out directory)")
			.action(consoleInterface.wrapAction(consoleInterface.clean))

		# info
		commander
			.command('info')
			.description("display the information about your docpad instance")
			.action(consoleInterface.wrapAction(consoleInterface.info))

		# help
		commander
			.command('help')
			.description("output the help")
			.action(consoleInterface.wrapAction(consoleInterface.help))

		# unknown
		commander
			.command('*')
			.description("anything else ouputs the help")
			.action ->
				commander.emit('help', [])


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

		# Handle
		docpad.log('error', "Something went wrong with the action")
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

	# Complete an anction
	completeAction: (err) =>
		# Handle the error
		if err
			@handleError(err)
		else
			@docpad.log('info', "The action completed successfully")

		# Chain
		@

	# Extract Configuration
	extractConfig: (customConfig={}) =>
		# Prepare
		config = {}
		commanderConfig = @commander
		sourceConfig = @docpad.initialConfig

		# Rename special configuration
		if commanderConfig.debug
			commanderConfig.debug = 7  if commanderConfig.debug is true
			commanderConfig.logLevel = commanderConfig.debug

		# Apply global configuration
		for own key, value of commanderConfig
			if sourceConfig[key]?
				config[key] = value

		# Apply custom configuration
		for own key, value of customConfig
			if sourceConfig[key]?
				config[key] = value

		# Return config object
		config

	# Select a skeleton
	selectSkeletonCallback: (skeletonsCollection,next) =>
		# Prepare
		commander = @commander
		docpad = @docpad
		skeletonNames = []

		# Show
		console.log cliColor.bold '''
			You are about to create your new project inside your current directory. Below is a list of skeletons to bootstrap your new project:

			'''
		skeletonsCollection.forEach (skeletonModel) ->
			skeletonName = skeletonModel.get('name')
			skeletonDescription = skeletonModel.get('description').replace(/\n/g,'\n\t')
			skeletonNames.push(skeletonName)
			console.log """
				\t#{cliColor.bold(skeletonName)}
				\t#{skeletonDescription}

				"""

		# Select
		console.log cliColor.bold '''
			Which skeleton will you use?
			'''
		commander.choose skeletonNames, (i) ->
			return next(null, skeletonsCollection.at(i))

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
		docpad.setLogLevel(5)  unless docpad.getLogLevel() is 7
		commander = @commander
		opts = {}

		# Prepare filename
		filename = commander.args[0] or null
		if !filename or consoleInterface.split('.').length <= 2 # [name,ext,ext] = 3 parts
			opts.renderSingleExtensions = true
		opts.filename = filename

		# Prepare text
		opts.data = ''

		# Render
		useStdin = true
		renderDocument = ->
			docpad.action 'render', opts, (err,result) ->
				return docpad.fatal(err)  if err
				process.stdout.write(result+'\n')
				next()

		# Timeout if we don't have stdin
		timeout = setTimeout(
			->
				# Clear timeout
				timeout = null
				# Skip if we are using stdin
				return  if opts.data.replace(/\s+/,'')
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
		stdin.on 'data', (data) ->
			opts.data += data.toString()
		process.stdin.on 'end', ->
			return  unless useStdin
			if timeout
				clearTimeout(timeout)
				timeout = null
			renderDocument()

		@

	run: (next) =>
		@docpad.action(
			'all'
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
