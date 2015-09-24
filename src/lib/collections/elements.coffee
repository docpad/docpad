# =====================================
# Requires

# External
typeChecker = require('typechecker')

# Local
{Collection,Model} = require('../base')


# =====================================
# Classes

###*
# Base class for the DocPad Elements Collection object
# Extends the DocPad collection class
# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee#L72
# Used as the base collection class for specific collection of file types.
# In particular metadata, scripts and styles.
# @class ElementsCollection
# @constructor
# @extends Collection
###
class ElementsCollection extends Collection

	###*
	# Base Model for all items in this collection
	# @property {Object} model
	###
	model: Model

	###*
	# Add an element to the collection.
	# Right now we just support strings.
	# @method add
	# @param {Array} values string array of values
	# @param {Object} opts
	###
	add: (values,opts) ->
		# Ensure array
		if typeChecker.isArray(values)
			values = values.slice()
		else if values
			values = [values]
		else
			values = []

		# Convert string based array properties into html
		for value,key in values
			if typeChecker.isString(value)
				values[key] = new Model({html:value})

		# Call the super with our values
		super(values, opts)

		# Chain
		@

	# Chain
	set: -> super; @
	remove: -> super; @
	reset: -> super; @

	###*
	# Create a way to output our elements to HTML
	# @method toHTML
	# @return {String}
	###
	toHTML: ->
		html = ''
		@forEach (item) ->
			html += item.get('html') or ''
		html

	# Join alias toHTML for b/c
	join: -> @toHTML()


# =====================================
# Export
module.exports = ElementsCollection
