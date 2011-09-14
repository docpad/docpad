# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
haml = require 'hamljs'

# Define Haml Plugin
class HamlPlugin extends DocpadPlugin
	# Plugin Name
	name: 'haml'

	# Parse Extensions
	parseExtensions: '.haml'

	# Parse a document
	parseDocument: ({fileMeta}, next) ->
		fileMeta.extension = '.html'
		fileMeta.content = haml.render fileMeta.content
		next()

# Export Haml Plugin
module.exports = HamlPlugin