# Require
DocPad = require(__dirname+'/../lib/docpad')
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Create Commander Instance
commander = require('commander')

# Create DocPad Instance
DocPad.createInstance (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Create Console Interface
	new ConsoleInterface {docpad,commander}, (err,consoleInterface) ->
		# Check
		return console.log(err.stack)  if err

		# Start
		consoleInterface.start()