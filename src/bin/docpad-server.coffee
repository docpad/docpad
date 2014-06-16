# ---------------------------------
# Requires

# Local
DocPad = require('../lib/docpad')


# ---------------------------------
# Helpers

# Prepare
getArgument = (name,value=null,defaultValue=null) ->
	result = defaultValue
	argumentIndex = process.argv.indexOf("--#{name}")
	if argumentIndex isnt -1
		result = value ? process.argv[argumentIndex+1]
	return result

# DocPad Action
action = getArgument('action', null, 'server generate')


# ---------------------------------
# DocPad Configuration
docpadConfig = {}

docpadConfig.port = (->
	port = getArgument('port')
	port = parseInt(port,10)  if port and isNaN(port) is false
	return port
)()


# ---------------------------------
# Create DocPad Instance
DocPad.createInstance docpadConfig, (err,docpad) ->
	# Check
	return console.log(err.stack)  if err

	# Generate and Serve
	docpad.action action, (err) ->
		# Check
		return console.log(err.stack)  if err

		# Done
		console.log('OK')
