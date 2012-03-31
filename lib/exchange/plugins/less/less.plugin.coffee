# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class LessPlugin extends BasePlugin
		# Plugin name
		name: 'less'

		# Plugin priority
		priority: 725

		# Render some content
		render: (opts,next) ->
			# Prepare
			{inExtension,outExtension,templateData,content,file} = opts

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
				new (less.Parser)(options).parse content, (err, tree) ->
					return next err  if err
					opts.content = tree.toCSS(compress: options.compress)
					next()
			
			# Some other extension
			else
				# Nothing to do, return back to DocPad
				return next()
