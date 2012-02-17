# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class EcoPlugin extends BasePlugin
		# Plugin name
		name: 'eco'

		# Plugin priority
		priority: 750

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check extensions
			if inExtension is 'eco'
				# Requires
				eco = require('eco')

				# Render
				file.content = eco.render file.content, templateData
		
			# Done, return back to DocPad
			return next()