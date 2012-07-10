# Necessary
_ = require('underscore')

# Local
ElementsCollection = require(__dirname+'/elements')

# Scripts Collection
class ScriptsCollection extends ElementsCollection

	# Add an element to the collection
	# Right now we just support strings
	add: (values,opts) ->
		# Prepare
		opts or= {}
		opts.defer ?= true
		values = [values]  unless _.isArray(values)
		attrs = ''

		# Build attrs
		if opts.defer
			attrs += """defer="defer" """

		# Convert urls into script element html
		for value,key in values
			if _.isString(value)
				if value[0] is '<'
					# we are a script element already, don't bother doing anything
				else if value.indexOf(' ') is -1
					# we are a url
					values[key] = """
						<script #{attrs} src="#{value}"></script>
						"""
				else
					# we are javascript not in a script element
					values[key] = """
						<script #{attrs}>#{value}</script>
						"""

		# Call the super with our values
		super(values,opts)


# Export
module.exports = ScriptsCollection
