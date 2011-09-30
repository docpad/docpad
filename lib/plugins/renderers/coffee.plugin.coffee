# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
ck = require 'coffeekup'
html2ck = require 'html2coffeekup-bal'
coffee = require 'coffee-script'
js2coffee = require 'js2coffee/lib/js2coffee.coffee'
ccss = require 'ccss'
html2ckConvertor = new html2ck.Converter()

# Define Plugin
class CoffeePlugin extends DocpadPlugin
	# Plugin name
	name: 'coffee'

	# Plugin priority
	priority: 700

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			# CoffeeKup to anything
			if inExtension in ['coffeekup','ck'] or (inExtension is 'coffee' and !(outExtension in ['js','css']))
				file.content = ck.render file.content, templateData
				next()
			
			# HTML to CoffeeKup
			else if inExtension is 'html' and outExtension in ['coffeekup','ck','coffee']
				html2ckConvertor.convert file.content, (err,content) ->
					next err  if err
					file.content = content
					next()
			
			# CoffeeScript to JavaScript
			else if inExtension is 'coffee' and outExtension is 'js'
				file.content = coffee.compile file.content
				next()
			
			# JavaScript to CoffeeScript
			else if inExtension is 'js' and outExtension is 'coffee'
				file.content = js2coffee.build file.content
				next()
			
			# CoffeeCSS to CSS
			else if inExtension in ['coffee','ccss'] and outExtension is 'css'
				file.content = ccss.compile coffee.eval file.content
				next()
			
			# Other
			else
				next()
		
		catch err
			return next err

# Export Plugin
module.exports = CoffeePlugin