# Requires
path = require('path')
DocumentModel = require(path.join __dirname, 'document.coffee')

# Partial Model
PartialModel = class extends DocumentModel
	
	# Model Type
	type: 'partial'

# Export
module.exports = PartialModel
