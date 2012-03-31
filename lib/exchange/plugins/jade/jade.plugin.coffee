# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class JadePlugin extends BasePlugin
		# Plugin name
		name: 'jade'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content,file} = opts

			# Check our extension
			if inExtension is 'jade'
				# Requires
				jade = require('jade')

				# Render
				opts.content = jade.compile(content, {
					filename: file.fullPath
				})(templateData)

			# Done, return back to DocPad
			return next()
