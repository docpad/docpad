# ---------------------------------
# Requires

# Standard Library
pathUtil = require('path')

# Local
{DocPad,queryEngine,Backbone,createInstance,createMiddlewareInstance} = require('./lib/docpad')


# ---------------------------------
# Export
module.exports =
	# Pre-Defined
	DocPad: DocPad
	queryEngine: queryEngine
	Backbone: Backbone
	createInstance: createInstance
	createMiddlewareInstance: createMiddlewareInstance

	# Require a local DocPad file
	require: (relativePath) ->
		# Absolute the path
		absolutePath = pathUtil.normalize(pathUtil.join(__dirname,relativePath))

		# now check we if are actually a local docpad file
		if absolutePath.replace(__dirname,'') is absolutePath
			throw new Error("docpad.require is limited to local docpad files only: #{relativePath}")

		# now check if the path actually exists
		try
			require.resolve(absolutePath)

		# if it doesn't exist, then try add the lib directory
		catch err
			absolutePath = pathUtil.join(__dirname,'lib',relativePath)
			require.resolve(absolutePath)

		# finally, require the path
		return require(absolutePath)
