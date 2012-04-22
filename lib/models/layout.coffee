# Requires
path = require('path')
FileModel = require(path.join __dirname, 'file.coffee')

# Layout Model
LayoutModel = FileModel.extend
	
	# Model Type
	type: 'layout'

# Export
module.exports = LayoutModel
