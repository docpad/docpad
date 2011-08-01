# Define Docpad Helper
class DocpadHelper
	cleanCompleted: ({docpad},next) ->
		next false

	parseFileAction: ({docpad,fileMeta},next) ->
		next false
	parseCompleted: ({docpad},next) ->
		next false
	
	renderAction: ({docpad,templateData},next) ->
		next false
	renderCompleted: ({docpad},next) ->
		next false

	writeCompleted: ({docpad},next) ->
		next false

	serverAction: ({docpad,server},next) ->
		next false

# Export Docpad Helper
module.exports = DocpadHelper