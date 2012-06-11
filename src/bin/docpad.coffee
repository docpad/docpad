# Necessary
DocPad = require(__dirname+'/../lib/docpad')
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Create Program
program = require('commander')

# Create Instance
docpad = DocPad.createInstance {}, (err) ->
	# Check
	throw err  if err

	# Create Console Interface
	new ConsoleInterface {docpad,program}, (err,consoleInterface) ->
		# Check
		throw err  if err

		# Start
		consoleInterface.start()