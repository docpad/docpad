# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class RubyPlugin extends BasePlugin
		# Plugin name
		name: 'ruby'

		# Plugin priority
		priority: 700

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content,file} = opts

			# Handle
			if inExtension in ['rb','ruby','erb']
				# Require
				{spawn,exec} = require('child_process')

				# Prepare Render
				data = JSON.stringify file.getSimpleAttributes()
				source = """
					content = <<-EOF
					#{templateData.content or ''}
					EOF
					document = Hash.new()
					require 'rubygems' unless defined? Gem
					require 'json'
					document = JSON.parse <<-EOF
					#{data}
					EOF

					"""
				source +=
					if inExtension is 'erb'
						"""
						require 'erb'
						template = ERB.new <<-EOF
						#{content}
						EOF
						puts template.result(binding)
						"""
					else
						content
				result = ''
				errors = ''

				# Spawn Render
				ruby = spawn 'ruby'
				ruby.stdout.on 'data', (data) ->
					result += data.toString()
				ruby.stderr.on 'data', (data) ->
					errors += data.toString()
				ruby.on 'exit', ->
					return next(new Error(errors))  if errors
					opts.content = result
					return next()
				
				# Start rendering
				ruby.stdin.write(source)
				ruby.stdin.end()
			else
				return next()