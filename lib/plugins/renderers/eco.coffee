# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
eco = require 'eco'

# Define Eco Plugin
class EcoPlugin extends DocpadPlugin
	# Plugin name
	name: 'eco'

	# Plugin priority
	priority: 750

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		if inExtension is 'eco'
			try
				file.content = eco.render file.content, templateData
				next()
			catch err
				return next err
		else next()

# Export Eco Plugin
module.exports = EcoPlugin