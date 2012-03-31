# Requires
fs = require('fs')
path = require('path')
{cliColor} = require('caterpillar')
DocPad = require(path.join __dirname, '..', 'docpad.coffee')

# =================================
# The Console Interface

class ConsoleInterface

	# =================================
	# Initialize

	constructor: ({@docpad,@program}) ->

	start: ->
		# Prepare
		me = @
		program = @program
		docpad = @docpad
		logger = @docpad.logger

		# Parse the Configuration
		applyConfiguration = (customConfig={}) ->
			# Prepare
			programConfig = program
			# Apply program configuration
			for own key, value of programConfig
				if docpad.config[key]?
					docpad.config[key] = value
			# Apply custom configuration
			for own key, value of customConfig
				if docpad.config[key]?
					docpad.config[key] = value
			# Return updated config object
			docpad.config
		
		# Fire when an action has completed
		actionCompleted = (err) ->
			# Handle the error
			if err
				logger.log 'error', "Something went wrong with the action"
				logger.log err
				process.exit(1)
			else
				logger.log 'info', "The action completed successfully"
			
			# Exit or return to cli
			if program.mode is 'cli'
				console.log ''
				program.emit 'cli', []
		
		# Add the Action
		addAction = (actionName,actionDescription) ->
			program
				.command(actionName)
				.description(actionDescription)
				.action ->
					applyConfiguration()
					me[actionName](actionCompleted)


		# Version
		program.version(docpad.version or 'unknown')

		# Options
		program
			.option(
				'-s, --skeleton <skeleton>'
				"the skeleton to create your project from, defaults to bootstrap"
			)
			.option(
				'-p, --port <port>'
				"the port to use for the docpad server <port>, defaults to 9788"
				parseInt
			) 
			.option(
				'-d, --debug [level]'
				"the level of debug messages you would like to display, if specified defaults to 7, otherwise 6"
				parseInt
			)
		
		# Actions
		actions =
			'run':
				'does everyting: scaffold, generate, watch, server'
			'skeleton':
				'fills the current working directory with the optional --skeleton'
			'render':
				'render a given file path, if stdin is provided use that in combination'
			'generate':
				'(re)generates the output'
			'watch':
				'(re)generates the output whenever a change is made'
			'server':
				'creates a docpad server instance with the optional --port'
			'install':
				'ensure docpad is installed correctly'
			'cli':
				'start the interactive cli'
			'clean':
				'clean everything (will remove your outdir)'
			'exit':
				'exit the cli'
			'info':
				'display information about our docpad instance'
			'help':
				'display the cli help'
		for own actionName, actionDescription of actions
			addAction(actionName,actionDescription)
		
		# Unknown
		program
			.command('*')
			.action ->
				program.emit 'help', []
			
		# Start
		@program.parse(process.argv)

	# Welcome
	welcome: ->
		# Prepare
		docpad = @docpad
		logger = @docpad.logger

		# Check
		return  if @welcomed
		@welcomed = true

		# Log
		logger.log 'info', "Welcome to DocPad v#{docpad.version}"

	# Select a skeleton
	selectSkeletonCallback: (skeletons,next) =>
		# Prepare
		program = @program
		docpad = @docpad
		ids = []

		# Show
		console.log cliColor.bold '''
			You are about to create your new project inside your current directory. Below is a list of skeletons to bootstrap your new project:

			'''
		for own skeletonId, skeleton of skeletons
			ids.push(skeletonId)
			console.log """
				\t#{cliColor.bold(skeletonId)}
				\t#{skeleton.description}

				"""
		
		# Select
		console.log cliColor.bold '''
			Which skeleton will you use?
			'''
		program.choose ids, (i) ->
			skeletonId = ids[i]
			return next(null,skeletonId)
		
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
		docpad = @docpad

		# Handle
		docpad.action('generate',next)

	help: (next) ->
		# Prepare
		@welcome()
		program = @program
		
		# Handle
		console.log program.helpInformation()
		next()
	
	info: (next) ->
		# Prepare
		@welcome()
		docpad = @docpad

		# Handle
		console.log require('util').inspect docpad.config
		next()
	
	install: (next) ->
		# Prepare
		@welcome()
		docpad = @docpad

		# Handle
		docpad.action('install',next)
	
	render: ->
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
				console.log document.contentRendered
				process.exit(0)
		
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
		docpad = @docpad
		opts =
			selectSkeletonCallback: @selectSkeletonCallback

		# Handle
		docpad.action('all',opts,next)

	server: (next) ->
		# Prepare
		@welcome()
		docpad = @docpad

		# Handle
		docpad.action('server',next)
	
	clean: (next) ->
		# Prepare
		@welcome()
		docpad = @docpad

		# Handle
		docpad.action('clean',next)
	
	skeleton: (next) ->
		# Prepare
		@welcome()
		program = @program
		docpad = @docpad
		opts =
			selectSkeletonCallback: @selectSkeletonCallback
		
		# Handle
		docpad.action('skeleton', opts, next)
	
	watch: (next) ->
		# Prepare
		@welcome()
		docpad = @docpad

		# Handle
		docpad.action('watch',next)
	

# =================================
# Export

module.exports = ConsoleInterface
