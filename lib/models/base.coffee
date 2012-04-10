# Requires
_ = require('underscore')
Backbone = require('backbone')

# BalUtil's Event System (extends Node's Event Emitter)
balUtil = require('bal-util')
EventSystem = balUtil.EventSystem

# Create our BaseModel extended from our Backbone.Model
BaseModel = Backbone.Model.extend
#class BaseModel extends Backbone.Model

	# When on is called, add the event with Backbone events if we have a context
	# if not, add the event with the Node events
    on: (event,callback,context) ->
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

# Extend our BaseModel's prototype with BalUtil's Event System
_.extend(BaseModel::,EventSystem::)

# Export our BaseModel Class
module.exports = BaseModel