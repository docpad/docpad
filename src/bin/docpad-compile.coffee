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
action = (getArgument('action', null, 'generate')+' '+getArgument('watch', 'watch', '')).trim()


# ---------------------------------
# DocPad Configuration
docpadConfig = {}
docpadConfig.rootPath = getArgument('rootPath', null, process.cwd())
docpadConfig.outPath = getArgument('outPath', null, docpadConfig.rootPath+'/out')
docpadConfig.srcPath = getArgument('srcPath', null, docpadConfig.rootPath+'/src')

docpadConfig.documentsPaths = (->
	documentsPath = getArgument('documentsPath')
	if documentsPath?
		documentsPath = docpadConfig.srcPath  if documentsPath is 'auto'
	else
		documentsPath = docpadConfig.srcPath+'/documents'
	return [documentsPath]
)()

docpadConfig.port = (->
	port = getArgument('port')
	port = parseInt(port,10)  if port and isNaN(port) is false
	return port
)()

docpadConfig.renderSingleExtensions = (->
	renderSingleExtensions = getArgument('renderSingleExtensions', null, 'auto')
	if renderSingleExtensions in ['true','yes']
		renderSingleExtensions = true
	else if renderSingleExtensions in ['false','no']
		renderSingleExtensions = false
	return renderSingleExtensions
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
