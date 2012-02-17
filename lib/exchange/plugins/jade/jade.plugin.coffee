# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class JadePlugin extends BasePlugin
		# Plugin name
		name: 'jade'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check our extension
			if inExtension is 'jade'
				# Requires
				jade = require('jade')

				# Render
				file.content = jade.compile(file.content, {
					filename: file.fullPath
				})(templateData)

			# Done, return back to DocPad
			return next()
