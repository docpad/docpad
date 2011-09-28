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
	writeFinished: ({docpad},next) ->
		# Run buildr.coffee on the outpath
		
		# Fetch the buildrPath
		buildrPath = path.normalize "#{docpad.rootPath}/buildr.coffee"

		# Check if it exists
		path.exists buildrPath, (exists) ->
			return next()  unless exists

			# Execute buildr.coffee
			child.kill()  if child
			child = exec "coffee #{buildrPath}", (err, stdout, stderr) ->
				return next(err)  if err
				console.log stdout.replace(/\s+$/,'')  if stdout
				console.log stderr.replace(/\s+$/,'')  if stderr
				next()

# Export Buildr Plugin
module.exports = BuildrPlugin