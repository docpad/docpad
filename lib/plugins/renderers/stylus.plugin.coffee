# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
stylus = require 'stylus'

# Define Plugin
class StylusPlugin extends DocpadPlugin
	# Plugin name
	name: 'stylus'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension is 'stylus' and outExtension is 'css'
				stylus.render file.content, {filename: file.basename}, (err,output) ->
					return next err  if err
					file.content = output
					next()
			else
				next()
		catch err
			return next err

# Export Plugin
module.exports = StylusPlugin