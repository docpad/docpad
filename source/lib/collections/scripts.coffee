# =====================================
# Requires

# External
typeChecker = require('typechecker')

# Local
ElementsCollection = require('./elements')


# =====================================
# Classes

###*
# Scripts collection class. A DocPad
# project's script file paths
# @class ScriptCollection
# @constructor
# @extends ElementsCollection
###
class ScriptsCollection extends ElementsCollection

	###*
	# Add an element to the collection
	# Right now we just support strings
	# @method add
	# @param {Array} values string array of file paths
	# @param {Object} opts
	###
	add: (values,opts) ->
		# Prepare
		opts or= {}
		opts.defer ?= true
		opts.async ?= false
		opts.attrs or= ''
		if typeChecker.isArray(values)
			values = values.slice()
		else if values
			values = [values]
		else
			values = []

		# Build attrs
		opts.attrs += """defer="defer" """  if opts.defer
		opts.attrs += """async="async" """  if opts.async

		# Convert urls into script element html
		for value,key in values
			if typeChecker.isString(value)
				if value[0] is '<'
					continue  # we are an element already, don't bother doing anything
				else if value.indexOf(' ') is -1
					# we are a url
					values[key] = """
						<script #{opts.attrs} src="#{value}"></script>
						"""
				else
					# we are inline
					values[key] = """
						<script #{opts.attrs}>#{value}</script>
						"""

		# Call the super with our values
		super(values, opts)


# =====================================
# Export
module.exports = ScriptsCollection
