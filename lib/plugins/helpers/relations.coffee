# Requires
DocpadHelper = require "#{__dirname}/../helper.coffee"

# Define Relations Helper
class RelationsHelper extends DocpadHelper

	# Generate relations
	parsingCompleted: ({docpad},next) ->
		# Requires
		eco = require 'eco'  unless eco
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
						return tasks.complete false

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
					tasks.complete false

# Export Relations Helper
module.exports = RelationsHelper