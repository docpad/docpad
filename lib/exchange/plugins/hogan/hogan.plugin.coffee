# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HoganPlugin extends BasePlugin
		# Plugin name
		name: 'hogan'

		# Plugin priority
		priority: 750

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check extensions
			if inExtension is 'hogan'
				# Requires
				hogan = require('hogan.js')

				# Render
				file.content = hogan.compile(file.content).render(templateData)
			
			# Done, return back to DocPad
			return next()