# Necessary
_ = require('underscore')
balUtil = require('bal-util')

# Local
{QueryCollection,Model} = require(__dirname+'/../base')
FileModel = require(__dirname+'/../models/file')

# Files Collection
class FilesCollection extends QueryCollection

	# Base Model for all items in this collection
	model: FileModel

	# Base Collection for all child collections
	collection: FilesCollection

	# Fuzzy Find One
	# Useful for layout searching
	fuzzyFindOne: (data,sorting,paging) ->
		# Prepare
		queries = [
			{id: data}
			{relativePath: data}
			{relativeBase: data}
			{url: data}
			{relativePath: $startsWith: data}
			{fullPath: $startsWith: data}
			{url: $startsWith: data}
		]

		# Try the queries
		for query in queries
			file = @findOne(query,sorting,paging)
			return file  if file

		# Didn't find a file
		return null

# Export
module.exports = FilesCollection
