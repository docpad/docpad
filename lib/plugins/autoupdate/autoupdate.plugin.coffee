# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Plugin
class AutoUpdatePlugin extends DocpadPlugin
	# Plugin Name
	name: 'autoupdate'

	# Constructor
	constructor: ->
		super
		@now = require 'now'

	# Insert Now
	renderBefore: ({templateData}, next) ->
		# Script
		templateData.blocks.scripts.push """
			<script src="/nowjs/now.js"></script>
			<script>
				// Wait for now
				window.now.ready(function(){
					// Handshake
					window.now.docpadHandshake(
						// Sync notify
						function (documentId, state) {
							document.location.reload();
						},
						// Callback
						function (clientId) {
							console.log('DocPad AutoUpdate plugin now ready');
						}
					);
				});
			</script>
			"""
		
		# Next
		return next()
	
	# Setup Now
	serverAfter: ({server},next) ->
		# Initialise Now
		@everyone = @now.initialize server, clientWrite: false

		# Client Handshake
		@everyone.now.docpadHandshake = (docpadSync,next) =>
			# Check properties
			if  typeof docpadSync isnt 'function'
				console.log 'Evil client'
				return false
			
			# Apply properties
			@now.docpadSync = docpadSync

			# Next
			return next()  if next
		
		# Next
		return next()
	
	# Regenerate
	writeAfter: ({},next) ->
		# Sync client
		@now.docpadSync()  if @now.docpadSync
		
		# Next
		return next()
			

# Export Plugin
module.exports = AutoUpdatePlugin