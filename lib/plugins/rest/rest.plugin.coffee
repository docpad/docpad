# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Plugin
class RestPlugin extends DocpadPlugin
	# Plugin Name
	name: 'rest'

	# Run when the server setup has finished
	serverFinished: ({docpad,server},next) ->
		# Hook into all post requests
		docpad.server.post /./, (req,res,next) =>
			# Check is maintainer
			unless @docpad.getPlugin('authenticate').isMaintainer()
				res.send(405) # Not authorized
				return next()

			# Fetch the document
			docpad.documents.findOne url: req.url, (err,document) ->
				# Error?
				return next(err)  if err

				# Empty?
				unless document
					return next()

				# Update it's meta data
				for own key, value of req.body
					document.fileMeta[key] = value  if document.fileMeta[key]?
				
				# Save the changes
				document.write (err) ->
					return next(err)  if err
					res.send JSON.stringify {success:true}
		next()

# Export Plugin
module.exports = RestPlugin