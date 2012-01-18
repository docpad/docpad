# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
path = require 'path'
exec = require('child_process').exec
child = false

# Define Buildr Plugin
class BuildrPlugin extends DocpadPlugin
	# Plugin Name
	name: 'buildr'

	# Writing all files has finished
	writeAfter: ({docpad},next) ->
		# Run buildr.coffee on the outpath
		
		# Fetch the buildrPath
		buildrPath = path.normalize "#{docpad.config.rootPath}/buildr.coffee"

		# Check if it exists
		path.exists buildrPath, (exists) ->
			return next()  unless exists

			# Execute buildr.coffee
			child.kill()  if child
			child = exec "coffee #{buildrPath}", (err, stdout, stderr) ->
				console.log stdout.replace(/\s+$/,'')  if stdout
				console.log stderr.replace(/\s+$/,'')  if stderr
				next err

# Export Buildr Plugin
module.exports = BuildrPlugin