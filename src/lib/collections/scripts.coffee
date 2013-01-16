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
		opts.async ?= false
		opts.attrs or= ''
		values = [values]  unless _.isArray(values)

		# Build attrs
		opts.attrs += """defer="defer" """  if opts.defer
		opts.attrs += """async="async" """  if opts.async

		# Convert urls into script element html
		for value,key in values
			if _.isString(value)
				if value[0] is '<'
					# we are a script element already, don't bother doing anything
				else if value.indexOf(' ') is -1
					# we are a url
					values[key] = """
						<script #{opts.attrs} src="#{value}"></script>
						"""
				else
					# we are javascript not in a script element
					values[key] = """
						<script #{opts.attrs}>#{value}</script>
						"""

		# Call the super with our values
		super(values,opts)


# Export
module.exports = ScriptsCollection
