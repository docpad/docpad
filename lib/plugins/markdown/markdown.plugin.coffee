# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
markdown = require('markdown').markdown

# Define Plugin
class MarkdownPlugin extends DocpadPlugin
	# Plugin name
	name: 'markdown'

	# Plugin priority
	priority: 700

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension in ['md','markdown'] and outExtension is 'html'
				file.content = markdown.toHTML file.content
				next()
			else
				next()
		catch err
			return next(err)

# Export Plugin
module.exports = MarkdownPlugin
