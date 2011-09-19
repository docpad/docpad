# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
jade = require 'jade'

# Define Jade Plugin
class JadePlugin extends DocpadPlugin
	# Plugin name
	name: 'jade'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		if inExtension is 'jade'
			try
				file.content = jade.compile(file.content, {})(templateData)
				next()
			catch err
				return next err
		else next()

# Export Jade Plugin
module.exports = JadePlugin