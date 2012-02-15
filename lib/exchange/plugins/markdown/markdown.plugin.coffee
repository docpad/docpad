# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	markdown = require('github-flavored-markdown')

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
					file.content = markdown.parse file.content
					next()
				else
					next()
			catch err
				return next(err)
