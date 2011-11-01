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

	# Run when the server setup has finished
	serverFinished: ({docpad,server},next) ->
		# Provide the clean url mapping
		docpad.server.all /./, (req,res,next) =>
			docpad.documents.findOne {urls:{'$in':req.url}}, (err,document) ->
				if err
					res.send(err.message, 500)
				else if document and document.url isnt req.url
					# document.url is handled by static
					res.send(document.contentRendered)
				next(err)
		
		# Continue
		next()
		true


# Export Clean Urls Plugin
module.exports = CleanUrlsPlugin