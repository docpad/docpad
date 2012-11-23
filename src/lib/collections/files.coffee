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
	fuzzyFindOne: (data) ->
		file = @findOne(id: data)
		return file  if file

		file = @findOne(relativePath: data)
		return file  if file

		file = @findOne(relativeBase: data)
		return file  if file

		file = @findOne(relativePath: $startsWith: data)
		return file  if file

		file = @findOne(fullPath: $startsWith: data)
		return file

# Export
module.exports = FilesCollection
