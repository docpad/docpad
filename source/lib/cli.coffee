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
	Errlop = require('errlop').default
	docpad = null
	instanceConfig = {}

	# Global options
	cli
		.option('--outpath <outPath>', locale.consoleOptionOutPath, {
			type: 'string'
		})
		.option('--config <configPaths>', locale.consoleOptionConfig, {
			type: 'string',
		})
		.option('--env <environment>', locale.consoleOptionEnv, {
			type: 'string',
		})
		.option('--log <logLevel>', locale.consoleOptionLogLevel, {
			type: 'string',
		})
		.option('--verbose, -v', locale.consoleOptionVerbose, {
			type: 'boolean',
		})
		.option('--debug, -d', locale.consoleOptionDebug, {
			type: 'boolean',
		})
		.option('--global', locale.consoleOptionGlobal, {
			type: 'boolean',
		})
		.option('--color, --colour', locale.consoleOptionColor, {
			default: true,
			type: 'boolean',
		})
		.option('--silent', locale.consoleOptionSilent, {
			type: 'boolean',
		})
		.option('--progress', locale.consoleOptionProgress, {
			default: true,
			type: 'boolean',
		})

	# Commands
	cli.command('run', locale.consoleDescriptionRun).action(-> docpad?.action('run'))

	cli.command('init', locale.consoleDescriptionInit).action(-> docpad?.action('init'))

	cli.command('generate', locale.consoleDescriptionGenerate).action(-> docpad?.action('generate'))

	cli.command('render [input]', locale.consoleDescriptionRender).action((input, options) ->
		instanceConfig.silent = true
		docpad?.action('render', {
			filename: input,
			renderSingleExtensions: 'auto',
			output: options?.output ? true,
			stdin: options?.stdin
		})
	).option('--output <output>', locale.consoleOptionOutput, {
		type: 'string',
	}).option('--stdin', locale.consoleOptionStdin, {
		type: 'boolean',
	}).example('docpad render <filename>').example('docpad render <filepath>').example("echo '*example*' | docpad render")

	cli.command('watch', locale.consoleDescriptionWatch).action(-> docpad?.action('generate watch'))

	cli.command('clean', locale.consoleDescriptionClean).action(-> docpad?.action('clean'))

	cli.command('update', locale.consoleDescriptionUpdate).action(-> docpad?.action('clean update'))

	cli.command('upgrade', locale.consoleDescriptionUpdate).action(-> docpad?.action('upgrade'))

	cli.command('install', locale.consoleDescriptionInstall).action(-> docpad?.action('install', {plugin: input[0]})).example('install <plugin>')

	cli.command('uninstall', locale.consoleDescriptionUninstall).action(-> docpad?.action('uninstall', {plugin: input[0]})).example('uninstall <plugin>')

	cli.command('info', locale.consoleDescriptionInfo).action(->
		instanceConfig.silent = true
		docpad?.action('info')
	)

	# Help
	cli.help()

	# Unknown
	cli.on('command:*', -> cli.showHelp())

	# ---------------------------------
	# DocPad

	# Fetch options
	result = cli.parse()

	# Exit if we are help
	return  if result.options.help

	# Otherwise, apply the configuration options to the instanceConfig
	Object.keys(DocPad.prototype.initialConfig).forEach (name) ->
		value = result.options[name]
		instanceConfig[name] ?= value  if value?

	# Create
	docpad = new DocPad instanceConfig, (err) ->
		if err
			console.error(err)
			return docpad.fatal(err)

		# CLI
		docpad.emitSerial 'consoleSetup', {cac: cli}, (err) ->
			if err
				console.error(err)
				return docpad.fatal(err)

			# Run the command
			cli.parse()
