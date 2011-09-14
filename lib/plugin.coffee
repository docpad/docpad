# Define Docpad Plugin
class DocpadPlugin

	# ---------------------------------
	# Variables

	# Plugin Name
	name: null

	# Plugin Priority
	priority: 500

	# Scan these extensions
	parseExtensions: false

	# Constructor
	constructor: ->
		if !@name
			throw new Error 'Plugin must have a name'
		
		if typeof @parseExtensions is 'String'
			@parseExtensions = @parseExtensions.split(/,\s/g)
	
	# ---------------------------------
	# Events

	# Cleaning has finished
	cleanFinished: ({docpad},next) ->
		next null

	# Parse a file
	parseFile: ({docpad,fileMeta},next) ->
		next null
	
	# Parsing a file has finished
	parseFileFinished: ({docpad,fileMeta},next) ->
		next null
	
	# Parsing all files has finished
	parseFinished: ({docpad},next) ->
		next null
	
	# Rendering a file has started
	renderFileStarted: ({docpad,templateData},next) ->
		next null
	
	# Run when rendering all files has finished
	renderFinished: ({docpad},next) ->
		next null

	# Run when writing all files has finished
	writeFinished: ({docpad},next) ->
		next null

	# Run when the server setup has finished
	serverFinished: ({docpad,server},next) ->
		next null


# Export Docpad Plugin
module.exports = DocpadPlugin