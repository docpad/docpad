###
This plugin is still in beta, don't use it.
###

# Export Plugin
module.exports = (BasePlugin) ->

	# Define Plugin
	class AdminPlugin extends BasePlugin
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
			docpad = require(@docpad.mainPath).createInstance(
				checkVersion: false
				growl: false
				rootPath: __dirname
				outPath: "#{@docpad.config.outPath}/_docpad/plugins/admin"
				logLevel: 0
				enableUnlistedPlugins: false
				enabledPlugins: 'coffee'
			).action 'generate', next
