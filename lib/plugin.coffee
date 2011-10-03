# Define Plugin
class DocpadPlugin

	# ---------------------------------
	# Variables

	# Plugin name
	name: null

	# Plugin priority
	priority: 500

	# Constructor
	constructor: ->
		if !@name
			throw new Error 'Plugin must have a name'

	# ---------------------------------
	# Events

	# Cleaning has finished
	cleanFinished: ({docpad},next) ->
		next()

	# Parsing all files has finished
	parseFinished: ({docpad},next) ->
		next()
	
	# Contextualizing all files has finished
	contextualizeFinished: ({docpad},next) ->
		next()
	
	# Rendering all files has started
	renderStarted: ({docpad,templateData},next) ->
		next()
	
	# Render a file
	render: ({docpad,inExtension,outExtension,templateData,file}, next) ->
		next()
	
	# Rendering all files has finished
	renderFinished: ({docpad},next) ->
		next()

	# Writing all files has finished
	writeFinished: ({docpad},next) ->
		next()

	# Setting up the server has finished
	serverFinished: ({docpad,server},next) ->
		next()


# Export Plugin
module.exports = DocpadPlugin