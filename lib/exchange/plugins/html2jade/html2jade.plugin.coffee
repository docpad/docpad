# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class Html2JadePlugin extends BasePlugin
		# Plugin name
		name: 'html2jade'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if outExtension is 'jade' and inExtension is 'html'
					path = require('path')
					try
						unless html2jade
							html2jade = require('html2jade')
					catch err
						unless html2jade
							html2jade = require path.resolve(__dirname, 'node_modules', 'html2jade', 'lib', 'html2jade.coffee')
					html2jade.convertHtml file.content, {}, (err,result) ->
						return next(err)  if err
						file.content = result
						next()
				else
					next()
			catch err
				return next(err)
