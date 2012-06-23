# Requires
_ = require('underscore')
caterpillar = require('caterpillar')
{cliColor} = caterpillar

# Console Interface
class ConsoleInterface

	# Setup the CLI
	constructor: ({@docpad,@program},next) ->
		# Prepare
		me = @
		program = @program
		docpad = @docpad

		# Ensure our actions always have the scope of this instance
		_.bindAll(@, 'run', 'server', 'skeleton', 'render', 'generate', 'watch', 'install', 'clean', 'info', 'cli', 'exit', 'help', 'actionCompleted', 'handleError')

		# -----------------------------
		# Global config

		program
			.version(docpad.getVersion() or 'unknown')
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
		program
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
		program
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
		program
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
		program
			.command('render <path>')
			.description("render the file at <path> and output its results to stdout")
			.action (command) ->
				me.applyConfiguration(command)
				me.render(me.actionCompleted)

		# generate
		program
			.command('generate')
			.description("(re)generates your project")
			.action (command) ->
				me.applyConfiguration(command)
				me.generate(me.actionCompleted)

		# watch
		program
			.command('watch')
			.description("watches your project for changes, and (re)generates whenever a change is made")
			.action (command) ->
				me.applyConfiguration(command)
				me.watch(me.actionCompleted)

		# install
		program
			.command('install')
			.description("ensure everything is installed correctly")
			.action (command) ->
				me.applyConfiguration(command)
				me.install(me.actionCompleted)

		# clean
		program
			.command('clean')
			.description("ensure everything is cleaned correctly (will remove your out directory)")
			.action (command) ->
				me.applyConfiguration(command)
				me.clean(me.actionCompleted)

		# info
		program
			.command('info')
			.description("display the information about your docpad instance")
			.action (command) ->
				me.applyConfiguration(command)
				me.info(me.actionCompleted)

		# cli
		program
			.command('cli')
			.description("start the interactive cli")
			.action (command) ->
				me.applyConfiguration(command)
				me.cli(me.actionCompleted)

		# exit
		program
			.command('exit')
			.description("exit the interactive cli")
			.action (command) ->
				me.applyConfiguration(command)
				me.exit(me.actionCompleted)

		# help
		program
			.command('help')
			.description("output the help")
			.action (command) ->
				me.applyConfiguration(command)
				me.help(me.actionCompleted)

		# unknown
		program
			.command('*')
			.description("anything else ouputs the help")
			.action ->
				program.emit 'help', []

		# -----------------------------
		# Finish Up

		# Plugins
		docpad.emitSync 'consoleSetup', {interface:@,program}, (err) ->
			return handleError(err)  if err
			next?(null,me)


	# =================================
	# Helpers

	# Start the CLI
	start: (argv) ->
		@program.parse(argv or process.argv)
		@

	# Get the program
	getProgram: ->
		@program

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
		program = @program

		# Handle the error
		if err
			@handleError(err)
		else
			docpad.log('info', "The action completed successfully")

		# Exit or return to cli
		if program.mode is 'cli'
			console.log('')
			program.emit('cli', [])

		# Chain
		@

	# Parse the Configuration
	applyConfiguration: (customConfig={}) ->
		# Prepare
		docpad = @docpad
		program = @program
		programConfig = @program

		# Apply program configuration
		if programConfig.debug
			programConfig.debug = 7  if programConfig.debug is true
			docpad.setLogLevel(programConfig.debug)
			delete programConfig.debug
		for own key, value of programConfig
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
		# Prepare
		docpad = @docpad
		version = docpad.getVersion()

		# Check
		return  if @welcomed
		@welcomed = true

		# Log
		docpad.log 'info', "Welcome to DocPad v#{version}"

		# Chain
		@

	# Select a skeleton
	selectSkeletonCallback: (skeletonsCollection,next) =>
		# Prepare
		program = @program
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
		program.choose skeletonNames, (i) ->
			return next(null, skeletonsCollection.at(i))

		# Chain
		@


	# =================================
	# Actions

	cli: (next) ->
		# Prepare
		@welcome()
		program = @program

		# Handle
		program.mode = 'cli'
		program.promptSingleLine 'What would you like to do now?\n> ',  (input) ->
			args = input.split /\s+/g
			if args.length
				if args[0] is 'docpad'
					args.shift()
			args.unshift process.argv[0]
			args.unshift process.argv[1]
			program.parse args

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
		console.log @program.helpInformation()
		next?()

	info: (next) ->
		# Prepare
		@welcome()

		# Handle
		console.log require('util').inspect @docpad.config
		next?()

	install: (next) ->
		# Prepare
		@welcome()

		# Handle
		@docpad.action('install',next)

	render: (next) ->
		# Prepare
		docpad = @docpad
		docpad.setLogLevel(5)
		program = @program

		# Check
		if program.args.length is 1
			return docpad.error("You must pass a filename to the render command")

		# File details
		details =
			filename: program.args[0]
			content: ''

		# Prepare
		useStdin = true
		renderDocument = ->
			docpad.action 'render', details, (err,document) ->
				throw err  if err
				console.log document.get('contentRendered')
				next?()

		# Timeout if we don't have stdin
		timeout = setTimeout(
			->
				# Clear timeout
				timeout = null
				# Skip if we are using stdin
				return  if details.content.replace(/\s+/,'')
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
			details.content += data.toString()
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
