# Requires
path = require('path')
DocumentModel = require(path.join __dirname, 'document.coffee')

# Layout Model
LayoutModel = class extends DocumentModel
	
	# Model Type
	type: 'layout'

# Export
module.exports = LayoutModel
