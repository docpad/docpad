# Requires
path = require('path')
FileModel = require(path.join __dirname, 'file.coffee')

# Partial Model
class PartialModel extends FileModel
	
	# Model Type
	type: 'partial'

# Export
module.exports = PartialModel
