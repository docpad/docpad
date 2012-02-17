# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MovePlugin extends BasePlugin
		# Plugin name
		name: 'move'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check our extensions
			if inExtension in ['move'] and outExtension is 'js'
				# Requires
				move = require('move')

				# Render
				file.content = move.compile(file.content)
		
			# Done, return back to DocPad
			return next()