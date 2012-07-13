# Requires
_ = require('underscore')
caterpillar = require('caterpillar')
{cliColor} = caterpillar

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: ({@docpad,@commander},next) ->
		# Prepare
		me = consoleInterface = @
		docpad = @docpad
		commander = @commander

		# Ensure our actions always have the scope of this instance
		_.bindAll(@, 'run', 'server', 'skeleton', 'render', 'generate', 'watch', 'install', 'clean', 'info', 'cli', 'exit', 'help', 'actionCompleted', 'handleError')

		# -----------------------------
		# Global config

		commander
			.version(docpad.getVersion() or 'unknown')
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
			.action (command) ->
				me.applyConfiguration(command)
				me.run(me.actionCompleted)

		# server
		commander
			.command('server')
			.description('creates a server for your generated project')
			.option(
				'-p, --port <port>'
				"a custom port to use for the server <port>"
				parseInt
			)
			.action (command) ->
				me.applyConfiguration(command)
				me.server(me.actionCompleted)

		# skeleton
		commander
			.command('skeleton')
			.description('will create a new project in your cwd based off an existing skeleton')
			.option(
				'-s, --skeleton <skeleton>'
				"instead of being asked for the skeleton, you can specify it here"
			)
			.action (command) ->
				me.applyConfiguration(command)
				me.skeleton(me.actionCompleted)

		# render
		commander
			.command('render [path]')
			.description("render the file at <path> and output its results to stdout")
			.action (command) ->
				me.applyConfiguration(command)
				me.render(me.actionCompleted)

		# generate
		commander
			.command('generate')
			.description("(re)generates your project")
			.action (command) ->
				me.applyConfiguration(command)
				me.generate(me.actionCompleted)

		# watch
		commander
			.command('watch')
			.description("watches your project for changes, and (re)generates whenever a change is made")
			.action (command) ->
				me.applyConfiguration(command)
				me.watch(me.actionCompleted)

		# install
		commander
			.command('install')
			.description("ensure everything is installed correctly")
			.action (command) ->
				me.applyConfiguration(command)
				me.install(me.actionCompleted)

		# clean
		commander
			.command('clean')
			.description("ensure everything is cleaned correctly (will remove your out directory)")
			.action (command) ->
				me.applyConfiguration(command)
				me.clean(me.actionCompleted)

		# info
		commander
			.command('info')
			.description("display the information about your docpad instance")
			.action (command) ->
				me.applyConfiguration(command)
				me.info(me.actionCompleted)

		# cli
		commander
			.command('cli')
			.description("start the interactive cli")
			.action (command) ->
				me.applyConfiguration(command)
				me.cli(me.actionCompleted)

		# exit
		commander
			.command('exit')
			.description("exit the interactive cli")
			.action (command) ->
				me.applyConfiguration(command)
				me.exit(me.actionCompleted)

		# help
		commander
			.command('help')
			.description("output the help")
			.action (command) ->
				me.applyConfiguration(command)
				me.help(me.actionCompleted)

		# unknown
		commander
			.command('*')
			.description("anything else ouputs the help")
			.action ->
				commander.emit 'help', []

		# -----------------------------
		# Finish Up

		# Plugins
		docpad.emitSync 'consoleSetup', {consoleInterface,commander}, (err) ->
			return handleError(err)  if err
			next?(null,me)


	# =================================
	# Helpers

	# Start the CLI
	start: (argv) ->
		@commander.parse(argv or process.argv)
		@

	# Get the commander
	getCommander: ->
		@commander

	# Handle Error
	handleError: (err) ->
		# Prepare
		docpad = @docpad

		# Handle
		docpad.log('error', "Something went wrong with the action")
		docpad.error(err)
		process.exit(1)

	# Action Completed
	# What to do once an action completes
	# Necessary, as we may want to exist
	# Or we may want to continue with the CLI
	actionCompleted: (err) ->
		# Prepare
		docpad = @docpad
		commander = @commander

		# Handle the error
		if err
			@handleError(err)
		else
			docpad.log('info', "The action completed successfully")

		# Exit or return to cli
		if commander.mode is 'cli'
			console.log('')
			commander.emit('cli', [])

		# Chain
		@

	# Parse the Configuration
	applyConfiguration: (customConfig={}) ->
		# Prepare
		docpad = @docpad
		commander = @commander
		commanderConfig = @commander

		# Apply commander configuration
		if commanderConfig.debug
			commanderConfig.debug = 7  if commanderConfig.debug is true
			docpad.setLogLevel(commanderConfig.debug)
			delete commanderConfig.debug
		for own key, value of commanderConfig
			if docpad.config[key]?
				docpad.config[key] = value

		# Apply custom configuration
		for own key, value of customConfig
			if docpad.config[key]?
				docpad.config[key] = value

		# Return updated config object
		docpad.config

	# Welcome
	welcome: ->
		# Check
		return  if @welcomed
		@welcomed = true

		# Prepare
		docpad = @docpad
		version = docpad.getVersion()
		env = docpad.getEnvironments()

		# Log
		docpad.log 'info', "Welcome to DocPad v#{version}"
		docpad.log 'info', "Environment: #{env}"

		# Chain
		@

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

	cli: (next) ->
		# Prepare
		@welcome()
		commander = @commander

		# Handle
		commander.mode = 'cli'
		commander.promptSingleLine 'What would you like to do now?\n> ',  (input) ->
			args = input.split /\s+/g
			if args.length
				if args[0] is 'docpad'
					args.shift()
			args.unshift process.argv[0]
			args.unshift process.argv[1]
			commander.parse(args)

	exit: ->
		process.exit(0)

	generate: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('generate',next)

	help: (next) ->
		# Prepare
		@welcome()

		# Handle
		console.log @commander.helpInformation()
		next()

	info: (next) ->
		# Prepare
		@welcome()

		# Handle
		console.log require('util').inspect @docpad.config
		next()

	install: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('install',next)

	render: (next) ->
		# Prepare
		docpad = @docpad
		docpad.setLogLevel(5)  unless docpad.getLogLevel() is 7
		commander = @commander
		opts = {}

		# Prepare filename
		filename = commander.args[0] or null
		if !filename or filename.split('.').length <= 2 # [name,ext,ext] = 3 parts
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

	run: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action(
			'all'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)

	server: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('server',next)

	clean: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('clean',next)

	skeleton: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action(
			'skeleton'
			{selectSkeletonCallback: @selectSkeletonCallback}
			next
		)

	watch: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('watch',next)


# =================================
# Export

module.exports = ConsoleInterface
