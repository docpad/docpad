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
			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension is 'html'
				# Requires
				markdown = require('github-flavored-markdown')

				# Render
				file.content = markdown.parse(file.content)
	
			# Done, return back to DocPad
			return next()