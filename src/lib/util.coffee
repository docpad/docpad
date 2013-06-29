# Import
pathUtil = require('path')
typeChecker = require('typechecker')
balUtil = require('bal-util')

# Export
module.exports = docpadUtil =
	# get a filename without the extension
	getBasename: (filename) ->
		if filename[0] is '.'
			basename = filename.replace(/^(\.[^\.]+)\..*$/, '$1')
		else
			basename = filename.replace(/\..*$/, '')
		return basename

	# get the extensions of a filename
	getExtensions: (filename) ->
		extensions = filename.split(/\./g).slice(1)
		return extensions

	# get the extension from a bunch of extensions
	getExtension: (extensions) ->
		unless typeChecker.isArray(extensions)
			extensions = docpadUtil.getExtensions(extensions)

		if extensions.length isnt 0
			extension = extensions.slice(-1)[0] or null
		else
			extension = null

		return extension

	# get the dir path
	getDirPath: (path) ->
		return pathUtil.dirname(path) or ''

	# get filename
	getFilename: (path) ->
		return pathUtil.basename(path)

	# get out filename
	getOutFilename: (basename, extension) ->
		if basename is '.'+extension  # prevent: .htaccess.htaccess
			return basename
		else
			return basename+(if extension then '.'+extension or '')

	# get url
	getUrl: (relativePath) ->
		return '/'+relativePath.replace(/[\\]/g, '/')

	# get slug
	getSlug: (relativeBase) ->
		return balUtil.generateSlugSync(relativeBase)