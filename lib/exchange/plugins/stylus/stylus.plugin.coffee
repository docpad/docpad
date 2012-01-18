# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
stylus = null
nib = null

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
				# Load stylus
				stylus = require 'stylus'  unless stylus
				
				# Create our style
				style = stylus(file.content)
					.set('filename', file.fullPath)
					.set('compress', @config.compress)
				
				# Use nib if we want to
				if @config.useNib
					nib = require 'nib'  unless nib
					style.use(nib())

				# Render our style
				style.render (err,output) ->
					return next err  if err
					file.content = output
					next()
			else
				next()
		catch err
			return next err

# Export Plugin
module.exports = StylusPlugin