# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
jade = require 'jade'
html2jade = require 'html2jade'

# Define Plugin
class JadePlugin extends DocpadPlugin
	# Plugin name
	name: 'jade'

	# Plugin priority
	priority: 725

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension is 'jade'
				file.content = jade.compile(file.content, {})(templateData)
				next()
			else if outExtension is 'jade' and inExtension is 'html'
				html2jade.convertHtml file.content, {}, (err,result) ->
					return next(err)  if err
					file.content = result
					next()
			else
				next()
		catch err
			return next(err)

# Export Plugin
module.exports = JadePlugin