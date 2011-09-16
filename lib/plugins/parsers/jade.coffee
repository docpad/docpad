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
	renderFile: ({file,templateData}, next) ->
		try
			file.content = jade.compile(file.content, {})(templateData)
		catch err
			return next err
		next null

# Export Jade Plugin
module.exports = JadePlugin