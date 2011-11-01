# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
stylus = require 'stylus'
nib = require 'nib'

# Define Plugin
class StylusPlugin extends DocpadPlugin
	# Plugin name
	name: 'stylus'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension in ['styl','stylus'] and outExtension is 'css'
				stylus(file.content)
					.set('filename', file.fullPath)
					.set('compress', true)
					.use(nib())
					.render (err,output) ->
						return next err  if err
						file.content = output
						next()
			else
				next()
		catch err
			return next err

# Export Plugin
module.exports = StylusPlugin