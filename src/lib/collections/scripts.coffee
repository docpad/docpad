# Necessary
_ = require('underscore')

# Local
ElementsCollection = require(__dirname+'/elements')

# Scripts Collection
class ScriptsCollection extends ElementsCollection

	# Add an element to the collection
	# Right now we just support strings
	add: (values,options) ->
		# Ensure array
		values = [values]  unless _.isArray(values)

		# Convert urls into script element html
		for value,key in values
			if _.isString(value) and /^\</.test(value) is false
				# convert url to script tag
				values[key] = """
					<script defer="defer" src="#{value}"></script>
					"""

		# Call the super with our values
		super(values,options)


# Export
module.exports = ScriptsCollection
