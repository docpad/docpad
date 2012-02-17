# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class SassPlugin extends BasePlugin
		# Plugin name
		name: 'sass'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check extensions
			if inExtension in ['sass','scss'] and outExtension is 'css'
				# Requires
				sass = require('sass')

				# Render
				file.content = sass.render file.content, filename: file.fullPath

			# Done, return back to DocPad
			return next()