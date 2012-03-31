# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class MarkdownPlugin extends BasePlugin
		# Plugin name
		name: 'markdown'

		# Plugin priority
		priority: 700

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts

			# Check our extensions
			if inExtension in ['md','markdown'] and outExtension is 'html'
				# Requires
				markdown = require('github-flavored-markdown')

				# Render
				opts.content = markdown.parse(content)
	
			# Done, return back to DocPad
			return next()