# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
haml = require 'hamljs'

# Define Haml Plugin
class HamlPlugin extends DocpadPlugin
	# Plugin name
	name: 'haml'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		if inExtension is 'haml'
			try
				file.content = haml.render file.content, locals: templateData
				next()
			catch err
				return next err
		else next()

# Export Haml Plugin
module.exports = HamlPlugin