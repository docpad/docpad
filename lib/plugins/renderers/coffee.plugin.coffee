# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
ck = require 'coffeekup'
html2ck = require 'html2coffeekup-bal'
coffee = require 'coffee-script'
js2coffee = require 'js2coffee/lib/js2coffee.coffee'
html2ckConvertor = new html2ck.Converter()

# Define Coffee Plugin
class CoffeePlugin extends DocpadPlugin
	# Plugin name
	name: 'coffee'

	# Plugin priority
	priority: 700

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension in ['coffeekup','ck'] or (inExtension is 'coffee' and outExtension isnt 'js')
				file.content = ck.render file.content, templateData
			else if inExtension is 'html' and outExtension in ['coffeekup','ck']
				html2ckConvertor.convert file.content, (err,content) ->
					next err  if err
					file.content = content
					next()
				return
			else if inExtension is 'coffee' and outExtension is 'js'
				file.content = coffee.compile file.content
			else if inExtension is 'js' and outExtension is 'coffee'
				file.content = js2coffee.build file.content
			next()
		catch err
			return next err

# Export Coffee Plugin
module.exports = CoffeePlugin