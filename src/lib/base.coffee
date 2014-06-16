# =====================================
# Requires

# External
extendr = require('extendr')
queryEngine = require('query-engine')
Backbone = queryEngine.Backbone


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

# Events
class Events
	log: log
	emit: emit

extendr.extend(Events::, Backbone.Events)


# Model
class Model extends Backbone.Model
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
class Collection extends Backbone.Collection
	log: log
	emit: emit
	destroy: =>
		@emit('destroy')
		@off().stopListening()
		@
Collection::model = Model
Collection::collection = Collection


# View
class View extends Backbone.View
	log: log
	emit: emit


# QueryCollection
class QueryCollection extends queryEngine.QueryCollection
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


# ---------------------------------
# Export our base models
module.exports = {queryEngine,Backbone,Events,Model,Collection,View,QueryCollection}
