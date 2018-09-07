module.exports = ->
	# ---------------------------------
	# Are we the desired DocPad installation?

	# Prepare
	docpadUtil = require('./util')

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
	# We are the desired DocPad installation

	# Prepare
	extendr = require('extendr')
	cli = require('cac')()
	locale = require('./locale/en')
	DocPad = require('./docpad')
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
	}, (input, flags) -> docpad?.action('run', {skeleton: flags.skeleton}))
		.option('skeleton', {
			type: 'string',
			desc: locale.consoleOptionSkeleton
		})

	cli.command('init', {
		desc: locale.consoleDescriptionInit
	}, (input, flags) -> docpad?.action('skeleton', {skeleton: flags.skeleton}))
		.option('skeleton', {
			type: 'string',
			desc: locale.consoleOptionSkeleton
		})

	cli.command('generate', {
		desc: locale.consoleDescriptionGenerate
	}, (input, flags) -> docpad?.action('generate'))

	cli.command('render', {
		desc: locale.consoleDescriptionRender,
		examples: [
			'docpad render <filename>',
			'docpad render <filepath>',
			"echo '*example*' | docpad render"
		]
	}, (input, flags) ->
		instanceConfig.silent = true
		docpad?.action('render', {
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
	}, (input, flags) -> docpad?.action('generate watch'))

	cli.command('clean', {
		desc: locale.consoleDescriptionClean
	}, (input, flags) -> docpad?.action('clean'))

	cli.command('update', {
		desc: locale.consoleDescriptionUpdate
	}, (input, flags) -> docpad?.action('clean update'))

	cli.command('upgrade', {
		desc: locale.consoleDescriptionUpdate
	}, (input, flags) -> docpad?.action('upgrade'))

	cli.command('install', {
		desc: locale.consoleDescriptionInstall,
		examples: ['install <plugin>']
	}, (input, flags) -> docpad?.action('install', {plugin: input[0]}))

	cli.command('uninstall', {
		desc: locale.consoleDescriptionUninstall,
		examples: ['uninstall <plugin>']
	}, (input, flags) -> docpad?.action('uninstall', {plugin: input[0]}))

	cli.command('info', {
		desc: locale.consoleDescriptionInfo
	}, (input, flags) ->
		instanceConfig.silent = true
		docpad?.action('info')
	)

	# ---------------------------------
	# DocPad

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
