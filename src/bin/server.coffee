# Require
DocPad = require(__dirname+'/../lib/docpad')

# Create DocPad Instance
DocPad.createInstance (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Generate and Serve
	docpad.action 'generate server', (err) ->
		# Check
		return console.log(err.stack)  if err

		# Done
		console.log('OK')