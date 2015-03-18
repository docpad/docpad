# =====================================
# Requires

# External
extendr = require('extendr')
{Backbone, QueryCollection} = require('query-engine')
{Events, Model, Collection} = Backbone


# =====================================
# Helpers

# Log a message
log = (args...) ->
	args.unshift('log')
	@emit.apply(@, args)
	@
emit = (args...) ->
	@trigger.apply(@, args)


# =====================================
# Classes


# -------------------------------------
# Backbone

# Events
class Events
	log: log
	emit: emit

extendr.extend(Events::, Events)


# Model
class Model extends Model
	log: log
	emit: emit

	# Set Defaults
	setDefaults: (attrs={},opts) ->
		# Extract
		set = {}
		for own key,value of attrs
			set[key] = value  if @get(key) is @defaults?[key]

		# Forward
		return @set(set, opts)


# Collection
class Collection extends Collection
	log: log
	emit: emit
	destroy: =>
		@emit('destroy')
		@off().stopListening()
		@
Collection::model = Model
Collection::collection = Collection


# QueryCollection
class QueryCollection extends QueryCollection
	log: log
	emit: emit

	setParentCollection: ->
		super
		parentCollection = @getParentCollection()
		parentCollection.on('destroy',@destroy)
		@

	destroy: =>
		@emit('destroy')
		@off().stopListening()
		@
QueryCollection::model = Model
QueryCollection::collection = QueryCollection


# =====================================
# Export our base models
module.exports = {Events,Model,Collection,QueryCollection}
