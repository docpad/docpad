# Define Docpad Parser
class DocpadParser
	inExtension: false
	outExtension: false
	parseContent: (content,next) ->
		next new Error 'Parser not defined'

# Export Docpad Parser
module.exports = DocpadParser