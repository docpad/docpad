# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	path = null
	less = null

	# Define Plugin
	class LessPlugin extends BasePlugin
		# Plugin name
		name: 'less'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			try
				if inExtension is 'less' and outExtension is 'css'
					# Load
					path = require 'path'  unless path
					less = require 'less-clean'  unless less

					# Prepare
					srcPath = file.fullPath
					dirPath = path.dirname(srcPath)
					options = 
						paths: [dirPath]
						optimization: 1
						compress: true

					# Compile
					new (less.Parser)(options).parse file.content, (err, tree) ->
						return next err  if err
						file.content = tree.toCSS(compress: options.compress)
						next()
				else
					next()
			catch err
				return next err
