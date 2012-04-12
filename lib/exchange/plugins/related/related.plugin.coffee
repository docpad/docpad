# Export Plugin
module.exports = (BasePlugin) ->
	# Define Relations Plugin
	class RelationsPlugin extends BasePlugin
		# Plugin Name
		name: 'relations'

		# Parsing all files has finished
		parseAfter: (opts,next) ->
			# Requires
			balUtil = require('bal-util')

			# Prepare
			docpad = @docpad
			logger = @logger
			documents = docpad.documents
			logger.log 'debug', 'Generating relations'

			# Async
			tasks = new balUtil.Group (err) ->
				logger.log 'debug', 'Generated relations'
				return next(err)

			# Check
			unless documents.length
				return tasks.exit()

			# Find documents
			tasks.total = documents.length
			documents.forEach (document) ->
				# Prepare
				tags = document.get('tags') or []

				# Find related documents
				relatedDocuments = documents.findAll(tags: '$in': tags)
				
				# Check
				unless relatedDocuments.length
					return tasks.complete()  

				# Fetch
				relatedDocumentsCleaned = []
				relatedDocumentsArray = relatedDocuments.sortArray (a,b) ->
					return a.tags.hasCount(tags) < b.tags.hasCount(tags)
				relatedDocumentsArray.forEach (relatedDocument) ->
					return null  if relatedDocument.url is document.get('url')
					relatedDocumentsCleaned.push relatedDocument

				# Save
				document.relatedDocuments = relatedDocumentsCleaned
				tasks.complete()
