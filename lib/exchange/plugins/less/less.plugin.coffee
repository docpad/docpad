# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class LessPlugin extends BasePlugin
		# Plugin name
		name: 'less'

		# Plugin priority
		priority: 725

		# Render some content
		render: ({inExtension,outExtension,templateData,file}, next) ->
			# Check extensions
			if inExtension is 'less' and outExtension is 'css'
				# Requires
				path = require('path')
				less = require('less')

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
			
			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()
