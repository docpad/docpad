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
			
			# -------------------------
			# CoffeeKup to anything

			# Check extensions
			if inExtension in ['coffeekup','ck'] or (inExtension is 'coffee' and !(outExtension in ['js','css']))
				# Requires
				ck = require('coffeekup')
				
				# Render
				file.content = ck.render file.content, templateData, (@config.coffeekup or {})
				
				# Done, return back to DocPad
				return next()

			
			# -------------------------
			# HTML to CoffeeKup

			# Check extensions
			else if inExtension is 'html' and outExtension in ['coffeekup','ck','coffee']
				# Requires
				html2ck = require('html2coffeekup')

				# Render asynchronously
				outputStream = {
					content: ''
					write: (content) ->
						@content += content
				}
				html2ck.convert file.content, outputStream, (err) ->
					# Check for error
					return next(err)  if err
					# Apply
					file.content = outputStream.content
					# Done, return back to DocPad
					return next()
			

			# -------------------------
			# CoffeeScript to JavaScript

			# Check extensions
			else if inExtension is 'coffee' and outExtension is 'js'
				# Requires
				coffee = require('coffee-script')

				# Render
				file.content = coffee.compile(file.content)
				
				# Done, return back to DocPad
				return next()
			

			# -------------------------
			# JavaScript to CoffeeScript

			# Check Extensions
			else if inExtension is 'js' and outExtension is 'coffee'
				# Requires
				js2coffee = require('js2coffee/lib/js2coffee.coffee')

				# Render
				file.content = js2coffee.build(file.content)
		
				# Done, return back to DocPad
				return next()
			

			# -------------------------
			# Something Else

			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()
