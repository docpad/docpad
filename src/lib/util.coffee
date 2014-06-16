# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
_ = require('lodash')
{extractOptsAndCallback} = require('extract-opts')
{TaskGroup} = require('taskgroup')


# =====================================
# Export
module.exports = docpadUtil =
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
					process.stderr.write(message)
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
		run = opts.run ? true
		runner = opts.runner ? me.getActionRunner()

		# Array?
		if Array.isArray(action)
			actions = action
		else
			actions = action.split(/[,\s]+/g)

		# Clean actions
		actions = _.uniq _.compact actions

		# Next
		next ?= (err) =>
			@emit('error', err)  if err

		# Multiple actions?
		if actions.length is 0
			err = new Error('No action was given')
			next(err)

		else if actions.length > 1
			group = runner.createGroup 'actions bundle: '+actions.join(' ')

			for action in actions
				# Fetch
				actionMethod = me[action].bind(me)

				# Task
				task = group.createTask(action, actionMethod, {args: [opts]})
				group.addTask(task)

			# Run
			runner.addGroup(group, {next})
			runner.run()  if run is true

		else
			# Fetch the action
			action = actions[0]

			# Fetch
			actionMethod = me[action].bind(me)

			# Check
			unless actionMethod
				err = new Error(util.format(locale.actionNonexistant, action))
				return next(err)

			# Task
			task = runner.createTask(action, actionMethod, {args: [opts], next})

			# Run
			runner.addTask(task)
			runner.run()  if run is true

		# Chain
		me
