# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	path = require('path')
	exec = require('child_process').exec
	child = false

	# Define Plugin
	class BuildrPlugin extends BasePlugin
		# Plugin Name
		name: 'buildr'

		# Writing all files has finished
		writeAfter: (opts,next) ->
			# Run buildr.coffee on the outpath
			docpad = @docpad
			logger = @logger
			
			# Fetch the buildrPath
			buildrPath = path.normalize "#{docpad.config.rootPath}/buildr.coffee"

			# Check if it exists
			path.exists buildrPath, (exists) ->
				return next?()  unless exists

				# Execute buildr.coffee
				child.kill()  if child
				child = exec "coffee #{buildrPath}", (err, stdout, stderr) ->
					console.log stdout.replace(/\s+$/,'')  if stdout
					console.log stderr.replace(/\s+$/,'')  if stderr
					next?(err)
