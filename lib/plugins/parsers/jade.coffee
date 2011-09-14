# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Jade Plugin
class JadePlugin extends DocpadPlugin
	# Plugin Name
	name: 'jade'

	# Parse Extensions
	parseExtensions: '.jade'

	# Parse a document
	parseDocument: ({fileMeta}, next) ->
		fileMeta.extension = '.html'
		fileMeta.content = jade.render fileMeta.content
		next()

# Export Jade Plugin
module.exports = JadePlugin