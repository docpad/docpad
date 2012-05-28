# Requires
_ = require('underscore')
QueryEngine = require('query-engine')
Backbone = QueryEngine.Backbone

# Log a message
log = (args...) ->
	args.unshift('log')
	@emit.apply(@,args)
	@

# Events
class Events
	emit: (args...) ->
		@trigger.apply(@,args)

_.extend(Events::, Backbone.Events)

# Model
class Model extends Backbone.Model
	# Log a message
	log: log

# Collection
class Collection extends Backbone.Collection
	# Log a message
	log: log

# View
class View extends Backbone.View
	# Log a message
	log: log

# QueryCollection
class QueryCollection extends QueryEngine.QueryCollection
	# Log a message
	log: log

	# Create Child Collection
	createChildCollection: ->
		collection = new QueryCollection().setParentCollection(@)
		return collection

# Export our BaseModel Class
module.exports = {Backbone,Events,Model,Collection,View,QueryCollection}