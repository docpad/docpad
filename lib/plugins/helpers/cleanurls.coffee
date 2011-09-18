# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
path = require 'path'
fs = require 'fs'

# Define Clean Urls Plugin
class CleanUrlsPlugin extends DocpadPlugin
	# Plugin Name
	name: 'cleanUrls'

	# Run when the server setup has finished
	serverFinished: ({docpad,server},next) ->
		# Try .html for urls with no extension
		docpad.server.all /\/[a-z0-9\-]+\/?$/i, (req,res,next) =>
			# should can for relativeBase
			filePath = docpad.outPath+req.url.replace(/\.\./g,'')+'.html' # stop tricktsers
			path.exists filePath, (exists) ->
				if exists
					fs.readFile filePath, (err,data) ->
						if err
							res.send(err.message, 500)
						else
							res.send(data.toString())
				else
					next()
		next()

# Export Clean Urls Plugin
module.exports = CleanUrlsPlugin