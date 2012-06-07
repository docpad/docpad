# Necessary
DocPad = require(__dirname+'/../docpad')
ConsoleInterface = require(__dirname+'/../interfaces/console')

# Create Program
program = require('commander')

# Create Instance
docpad = DocPad.createInstance {}, (err) ->
	# Check
	throw err  if err

	# Create Console Interface
	new ConsoleInterface({docpad,program}, (err,consoleInterface) ->
		# Start
		consoleInterface.start()