# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
roy = null

# Define Plugin
class RoyPlugin extends DocpadPlugin
	# Plugin name
	name: 'roy'

	# Plugin priority
	priority: 700

	# Render some content
	render: ({inExtension,outExtension,templateData,file}, next) ->
		try
			if inExtension in ['roy'] and outExtension is 'js'
				roy = require('roy')  unless roy
				file.content = roy.compile(file.content.replace(/^\s+/,'')).output
				next()
			else
				next()
		catch err
			return next(err)

# Export Plugin
module.exports = RoyPlugin
