# Requires
DocpadParser = require "#{__dirname}/../parser.coffee"
gfm = false

# Define Markdown Parser
class MarkdownParser extends DocpadParser
	inExtension: '.jade'
	outExtension: '.html'
	parseContent: (content,next) ->
		result = jade.render content
		next false, result

# Export Markdown Parser
module.exports = MarkdownParser