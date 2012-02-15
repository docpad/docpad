# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class SassPlugin extends BasePlugin
		# Plugin name
		name: 'sass'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension in ['sass','scss'] and outExtension is 'css'
					# Requires
					sass = require('sass')

					# REnder
					file.content = sass.render file.content, filename: file.fullPath
					next()
				else
					next()
			catch err
				return next err
