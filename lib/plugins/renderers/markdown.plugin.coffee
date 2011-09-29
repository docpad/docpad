# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
markdown = require 'github-flavored-markdown'

# Define Markdown Plugin
class MarkdownPlugin extends DocpadPlugin
	# Plugin name
	name: 'markdown'

	# Plugin priority
	priority: 700

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		if inExtension in ['md','markdown']
			try
				file.content = markdown.parse file.content
				next()
			catch err
				return next err
		else next()

# Export Markdown Plugin
module.exports = MarkdownPlugin