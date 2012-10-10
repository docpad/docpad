# Require
DocPad = require(__dirname+'/../lib/docpad')

# DocPad Configuration
docpadConfig = {}
serverAction = process.env.DOCPAD_SERVER_ACTION or 'generate server'

# --action <value>
(->
	actionArgumentIndex = process.argv.indexOf('--action')
	if actionArgumentIndex isnt -1
		serverAction = process.argv[actionArgumentIndex+1]
)()

# --port <value>
(->
	portArgument = null
	portArgumentIndex = process.argv.indexOf('--port')
	if portArgumentIndex isnt -1
		portArgument = process.argv[portArgumentIndex+1]
		if isNaN(portArgument)
			portArgument = null
		else
			portArgument = parseInt(portArgument,10)
	if portArgument
		docpadConfig.port = portArgument
)()

# Create DocPad Instance
DocPad.createInstance docpadConfig, (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Generate and Serve
	docpad.action serverAction, (err) ->
		# Check
		return console.log(err.stack)  if err

		# Done
		console.log('OK')