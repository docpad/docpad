# Require
DocPad = require(__dirname+'/../lib/docpad')
ConsoleInterface = require(__dirname+'/../lib/interfaces/console')

# Fetch action
action =
	# we should eventually do a load always
	# but as it is a big change of functionality, lets only do it inclusively for now
	if process.argv[1...].join(' ').indexOf('deploy') isnt -1
		'load'
	else
		false

# Create DocPad Instance
DocPad.createInstance {action}, (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Create Console Interface
	new ConsoleInterface {docpad}, (err,consoleInterface) ->
		# Check
		return console.log(err.stack)  if err

		# Start
		consoleInterface.start()