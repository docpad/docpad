# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class RoyPlugin extends BasePlugin
		# Plugin name
		name: 'roy'

		# Plugin priority
		priority: 700

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check extensions
			if inExtension in ['roy'] and outExtension is 'js'
				# Requires
				roy = require('roy')

				# Render
				opts.content = roy.compile(content.replace(/^\s+/,'')).output
			
			# Done, return back to DocPad
			return next()