# Requirements
fs = require 'fs'
path = require 'path'

# Util
util =
	# Copy a file
	cp: (src,dst,next) ->
		fs.readFile src, 'binary', (err,data) ->
			throw err if err
			fs.writeFile dst, data, 'binary', (err) ->
				throw err if err
				if next then next()
	
	# Get the parent path
	getParentPathSync: (p) ->
		parentPath = p.replace /[\/\\][^\/\\]+$/, ''
		return parentPath
	
	# Ensure path exists
	ensurePath: (p,next) ->
		p = p.replace /[\/\\]$/, ''
		path.exists p, (exists) ->
			if exists then return next()
			parentPath = util.getParentPathSync p
			util.ensurePath parentPath, ->
				fs.mkdir p, 0700, (err) ->
					path.exists p, (exists) ->
						if not exists then if err then throw err
						next()
	
	# Recursively scan a directory
	scandir: (parentPath,fileAction,dirAction,next,relativePath) ->
		# Async
		completed = 0
		total = 0
		complete = ->
			++completed
			if completed is total
				if next then next()
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Error
			if err
				console.log 'Failed to read:', parentPath
				throw err
			
			# Skip
			else if !files.length
				if next then return next()
			
			# Cycle
			else files.forEach (file) ->
				# Prepare
				++total
				fileFullPath = parentPath+'/'+file
				fileRelativePath = (if relativePath then relativePath+'/' else '')+file

				# Stat
				fs.stat fileFullPath, (err,fileStat) ->
					# Error
					if err then throw err
					
					# Directory
					else if fileStat.isDirectory()
						# Recurse
						util.scandir(
							# Path
							fileFullPath
							# File
							fileAction
							# Dir
							dirAction
							# Next
							->
								if dirAction then dirAction fileFullPath, fileRelativePath, complete
								else complete()
							# Relative Path
							fileRelativePath
						)
					
					# File
					else
						if fileAction then fileAction fileFullPath, fileRelativePath, complete
						else complete()

	# Copy a directory
	cpdir: (srcPath,outPath,next) ->
		util.scandir(
			# Path
			srcPath
			# File
			(fileSrcPath,fileRelativePath,next) ->
				fileOutPath = outPath+'/'+fileRelativePath
				util.ensurePath path.dirname(fileOutPath), ->
					util.cp fileSrcPath, fileOutPath, ->
						if next then next()
			# Dir
			false
			# Next
			next
		)
	
	# Remove a directory
	rmdir: (parentPath,next) ->
		path.exists parentPath, (exists) ->
			if not exists then if next then return next()
			util.scandir(
				# Path
				parentPath
				# File
				(fileFullPath,fileRelativePath,next) ->
					fs.unlink fileFullPath, (err) ->
						if err then throw err
						else if next then next()
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					fs.rmdir fileFullPath, (err) ->
						if err then throw err
						else if next then next()
				# Next
				->
					fs.rmdir parentPath, (err) ->
						if err then throw err
						else if next then next()
			)

# Export
module.exports = util