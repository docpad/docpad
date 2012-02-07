# Export Plugin
module.exports = (BasePlugin) ->
	# Required
	roy = null

	# Define Plugin
	class MovePlugin extends BasePlugin
		# Plugin name
		name: 'move'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension in ['move'] and outExtension is 'js'
					move = require('move')  unless roy
					file.content = move.compile(file.content)
					next()
				else
					next()
			catch err
				return next(err)