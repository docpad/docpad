# Require
DocPad = require(__dirname+'/../lib/docpad')
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Create DocPad Instance
DocPad.createInstance {load:false}, (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Create Console Interface
	new ConsoleInterface {docpad}, (err,consoleInterface) ->
		# Check
		return console.log(err.stack)  if err

		# Start
		consoleInterface.start()