# Requires
_ = require('underscore')
QueryEngine = require('query-engine')
Backbone = QueryEngine.Backbone

# Log a message
log = (args...) ->
	args.unshift('log')
	@emit.apply(@,args)
	@
emit = (args...) ->
	@trigger.apply(@,args)

# Events
class Events
	log: log
	emit: emit

_.extend(Events::, Backbone.Events)

# Model
class Model extends Backbone.Model
	log: log
	emit: emit

# Collection
class Collection extends Backbone.Collection
	log: log
	emit: emit

# View
class View extends Backbone.View
	log: log
	emit: emit

# QueryCollection
class QueryCollection extends QueryEngine.QueryCollection
	log: log
	emit: emit

	# Create Child Collection
	createChildCollection: ->
		collection = new QueryCollection().setParentCollection(@)
		return collection

# Export our BaseModel Class
module.exports = {Backbone,Events,Model,Collection,View,QueryCollection}