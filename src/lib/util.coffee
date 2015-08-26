# =====================================
# Requires

# Standard Library
pathUtil = require('path')
util = require('util')

# External
{uniq, compact} = require('underscore')
extractOptsAndCallback = require('extract-opts')
{TaskGroup} = require('taskgroup')


# =====================================
# Export
###*
# The DocPad Util Class.
# Collection of DocPad utility methods
# @class docpadUtil
# @constructor
# @static
###
module.exports = docpadUtil =

	###*
	# Write to stderr
	# @private
	# @method writeStderr
	# @param {String} data
	###
	writeStderr: (data) ->
		try
			process.stderr.write(data)
		catch err
			process.stdout.write(data)

	###*
	# Write an error
	# @private
	# @method writeError
	# @param {Object} err
	###
	writeError: (err) ->
		docpadUtil.writeStderr(err.stack?.toString?() or err.message or err)

	###*
	# Wait. Wrapper for setTimeout
	# @private
	# @method wait
	# @param {Number} time
	# @param {function} fn
	###
	wait: (time, fn) -> setTimeout(fn, time)


	###*
	# Get Default Log Level
	# @private
	# @method getDefaultLogLevel
	# @return {Number} default log level
	###
	getDefaultLogLevel: ->
		if docpadUtil.isTravis() or ('-d' in process.argv)
			return 7
		else
			return 5

	###*
	# Are we executing on Travis
	# @private
	# @method isTravis
	# @return {String} The travis node version
	###
	isTravis: ->
		return process.env.TRAVIS_NODE_VERSION?

	###*
	# Is this TTY
	# @private
	# @method isTTY
	# @return {Boolean}
	###
	isTTY: ->
		return process.stdout?.isTTY is true and process.stderr?.isTTY is true


	###*
	# Is Standadlone
	# @private
	# @method isStandalone
	# @return {Object}
	###
	isStandalone: ->
		return /docpad$/.test(process.argv[1] or '')

	###*
	# Is user
	# @private
	# @method isUser
	# @return {Boolean}
	###
	isUser: ->
		return docpadUtil.isStandalone() and docpadUtil.isTTY() and docpadUtil.isTravis() is false

	###*
	# Wrapper for the node.js method util.inspect
	# @method inspect
	# @param {Object} obj
	# @param {Object} opts
	# @return {String}
	###
	inspect: (obj, opts) ->
		# Prepare
		opts ?= {}

		# If the terminal supports colours, and the user hasn't set anything, then default to a sensible default
		if docpadUtil.isTTY()
			opts.colors ?= '--no-colors' not in process.argv

		# If the terminal doesn't support colours, then over-write whatever the user set
		else
			opts.colors = false

		# Inspect and return
		return util.inspect(obj, opts)

	###*
	# Are we using standard encoding?
	# @private
	# @method isStandardEncoding
	# @param {String} encoding
	# @return {Boolean}
	###
	isStandardEncoding: (encoding) ->
		return encoding.toLowerCase() in ['ascii', 'utf8', 'utf-8']


	###*
	# Get Local DocPad Installation Executable - ie
	# not the global installation
	# @private
	# @method getLocalDocPadExecutable
	# @return {String} the path to the local DocPad executable
	###
	getLocalDocPadExecutable: ->
		return pathUtil.join(process.cwd(), 'node_modules', 'docpad', 'bin', 'docpad')

	###*
	# Is Local DocPad Installation
	# @private
	# @method isLocalDocPadExecutable
	# @return {Boolean}
	###
	isLocalDocPadExecutable: ->
		return docpadUtil.getLocalDocPadExecutable() in process.argv

	###*
	# Does the local DocPad Installation Exist?
	# @private
	# @method getLocalDocPadExecutableExistance
	# @return {Boolean}
	###
	getLocalDocPadExecutableExistance: ->
		return require('safefs').existsSync(docpadUtil.getLocalDocPadExecutable()) is true

	###*
	# Spawn Local DocPad Executable
	# @private
	# @method startLocalDocPadExecutable
	# @param {Function} next
	# @return {Object} don't know what
	###
	startLocalDocPadExecutable: (next) ->
		args = process.argv.slice(2)
		command = ['node', docpadUtil.getLocalDocPadExecutable()].concat(args)
		return require('safeps').spawn command, {stdio:'inherit'}, (err) ->
			if err
				if next
					next(err)
				else
					message = 'An error occured within the child DocPad instance: '+err.message+'\n'
					docpadUtil.writeStderr(message)
			else
				next?()


	###*
	# get a filename without the extension
	# @method getBasename
	# @param {String} filename
	# @return {String} base name
	###
	getBasename: (filename) ->
		if filename[0] is '.'
			basename = filename.replace(/^(\.[^\.]+)\..*$/, '$1')
		else
			basename = filename.replace(/\..*$/, '')
		return basename


	###*
	# Get the extensions of a filename
	# @method getExtensions
	# @param {String} filename
	# @return {Array} array of string
	###
	getExtensions: (filename) ->
		extensions = filename.split(/\./g).slice(1)
		return extensions


	###*
	# Get the extension from a bunch of extensions
	# @method getExtension
	# @param {Array} extensions
	# @return {String} the extension
	###
	getExtension: (extensions) ->
		unless require('typechecker').isArray(extensions)
			extensions = docpadUtil.getExtensions(extensions)

		if extensions.length isnt 0
			extension = extensions.slice(-1)[0] or null
		else
			extension = null

		return extension

	###*
	# Get the directory path.
	# Wrapper around the node.js path.dirname method
	# @method getDirPath
	# @param {String} path
	# @return {String}
	###
	getDirPath: (path) ->
		return pathUtil.dirname(path) or ''

	###*
	# Get the file name.
	# Wrapper around the node.js path.basename method
	# @method getFilename
	# @param {String} path
	# @return {String}
	###
	getFilename: (path) ->
		return pathUtil.basename(path)

	###*
	# Get the DocPad out file name
	# @method getOutFilename
	# @param {String} basename
	# @param {String} extension
	# @return {String}
	###
	getOutFilename: (basename, extension) ->
		if basename is '.'+extension  # prevent: .htaccess.htaccess
			return basename
		else
			return basename+(if extension then '.'+extension else '')

	###*
	# Get the URL
	# @method getUrl
	# @param {String} relativePath
	# @return {String}
	###
	getUrl: (relativePath) ->
		return '/'+relativePath.replace(/[\\]/g, '/')

	###*
	# Get the post slug from the URL
	# @method getSlug
	# @param {String} relativeBase
	# @return {String} the slug
	###
	getSlug: (relativeBase) ->
		return require('bal-util').generateSlugSync(relativeBase)

	###*
	# Perform an action
	# next(err,...), ... = any special arguments from the action
	# this should be it's own npm module
	# as we also use the concept of actions in a few other packages.
	# Important concept in DocPad.
	# @method action
	# @param {Object} action
	# @param {Object} opts
	# @param {Function} next
	###
	action: (action,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		me = @
		locale = me.getLocale()
		run = opts.run ? true
		runner = opts.runner ? me.getActionRunner()

		# Array?
		if Array.isArray(action)
			actions = action
		else
			actions = action.split(/[,\s]+/g)

		# Clean actions
		actions = uniq compact actions

		# Exit if we have no actions
		if actions.length is 0
			err = new Error(locale.actionEmpty)
			return next(err); me

		# We have multiple actions
		if actions.length > 1
			actionTaskOrGroup = runner.createGroup 'actions bundle: '+actions.join(' ')

			for action in actions
				# Fetch
				actionMethod = me[action].bind(me)

				# Check
				unless actionMethod
					err = new Error(util.format(locale.actionNonexistant, action))
					return next(err); me

				# Task
				task = actionTaskOrGroup.createTask(action, actionMethod, {args: [opts]})
				actionTaskOrGroup.addTask(task)

		# We have single actions
		else
			# Fetch the action
			action = actions[0]

			# Fetch
			actionMethod = me[action].bind(me)

			# Check
			unless actionMethod
				err = new Error(util.format(locale.actionNonexistant, action))
				return next(err); me

			# Task
			actionTaskOrGroup = runner.createTask(action, actionMethod, {args: [opts]})

		# Create our runner task
		runnerTask = runner.createTask "runner task for action: #{action}", (continueWithRunner) ->
			# Add our listener for our action
			actionTaskOrGroup.done (args...) ->
				# If we have a completion callback, let it handle the error
				if next
					next(args...)
					args[0] = null

				# Continue with our runner
				continueWithRunner(args...)

			# Run our action
			actionTaskOrGroup.run()

		# Add it and run it
		runner.addTask(runnerTask)
		runner.run()  if run is true

		# Chain
		return me
