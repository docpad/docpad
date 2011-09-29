# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
stylus = require 'stylus'

# Define Stylus Plugin
class StylusPlugin extends DocpadPlugin
	# Plugin name
	name: 'stylus'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		if inExtension is 'stylus'
			try
				stylus.render file.content, {filename: file.basename}, (err,output) ->
					return next err  if err
					file.content = output
					next()
			catch err
				return next err
		else next()

# Export Stylus Plugin
module.exports = StylusPlugin