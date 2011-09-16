# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
markdown = require 'github-flavored-markdown'

# Define Markdown Plugin
class MarkdownPlugin extends DocpadPlugin
	# Plugin name
	name: 'markdown'

	# Plugin priority
	priority: 700

	# Plugin extensions
	extensions: ['md','markdown']

	# Render some content
	renderFile: ({file,templateData}, next) ->
		try
			file.content = markdown.parse file.content
		catch err
			return next err
		next null

# Export Markdown Plugin
module.exports = MarkdownPlugin