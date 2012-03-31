# Requires
path = require('path')
FileModel = require(path.join __dirname, 'file.coffee')

# Document Model
class DocumentModel extends FileModel
	
	# Model Type
	type: 'document'

# Export
module.exports = DocumentModel
