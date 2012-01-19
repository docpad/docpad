# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	path = require 'path'
	fs = require 'fs'
	util = require 'bal-util'

	# Define Plugin
	class CleanUrlsPlugin extends BasePlugin
		# Plugin Name
		name: 'cleanUrls'

		# Parsing all files has finished
		parseAfter: ({docpad,logger},next) ->
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
				return tasks.exit()  unless length
				tasks.total = length
				docs.forEach (document) ->
					# Index URL
					if /index\.html$/i.test document.url
						document.addUrl document.url.replace(/index\.html$/i,'')
					
					# Extesionless URL
					if /\.html$/i.test document.url
						document.addUrl document.url.replace(/\.html$/i,'')
					
					# Complete
					tasks.complete()
			
			# Continue
			next()
			true
