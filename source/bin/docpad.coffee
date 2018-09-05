# Extensions
require('../lib/extensions')

# Prepare
main = ->

	# ---------------------------------
	# Check for Local DocPad Installation

	# Prepare
	docpadUtil = require('../lib/util')

	# Continue if we explcitly want to use the global installation
	if '--global' in process.argv
		# remove them to workaround https://github.com/cacjs/cac/issues/25
		process.argv = process.argv.filter (arg) -> arg isnt '--global'
		# continue

	# Continue if we are already the local installation
	else if docpadUtil.isLocalDocPadExecutable()
		# continue

	# Continue if the local installation doesn't exist
	else if docpadUtil.getLocalDocPadExecutableExistance() is false
		# continue

	# Otherwise forward to the local installation
	else
		# return
		return docpadUtil.startLocalDocPadExecutable()

	# ---------------------------------
	# CLI

	# Prepare
	extendr = require('extendr')
	cli = require('cac')()
	locale = require('../lib/locale/en')
	DocPad = require('../lib/docpad')
	Errlop = require('errlop')
	docpad = null
	instanceConfig = {}

	# Global options
	cli
		.option('outPath', {
			type: 'string',
			desc: locale.consoleOptionOutPath
		})
		.option('configPaths', {
			alias: ['configPath', 'config', 'c'],
			type: 'string',
			desc: locale.consoleOptionConfig
		})
		.option('environment', {
			alias: ['env', 'e'],
			type: 'string',
			desc: locale.consoleOptionEnv
		})
		.option('logLevel', {
			type: 'string',
			desc: locale.consoleOptionLogLevel
		})
		.option('verbose', {
			alias: ['v'],
			type: 'boolean',
			desc: locale.consoleOptionVerbose
		})
		.option('debug', {
			alias: ['d'],
			type: 'boolean',
			desc: locale.consoleOptionDebug
		})
		.option('global', {
			type: 'boolean',
			desc: locale.consoleOptionGlobal
		})
		.option('color', {
			alias: ['colour'],
			default: true,
			type: 'boolean',
			desc: locale.consoleOptionColor
		})
		.option('silent', {
			type: 'boolean',
			desc: locale.consoleOptionSilent
		})
		.option('progress', {
			default: true,
			type: 'boolean',
			desc: locale.consoleOptionProgress
		})
		.option('offline', {
			type: 'boolean',
			desc: locale.consoleOptionOffline
		})

	# Commands
	cli.command('run', {
		desc: locale.consoleDescriptionRun
	}, (input, flags) -> performAction('run', {skeleton: flags.skeleton}))
		.option('skeleton', {
			type: 'string',
			desc: locale.consoleOptionSkeleton
		})

	cli.command('init', {
		desc: locale.consoleDescriptionInit
	}, (input, flags) -> performAction('init', {skeleton: flags.skeleton}))
		.option('skeleton', {
			type: 'string',
			desc: locale.consoleOptionSkeleton
		})

	cli.command('generate', {
		desc: locale.consoleDescriptionGenerate
	}, (input, flags) -> performAction('generate'))

	cli.command('render', {
		desc: locale.consoleDescriptionRender,
		examples: [
			'docpad render <filename>',
			'docpad render <filepath>',
			"echo '*example*' | docpad render"
		]
	}, (input, flags) ->
		instanceConfig.silent = true
		performAction('render', {
			filename: input[0],
			renderSingleExtensions: 'auto',
			output: flags.output ? true,
			stdin: flags.stdin
		})
	).option('output', {
		alias: ['out', 'o'],
		type: 'string',
		desc: locale.consoleOptionOutput
	}).option('stdin', {
		type: 'boolean',
		desc: locale.consoleOptionStdin
	})

	cli.command('watch', {
		desc: locale.consoleDescriptionWatch
	}, (input, flags) -> performAction('generate watch'))

	cli.command('clean', {
		desc: locale.consoleDescriptionClean
	}, (input, flags) -> performAction('clean'))

	cli.command('update', {
		desc: locale.consoleDescriptionUpdate
	}, (input, flags) -> performAction('clean update'))

	cli.command('upgrade', {
		desc: locale.consoleDescriptionUpdate
	}, (input, flags) -> performAction('upgrade'))

	cli.command('install', {
		desc: locale.consoleDescriptionInstall,
		examples: ['install <plugin>']
	}, (input, flags) -> performAction('install', {plugin: input[0]}))

	cli.command('uninstall', {
		desc: locale.consoleDescriptionUninstall,
		examples: ['uninstall <plugin>']
	}, (input, flags) -> performAction('uninstall', {plugin: input[0]}))

	cli.command('info', {
		desc: locale.consoleDescriptionInfo
	}, (input, flags) ->
		instanceConfig.silent = true
		performAction('info')
	)

	# ---------------------------------
	# DocPad

	# Action
	performAction = (action, opts = {}, stayAlive) ->
		# Check if we are ready yet
		return  unless docpad

		# Continue with action
		docpad.action action, opts, (err) ->
			# Status
			if err
				docpad.fatal(new Errlop(locale.consoleFailed, err))
			else
				docpad.log('info', locale.consoleSuccess)

			###
			@todo determine if we want to keep this or not, as it is now unnecessary
			# Destroy docpad
			unless stayAlive
				docpad.destroy (err) ->
					# We don't care about logging the error, as it would have already been done
					process.exit(process.exitCode or (err and 1) or 0)
			###

	# Convert help command to --help
	process.argv[2] = '--help'  if process.argv[2] is 'help'

	# Fetch options
	result = cli.parse()

	# Exit if we are help
	return  if result.flags.help

	# Otherwie, apply the configuration options to the instanceConfig
	Object.keys(DocPad.prototype.initialConfig).forEach (name) ->
		value = result.flags[name]
		instanceConfig[name] ?= value  if value?

	# Exit
	process.once 'exit', (exitCode) ->
		# Log
		docpad.log('info', locale.consoleExit)

		# Handle any errors that occur when stdin is closed
		# https://github.com/docpad/docpad/pull/1049
		process.stdin?.on? 'error', (stdinError) ->
			# ignore ENOTCONN as it means stdin was already closed when we called stdin.end
			# node v8 and above have stdin.destroy to avoid emitting this error
			if stdinError.toString().indexOf('ENOTCONN') is -1
				err = new Errlop(
					"closing stdin encountered an error",
					stdinError
				)
				docpad.fatal(err)

		# Close stdin
		# https://github.com/docpad/docpad/issues/1028
		# https://github.com/docpad/docpad/pull/1029
		process.stdin?.destroy?() or process.stdin?.end?()

		# Wait a moment before outputting things that are preventing closure
		setImmediate ->
			# Note any requests that are still active
			activeRequests = process._getActiveRequests?()
			if activeRequests?.length
				docpadUtil.writeStderr """
					Waiting on these #{activeRequests.length} requests to close:
					#{docpad.inspect activeRequests}
					"""

			# Note any handles that are still active
			activeHandles = process._getActiveHandles?()
			if activeHandles?.length
				docpadUtil.writeStderr """
					Waiting on these #{activeHandles.length} handles to close:
					#{docpad.inspect activeHandles}
					"""

		# Chain
		@

	# Create
	docpad = new DocPad instanceConfig, (err) ->
		return docpad.fatal(err)  if err

		# CLI
		docpad.emitSerial 'consoleSetup', {cac: cli}, (err) ->
			return docpad.fatal(err)  if err

			# Help
			cli.command('*', {
				desc: locale.consoleDescriptionUnknown
			}, (input, flags) -> cli.showHelp())

			# Run the command
			cli.parse()


# ---------------------------------
# Fire

main()