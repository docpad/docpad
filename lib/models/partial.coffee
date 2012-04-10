# Requires
path = require('path')
FileModel = require(path.join __dirname, 'file.coffee')

# Partial Model
PartialModel = FileModel.extend
#class PartialModel extends FileModel
	
	# Model Type
	type: 'partial'

# Export
module.exports = PartialModel
