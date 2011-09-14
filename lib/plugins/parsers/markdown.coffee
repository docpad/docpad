# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Markdown Plugin
class MarkdownPlugin extends DocpadPlugin
	# Plugin Name
	name: 'markdown'

	# Parse Extensions
	parseExtensions: '.md'

	# Parse a document
	parseDocument: ({fileMeta}, next) ->
		fileMeta.extension = '.html'
		fileMeta.content = markdown.parse fileMeta.content
		next()

# Export Markdown Plugin
module.exports = MarkdownPlugin