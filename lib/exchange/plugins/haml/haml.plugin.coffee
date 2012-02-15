# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class HamlPlugin extends BasePlugin
		# Plugin name
		name: 'haml'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension is 'haml'
					haml = require('haml')
					file.content = haml.render file.content, locals: templateData
					next()
				else
					next()
			catch err
				return next(err)
