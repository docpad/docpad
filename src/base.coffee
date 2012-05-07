# Requires
_ = require('underscore')
QueryEngine = require('query-engine')
Backbone = QueryEngine.Backbone

# Events
class Events
_.extend(Events::, Backbone.Events)

# Model
class Model extends Backbone.Model

# Collection
class Collection extends Backbone.Collection

# View
class View extends Backbone.View

# QueryCollection
class QueryCollection extends QueryEngine.QueryCollection
	# Create Child Collection
	createChildCollection: ->
		collection = new QueryCollection().setParentCollection(@)
		return collection

# Export our BaseModel Class
module.exports = {Events,Model,Collection,View,QueryCollection}