# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HoganPlugin extends BasePlugin
		# Plugin name
		name: 'hogan'

		# Plugin priority
		priority: 750

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check extensions
			if inExtension is 'hogan'
				# Requires
				hogan = require('hogan.js')

				# Render
				opts.content = hogan.compile(content).render(templateData)
			
			# Done, return back to DocPad
			return next()