# Requires
_ = require('underscore')
queryEngine = require('query-engine')
Backbone = queryEngine.Backbone

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
	setDefaults: (defaults) ->
		set = {}
		for own key,value of defaults
			set[key] = value  if @get(key) is @defaults?[key]
		@set(set)
		return @

# Collection
class Collection extends Backbone.Collection
	log: log
	emit: emit

# View
class View extends Backbone.View
	log: log
	emit: emit

# QueryCollection
class QueryCollection extends queryEngine.QueryCollection
	log: log
	emit: emit
	Collection: QueryCollection

# Export our base models
module.exports = {queryEngine,Backbone,Events,Model,Collection,View,QueryCollection}
