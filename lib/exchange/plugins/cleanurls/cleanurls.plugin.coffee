# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class CleanUrlsPlugin extends BasePlugin
		# Plugin Name
		name: 'cleanUrls'

		# Parsing all files has finished
		parseAfter: (opts,next) ->
			# Requires
			path = require('path')
			fs = require('fs')
			balUtil = require('bal-util')

			# Prepare
			docpad = @docpad
			logger = @logger
			documents = docpad.documents
			logger.log 'debug', 'Creating clean urls'

			# Async
			tasks = new balUtil.Group (err) ->
				logger.log 'debug', 'Created clean urls'
				next?(err)

			# Check
			unless documents.length
				return tasks.exit()
			
			# Find documents
			tasks.total = documents.length
			documents.forEach (document) ->
				# Prepare
				documentUrl = document.get('url')

				# Index URL
				if /index\.html$/i.test(documentUrl)
					document.addUrl documentUrl.replace(/index\.html$/i,'')
				
				# Extesionless URL
				if /\.html$/i.test(documentUrl)
					document.addUrl documentUrl.replace(/\.html$/i,'')
				
				# Complete
				tasks.complete()
