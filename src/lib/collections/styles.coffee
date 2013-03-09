# Necessary
balUtil = require('bal-util')

# Local
ElementsCollection = require(__dirname+'/elements')

# Styles Collection
class StylesCollection extends ElementsCollection

	# Add an element to the collection
	# Right now we just support strings
	add: (values,opts) ->
		# Prepare
		opts or= {}
		opts.attrs or= ''

		# Ensure array
		if balUtil.isArray(values)
			values = values.slice()
		else
			values = [values]

		# Convert urls into script element html
		for value,key in values
			if balUtil.isString(value) and /^\</.test(value) is false
				# convert url to script tag
				values[key] = """
					<link #{opts.attrs} rel="stylesheet" href="#{value}" />
					"""

		# Call the super with our values
		super(values,opts)


# Export
module.exports = StylesCollection
