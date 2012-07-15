# Require
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Create Console Interface
new ConsoleInterface {}, (err,consoleInterface) ->
	# Check
	return console.log(err.stack)  if err

	# Start
	consoleInterface.start()