# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class StylusPlugin extends BasePlugin
		# Plugin name
		name: 'stylus'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content,file} = opts

			# Check extensions
			if inExtension in ['styl','stylus'] and outExtension is 'css'
				# Load stylus
				stylus = require('stylus')
				
				# Create our style
				style = stylus(content)
					.set('filename', file.fullPath)
					.set('compress', @config.compress)
				
				# Use nib if we want to
				if @config.useNib
					nib = require('nib')
					style.use nib()

				# Render our style
				style.render (err,output) ->
					# Check for errors, and return to docpad if so
					return next(err)  if err
					# Apply result
					opts.content = output
					# Done, return to docpad
					return next()
		
			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()

