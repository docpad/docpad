# Requires
DocpadHelper = require "#{__dirname}/../helper.coffee"

# Define Clean Urls Helper
class CleanUrlsHelper extends DocpadHelper
	serverSetup: ({docpad,server},next) ->
		# Try .html for urls with no extension
		docpad.server.all /\/[a-z0-9]+\/?$/i, (req,res,next) =>
			filePath = docpad.outPath+req.url.replace(/\.\./g,'')+'.html' # stop tricktsers
			path.exists filePath, (exists) ->
				if exists
					fs.readFile filePath, (err,data) ->
						if err
							res.send(err.message, 500)
						else
							res.send(data.toString())
				else
					next false

# Export Clean Urls Helper
module.exports = CleanUrlsHelper