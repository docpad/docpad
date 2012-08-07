# Require
DocPad = require(__dirname+'/../lib/docpad')

# Create DocPad Instance
DocPad.createInstance (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Fetch the server action
	serverAction = process.env.DOCPAD_SERVER_ACTION or 'generate server'

	# Generate and Serve
	docpad.action serverAction, (err) ->
		# Check
		return console.log(err.stack)  if err

		# Done
		console.log('OK')