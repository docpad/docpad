# Necessary
balUtil = require('bal-util')

# Local
{Collection,Model} = require(__dirname+'/../base')

# Elements Collection
class ElementsCollection extends Collection

	# Base Model for all items in this collection
	model: Model

	# Add an element to the collection
	# Right now we just support strings
	add: (values,opts) ->
		# Ensure array
		values = [values]  unless balUtil.isArray(values)

		# Convert string based array properties into html
		for value,key in values
			if balUtil.isString(value)
				values[key] = new Model({html:value})

		# Call the super with our values
		super(values,opts)

	# Create a way to output our elements to HTML
	toHTML: ->
		html = ''
		@forEach (item) ->
			html += item.get('html') or ''
		html

	# Join alias toHTML for b/c
	join: -> @toHTML()

# Export
module.exports = ElementsCollection
