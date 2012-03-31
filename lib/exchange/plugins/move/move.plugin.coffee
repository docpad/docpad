# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MovePlugin extends BasePlugin
		# Plugin name
		name: 'move'

		# Plugin priority
		priority: 700

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check our extensions
			if inExtension in ['move'] and outExtension is 'js'
				# Requires
				move = require('move')

				# Render
				opts.content = move.compile(content)
		
			# Done, return back to DocPad
			return next()