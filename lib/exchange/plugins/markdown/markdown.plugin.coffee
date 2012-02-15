# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension in ['md','markdown'] and outExtension is 'html'
					# Requires
					markdown = require('github-flavored-markdown')

					# Render
					file.content = markdown.parse file.content
					next()
				else
					next()
			catch err
				return next(err)
