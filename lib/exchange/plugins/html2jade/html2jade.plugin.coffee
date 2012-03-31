# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class Html2JadePlugin extends BasePlugin
		# Plugin name
		name: 'html2jade'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content} = opts
			
			# Check our extensions
			if outExtension is 'jade' and inExtension is 'html'

				# Requires
				path = require('path')
				try
					# Sometimes works
					html2jade = require('html2jade')
				catch err
					# Sometimes this works
					html2jade = require path.resolve(__dirname, 'node_modules', 'html2jade', 'lib', 'html2jade.coffee')
				
				# Render asynchronously
				html2jade.convertHtml content, {}, (err,result) ->
					# Errord, return it back to DocPad
					return next(err)  if err

					# Render
					opts.content = result
					
					# Done, return back to DocPad
					return next()
			
			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()
