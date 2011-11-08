###
This plugin is still in beta, don't use it.
###

# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Plugin
class AdminPlugin extends DocpadPlugin
	# Plugin Name
	name: 'admin'

	# Administration Blocks
	renderBefore: ({templateData}, next) ->
		templateData.blocks.scripts.push '''
			<script src="/_docpad/plugins/admin/scripts/script.js"></script>
		'''
		next()
	
	# Adminstration Website
	writeAfter: ({},next) ->
		docpad = require(@docpad.config.mainPath).createInstance(
			rootPath: __dirname,
			outPath: "#{@docpad.config.outPath}/_docpad/plugins/admin"
			logLevel: @docpad.config.logLevel
			enableUnlistedPlugins: false
			enabledPlugins: 'coffee'
		).action 'generate', next

# Export Plugin
module.exports = AdminPlugin