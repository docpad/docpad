# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Relations Plugin
class RelationsPlugin extends DocpadPlugin
	# Plugin Name
	name: 'relations'

	# Parsing all files has finished
	parseFinished: ({docpad},next) ->
		# Requires
		util = require 'bal-util'  unless util

		# Prepare
		Documents = docpad.Documents
		console.log 'Generating Relations'

		# Async
		tasks = new util.Group (err) ->
			console.log 'Generated Relations'
			next err

		# Find documents
		Documents.find {}, (err,documents,length) ->
			return tasks.exit err  if err
			tasks.total += length
			documents.forEach (document) ->
				# Find related documents
				Documents.find {tags:{'$in':document.tags}}, (err,relatedDocuments) ->
					# Check
					if err
						return tasks.exit err
					else if relatedDocuments.length is 0
						return tasks.complete null

					# Fetch
					relatedDocumentsArray = []
					relatedDocuments.sort (a,b) ->
						return a.tags.hasCount(document.tags) < b.tags.hasCount(document.tags)
					.forEach (relatedDocument) ->
						return null  if document.url is relatedDocument.url
						relatedDocumentsArray.push relatedDocument

					# Save
					document.relatedDocuments = relatedDocumentsArray
					document.save()
					tasks.complete()

# Export Relations Plugin
module.exports = RelationsPlugin