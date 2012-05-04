# Necessary
DocPad = require(__dirname+'/../docpad')
ConsoleInterface = require(__dirname+'/../interfaces/console')

# Create Program
program = require('commander')

# Configure Instance
docpadConfig = {}
docpadConfig.skeleton = program.skeleton  if program.skeleton
docpadConfig.port = program.port  if program.port

# Create Instance
docpad = DocPad.createInstance docpadConfig, (err) ->
	# Check
	throw err  if err

	# Create Console Interface
	consoleInterface = new ConsoleInterface({docpad,program})

	# Start
	consoleInterface.start()