###
This plugin is still in beta, don't use it.
###

# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Plugin
class AdminPlugin extends DocpadPlugin
	# Plugin Name
	name: 'admin'

###
	# Add in a Script
	beforeRender: ({templateData}) ->
		templateData.scripts.push '''
			<script src="/docpad/admin.js"></script>
		'''
	
	# Server
	afterServer: ({server}) ->
		server.get '/docpad/admin.js', (req,res,next) ->
			res.send fs.readFileSync "#{__dirname}"/
###

# Export Plugin
module.exports = AdminPlugin