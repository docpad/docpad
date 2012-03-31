# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class EcoPlugin extends BasePlugin
		# Plugin name
		name: 'eco'

		# Plugin priority
		priority: 750

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check extensions
			if inExtension is 'eco'
				# Requires
				eco = require('eco')

				# Render
				opts.content = eco.render(content,templateData)
			
			# Done, return back to DocPad
			return next()