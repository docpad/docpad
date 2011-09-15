# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
eco = require 'eco'

# Define Eco Plugin
class EcoPlugin extends DocpadPlugin
	# Plugin name
	name: 'eco'

	# Plugin priority
	priority: 750

	# Plugin extensions
	extensions: true

	# Render some content
	renderFile: ({fileMeta,templateData}, next) ->
		try
			fileMeta.content = eco.render fileMeta.content, templateData
		catch err
			return next err
		next null

# Export Eco Plugin
module.exports = EcoPlugin