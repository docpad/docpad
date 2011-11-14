# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
util = require 'bal-util'

# Define Relations Plugin
class RelationsPlugin extends DocpadPlugin
	# Plugin Name
	name: 'relations'

	# Parsing all files has finished
	parseAfter: ({docpad,logger},next) ->
		# Prepare
		documents = docpad.documents
		logger.log 'debug', 'Generating relations'

		# Async
		tasks = new util.Group (err) ->
			logger.log 'debug', 'Generated relations'
			next err

		# Find documents
		documents.find {}, (err,docs,length) ->
			return tasks.exit err  if err
			return tasks.exit()  unless length
			tasks.total = length
			docs.forEach (document) ->
				# Find related documents
				documents.find {tags:{'$in':document.tags}}, (err,relatedDocuments) ->
					return tasks.exit err  if err
					return tasks.complete()  unless relatedDocuments.length

					# Fetch
					relatedDocumentsArray = []
					relatedDocuments.sort (a,b) ->
						return a.tags.hasCount(document.tags) < b.tags.hasCount(document.tags)
					.forEach (relatedDocument) ->
						return null  if document.url is relatedDocument.url
						relatedDocumentsArray.push relatedDocument

					# Save
					document.relatedDocuments = relatedDocumentsArray
					document.store()
					tasks.complete()

# Export Relations Plugin
module.exports = RelationsPlugin
