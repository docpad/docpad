# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class PhpPlugin extends BasePlugin
		# Plugin name
		name: 'php'

		# Plugin priority
		priority: 700

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check extensions
			if inExtension in ['php','phtml']
				# Require
				{spawn,exec} = require('child_process')

				# Prepare Render
				data = JSON.stringify file.getSimpleAttributes()
				source = """
					<?php
					$content = <<<EOF
					#{templateData.content or ''}
					EOF;

					$document = <<<EOF
					#{data}
					EOF;
					$document = json_decode($document,true);
					?>

					#{file.content}
					"""
				result = ''
				errors = ''

				# Spawn Render
				php = spawn 'php'
				php.stdout.on 'data', (data) ->
					result += data.toString()
				php.stderr.on 'data', (data) ->
					errors += data.toString()
				php.on 'exit', ->
					# Check for errors, and return to docpad if so
					return next(new Error(errors))  if errors
					# Apply
					file.content = result
					# Done, return to docpad
					return next()
				
				# Start rendering
				php.stdin.write(source)
				php.stdin.end()
			
			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()

