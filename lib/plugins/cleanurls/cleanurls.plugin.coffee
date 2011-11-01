# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
path = require 'path'
fs = require 'fs'

# Define Clean Urls Plugin
class CleanUrlsPlugin extends DocpadPlugin
	# Plugin Name
	name: 'cleanUrls'

	# Parsing all files has finished
	contextualizeFinished: ({docpad,logger,util},next) ->
		# Prepare
		documents = docpad.documents
		logger.log 'debug', 'Creating clean urls'

		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Created clean urls'
			next err

		# Find documents
		documents.find {}, (err,docs,length) ->
			return tasks.exit err  if err
			tasks.total = length
			docs.forEach (document) ->
				# Extesionless URL
				if /\.html$/i.test document.url
					document.addUrl document.url.replace(/\.html$/i,'')
				
				# Complete
				tasks.complete()
		
		# Continue
		next()
		true


# Export Clean Urls Plugin
module.exports = CleanUrlsPlugin