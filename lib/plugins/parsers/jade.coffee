# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
jade = require 'jade'

# Define Jade Plugin
class JadePlugin extends DocpadPlugin
	# Plugin name
	name: 'jade'

	# Plugin priority
	priority: 725

	# Plugin extensions
	extensions: ['jade']

	# Render some content
	renderFile: ({fileMeta,templateData}, next) ->
		try
			fileMeta.content = jade.compile(fileMeta.content, {})(templateData)
		catch err
			return next err
		next null

# Export Jade Plugin
module.exports = JadePlugin