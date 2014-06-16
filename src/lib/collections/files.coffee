# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# Local
{QueryCollection,Model} = require('../base')
FileModel = require('../models/file')


# =====================================
# Classes

# Files Collection
class FilesCollection extends QueryCollection
	# Base Model for all items in this collection
	model: FileModel

	# Base Collection for all child collections
	collection: FilesCollection

	# Prepare
	initialize: (attrs,opts={}) ->
		@options ?= {}
		@options.name ?= opts.name or null
		super

	# Fuzzy Find One
	# Useful for layout searching
	fuzzyFindOne: (data,sorting,paging) ->
		# Prepare
		escapedData = data?.replace(/[\/]/g, pathUtil.sep)
		queries = [
			{relativePath: escapedData}
			{relativeBase: escapedData}
			{url: data}
			{relativePath: $startsWith: escapedData}
			{fullPath: $startsWith: escapedData}
			{url: $startsWith: data}
		]

		# Try the queries
		for query in queries
			file = @findOne(query, sorting, paging)
			return file  if file

		# Didn't find a file
		return null


# =====================================
# Export
module.exports = FilesCollection
