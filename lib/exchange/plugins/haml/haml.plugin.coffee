# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HamlPlugin extends BasePlugin
		# Plugin name
		name: 'haml'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check our extensions
			if inExtension is 'haml'
				# Requires
				haml = require('haml')

				# Render
				opts.content = haml.render(content, locals:templateData)
		
			# Done, return back to DocPad
			return next()