# Export Plugin
module.exports = (BasePlugin) ->

	# Define Plugin
	class RestPlugin extends BasePlugin
		# Plugin Name
		name: 'rest'

		# Run when the server setup has finished
		serverAfter: ({docpad,server},next) ->
			# Hook into all post requests
			docpad.server.post /./, (req,res,next) =>
				# Check is maintainer
				if @config.requireAuthentication and @docpad.getPlugin('authenticate').isMaintainer() is false
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