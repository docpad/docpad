# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
jade = null

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
				jade = require 'jade'  unless jade
				file.content = jade.compile(file.content, {
					filename: file.fullPath
				})(templateData)
				next()
			else
				next()
		catch err
			return next(err)

# Export Plugin
module.exports = JadePlugin