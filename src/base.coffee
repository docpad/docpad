# Requires
_ = require('underscore')
Backbone = require('backbone')
QueryEngine = require('query-engine')

# BalUtil's Event System (extends Node's Event Emitter)
balUtil = require('bal-util')
EventSystem = balUtil.EventSystem

# Inject
# Injects a CoffeeScript class with other Classes
# The important thing here, is that it doesn't over-write our constructor
inject = (A,args...) ->
	for B in args
		for key,value of B::
			continue  if key is 'constructor'
			A::[key] = value
	A

# Events
class Events
	# When on is called, add the event with Backbone events if we have a context
	# if not, add the event with the Node events
	on: (event,callback,context) ->
		@setMaxListeners(0)
		if context?
			@bind(event,callback,context)  # backbone
		else
			@addListener(event,callback)  # node
		@

	# When off is called, remove the event with Backbone events if we have a context
	# if not, then remote it with both
	# if no arguments are specified, then remove everything with both
	off: (event,callback,context) ->
		if context?
			@unbind(event,callback,context)  # backbone
		else if callback?
			@unbind(event,callback)  # backbone
			@removeListener(event,callback)  # node
		else
			@unbind(event)  # backbone
			@removeAllListeners(event)  # node
		@

	# When trigger is called, trigger the events for both Backbone and Node
	trigger: (args...) ->
		Backbone.Events.trigger.apply(@,args)  # backbone
		EventSystem::emit.apply(@,args)  # node
		@

	# When emit is called, trigger the events for both Backbone and Node
	emit: (args...) ->
		Backbone.Events.trigger.apply(@,args)  # backbone
		EventSystem::emit.apply(@,args)  # node
		@

# Adjust Events
Events:: = _.extend({}, Backbone.Events, EventSystem::, Events::)

# Model
class Model extends Backbone.Model
inject(Model,Events)

# Collection
class Collection extends Backbone.Collection
inject(Collection,Events)

# View
class View extends Backbone.View
inject(View,Events)

# QueryCollection
class QueryCollection extends QueryEngine.QueryCollection
	# Create Child Collection
	createChildCollection: ->
		collection = new QueryCollection().setParentCollection(@)
		return collection
inject(QueryCollection,Events)

# Export our BaseModel Class
module.exports = {Events,Model,Collection,View,QueryCollection}