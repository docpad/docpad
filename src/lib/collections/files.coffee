# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# Local
{QueryCollection,Model} = require('../base')
FileModel = require('../models/file')


# =====================================
# Classes

###*
# The DocPad files and documents query collection class
# Extends the DocPad QueryCollection class
# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee#L91
# Used as the query collection class for DocPad files and documents.
# This differs from standard collections in that it provides backbone.js,
# noSQL style methods for querying the file system. In DocPad this
# is the various files that make up a web project. Typically this is the documents,
# css, script and image files.
#
# Most often a developer will use this class to find (and possibly sort) documents,
# such as blog posts, by some criteria.
# 	posts: ->
# 		@getCollection('documents').findAllLive({relativeOutDirPath: 'posts'},[{date:-1}])
# @class FilesCollection
# @constructor
# @extends QueryCollection
###
class FilesCollection extends QueryCollection

	###*
	# Base Model for all items in this collection
	# @private
	# @property {Object} model
	###
	model: FileModel

	###*
	# Base Collection for all child collections
	# @private
	# @property {Object} collection
	###
	collection: FilesCollection

	###*
	# Initialize the collection
	# @private
	# @method initialize
	# @param {Object} attrs
	# @param {Object} [opts={}]
	###
	initialize: (attrs,opts={}) ->
		@options ?= {}
		@options.name ?= opts.name or null
		super

	###*
	# Fuzzy find one
	# Useful for layout searching
	# @method fuzzyFindOne
	# @param {Object} data
	# @param {Object} sorting
	# @param {Object} paging
	# @return {Object} the file, if found
	###
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
