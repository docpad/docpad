# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CoffeePlugin extends BasePlugin
		# Plugin name
		name: 'coffee'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				# CoffeeKup to anything
				if inExtension in ['coffeekup','ck'] or (inExtension is 'coffee' and !(outExtension in ['js','css']))
					ck = require('coffeekup')
					file.content = ck.render file.content, templateData, (@config.coffeekup or {})
					next()
				
				# HTML to CoffeeKup
				else if inExtension is 'html' and outExtension in ['coffeekup','ck','coffee']
					html2ck = require('html2coffeekup')
					outputStream = {
						content: ''
						write: (content) ->
							@content += content
					}
					html2ck.convert file.content, outputStream, (err) ->
						next err  if err
						file.content = outputStream.content
						next()
				
				# CoffeeScript to JavaScript
				else if inExtension is 'coffee' and outExtension is 'js'
					coffee = require('coffee-script')
					file.content = coffee.compile file.content
					next()
				
				# JavaScript to CoffeeScript
				else if inExtension is 'js' and outExtension is 'coffee'
					js2coffee = require('js2coffee/lib/js2coffee.coffee')
					file.content = js2coffee.build file.content
					next()
				
				# Removed the CoffeeCSS plugin as it was causing issues in the new version
				# Either caused by docpad v2.0, node.js 0.6, or coffee-script 1.1.1

				# Other
				else
					next()
			
			catch err
				return next err
