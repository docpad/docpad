# =====================================
# Requires

# External
extendr = require('extendr')
queryEngine = require('query-engine')


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

###*
# Base class for the DocPad Events object
# Extends the backbone.js events object
# http://backbonejs.org/#Events
# @class Events
# @constructor
# @extends queryEngine.Backbone.Events
###
class Events
	log: log
	emit: emit
extendr.extend(Events::, queryEngine.Backbone.Events)

###*
# Base class for the DocPad file and document model
# Extends the backbone.js model
# http://backbonejs.org/#Model
# @class Model
# @constructor
# @extends queryEngine.Backbone.Model
###
class Model extends queryEngine.Backbone.Model
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


###*
# Base class for the DocPad collection object
# Extends the backbone.js collection object
# http://backbonejs.org/#Collection
# @class Collection
# @constructor
# @extends queryEngine.Backbone.Collection
###
class Collection extends queryEngine.Backbone.Collection
	log: log
	emit: emit
	destroy: =>
		@emit('destroy')
		@off().stopListening()
		@
Collection::model = Model
Collection::collection = Collection


###*
# Base class for the DocPad query collection object
# Extends the bevry QueryEngine object
# http://github.com/bevry/query-engine
# @class QueryCollection
# @constructor
# @extends queryEngine.QueryCollection
###
class QueryCollection extends queryEngine.QueryCollection
	log: log
	emit: emit

	setParentCollection: ->
		super
		parentCollection = @getParentCollection()
		parentCollection.on('destroy', @destroy)
		@

	destroy: =>
		@emit('destroy')
		@off().stopListening()
		@
QueryCollection::model = Model
QueryCollection::collection = QueryCollection


# =====================================
# Export our base models
module.exports = {Events, Model, Collection, QueryCollection}
