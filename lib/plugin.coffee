# Define Docpad Plugin
class DocpadPlugin

	# ---------------------------------
	# Variables

	# Plugin name
	name: null

	# Plugin priority
	priority: 500

	# Scan these extensions
	extensions: []

	# Constructor
	constructor: ->
		if !@name
			throw new Error 'Plugin must have a name'
		
		if typeof @parseExtensions is 'string'
			@parseExtensions = @parseExtensions.split(/,\s/g)
	
	# ---------------------------------
	# Events

	# Cleaning has finished
	cleanFinished: ({docpad},next) ->
		next null

	# Parsing all files has finished
	parseFinished: ({docpad},next) ->
		next null
	
	# Rendering all files has started
	renderStarted: ({docpad,templateData},next) ->
		next null
	
	# Render a file
	render: ({docpad,inExtension,outExtension,templateData,file}, next) ->
		next null
	
	# Rendering all files has finished
	renderFinished: ({docpad},next) ->
		next null

	# Writing all files has finished
	writeFinished: ({docpad},next) ->
		next null

	# Setting up the server has finished
	serverFinished: ({docpad,server},next) ->
		next null


# Export Docpad Plugin
module.exports = DocpadPlugin