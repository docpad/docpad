# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HamlPlugin extends BasePlugin
		# Plugin name
		name: 'haml'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check our extensions
			if inExtension is 'haml'
				# Requires
				haml = require('haml')

				# Render
				file.content = haml.render file.content, locals: templateData
		
			# Done, return back to DocPad
			return next()