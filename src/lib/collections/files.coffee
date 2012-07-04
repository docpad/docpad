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

	# Comparator
	comparator: [name: 1, date: -1]


# Export
module.exports = FilesCollection
