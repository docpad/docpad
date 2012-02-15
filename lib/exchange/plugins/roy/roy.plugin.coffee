# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class RoyPlugin extends BasePlugin
		# Plugin name
		name: 'roy'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension in ['roy'] and outExtension is 'js'
					# Requires
					roy = require('roy')

					# Render
					file.content = roy.compile(file.content.replace(/^\s+/,'')).output
					next()
				else
					next()
			catch err
				return next(err)