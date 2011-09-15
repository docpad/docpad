# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
haml = require 'hamljs'

# Define Haml Plugin
class HamlPlugin extends DocpadPlugin
	# Plugin name
	name: 'haml'

	# Plugin priority
	priority: 725

	# Plugin extensions
	extensions: ['haml']

	# Render some content
	renderFile: ({fileMeta,templateData}, next) ->
		try
			fileMeta.content = haml.render fileMeta.content, locals: templateData
		catch err
			return next err
		next null

# Export Haml Plugin
module.exports = HamlPlugin