# =====================================
# Requires

# Standard Library
pathUtil = require('path')
util = require('util')

# External
_ = require('lodash')
extractOptsAndCallback = require('extract-opts')
{TaskGroup} = require('taskgroup')


# =====================================
# Export
module.exports = docpadUtil =
	# Write to stderr
	writeStderr: (data) ->
		try
			process.stderr.write(data)
		catch err
			process.stdout.write(data)

	# Write an error
	writeError: (err) ->
		docpadUtil.writeStderr(err.stack?.toString?() or err.message or err)

	# Wait
	wait: (time, fn) -> setTimeout(fn, time)

	# Is TTY
	isTTY: ->
		return process.stdout?.isTTY is true and process.stderr?.isTTY is true

	# Inspect
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

	# Standard Encodings
	isStandardEncoding: (encoding) ->
		return encoding.toLowerCase() in ['ascii', 'utf8', 'utf-8']

	# Get Local DocPad Installation Executable
	getLocalDocPadExecutable: ->
		return pathUtil.join(process.cwd(), 'node_modules', 'docpad', 'bin', 'docpad')

	# Is Local DocPad Installation
	isLocalDocPadExecutable: ->
		return docpadUtil.getLocalDocPadExecutable() in process.argv

	# Does Local DocPad Installation Exist?
	getLocalDocPadExecutableExistance: ->
		return require('safefs').existsSync(docpadUtil.getLocalDocPadExecutable()) is true

	# Spawn Local DocPad Executable
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
		unless require('typechecker').isArray(extensions)
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
			return basename+(if extension then '.'+extension else '')

	# get url
	getUrl: (relativePath) ->
		return '/'+relativePath.replace(/[\\]/g, '/')

	# get slug
	getSlug: (relativeBase) ->
		return require('bal-util').generateSlugSync(relativeBase)

	# Perform an action
	# next(err,...), ... = any special arguments from the action
	# this should be it's own npm module
	# as we also use the concept of actions in a few other packages
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
		actions = _.uniq _.compact actions

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
