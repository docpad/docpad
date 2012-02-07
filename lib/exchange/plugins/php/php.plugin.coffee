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
			try
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
						return next(new Error(errors))  if errors
						file.content = result
						next()
					
					# Start rendering
					php.stdin.write(source)
					php.stdin.end()
				else
					next()
			catch err
				return next(err)