# Requires
path = require('path')
FileModel = require(path.join __dirname, 'file.coffee')

# Document Model
DocumentModel = FileModel.extend
	
	# Model Type
	type: 'document'

# Export
module.exports = DocumentModel
