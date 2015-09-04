# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
safefs = require('safefs')
balUtil = require('bal-util')
extendr = require('extendr')
joe = require('joe')
assert = require('assert')
{equal, deepEqual, errorEqual} = require('assert-helpers')
CSON = require('cson')
{difference} = require('underscore')

# Local
DocPad = require('./docpad')
docpadUtil = require('./util')


# =====================================
# Helpers

# Prepare
# We want the plugn port to be a semi-random number above 2000
pluginPort = 2000 + parseInt(String(Date.now()).substr(-6, 4))
testers = {
	CSON,
	DocPad
}


# ---------------------------------
# Classes

###*
# The Plugin Tester class
# @class PluginTester
# @constructor
###
testers.PluginTester =
class PluginTester
	# Add support for BasePlugin.extend(proto)
	@extend: require('csextends')


	###*
	# Default plugin config
	# @property {Object}
	###
	config:
		testerName: null
		pluginName: null
		pluginPath: null
		testPath: null
		outExpectedPath: null
		removeWhitespace: false
		contentRemoveRegex: null
		autoExit: 'safe'

	###*
	# Default DocPad config
	# @property {Object}
	###
	docpadConfig:
		global: true
		port: null
		logLevel: (if ('-d' in process.argv) then 7 else 5)
		rootPath: null
		outPath: null
		srcPath: null
		pluginPaths: null
		enableUnlistedPlugins: true
		enabledPlugins: null
		skipUnsupportedPlugins: false
		catchExceptions: false
		environment: null


	###*
	# The DocPad instance
	# @private
	# @property {Object}
	###
	docpad: null
	
	###*
	# Constructor method
	# @method constructor
	# @param {Object} [config={}]
	# @param {Object} [docpadConfig={}]
	# @param {Function} next
	###
	constructor: (config={},docpadConfig={},next) ->
		# Apply Configuration
		tester = @
		@config = extendr.deepExtendPlainObjects({}, PluginTester::config, @config, config)
		@docpadConfig = extendr.deepExtendPlainObjects({}, PluginTester::docpadConfig, @docpadConfig, docpadConfig)
		@docpadConfig.port ?= ++pluginPort
		@config.testerName ?= "#{@config.pluginName} plugin"

		# Extend Configuration
		@config.testPath or= pathUtil.join(@config.pluginPath, 'test')
		@config.outExpectedPath or= pathUtil.join(@config.testPath, 'out-expected')

		# Extend DocPad Configuration
		@docpadConfig.rootPath or= @config.testPath
		@docpadConfig.outPath or= pathUtil.join(@docpadConfig.rootPath, 'out')
		@docpadConfig.srcPath or= pathUtil.join(@docpadConfig.rootPath, 'src')
		@docpadConfig.pluginPaths ?= [@config.pluginPath]
		defaultEnabledPlugins = {}
		defaultEnabledPlugins[@config.pluginName] = true
		@docpadConfig.enabledPlugins or= defaultEnabledPlugins

		# Test API
		joe.describe @config.testerName, (suite,task) ->
			tester.describe = tester.suite = suite
			tester.it = tester.test = task
			tester.done = tester.exit = (next) ->
				tester.docpad?.action('destroy', next)
			next?(null, tester)

		# Chain
		@


	###*
	# Get tester Configuration
	# @method getConfig
	# @return {Object}
	###
	getConfig: ->
		return @config

	###*
	# Get the plugin instance
	# @method getPlugin
	# @return {Object} the plugin
	###
	getPlugin: ->
		return @docpad.getPlugin(@getConfig().pluginName)


	###*
	# Create the DocPad instance
	# @method testCreate
	###
	testCreate: =>
		# Prepare
		tester = @
		docpadConfig = @docpadConfig

		# Create Instance
		@test "create", (done) ->
			new DocPad docpadConfig, (err, docpad) ->
				return done(err)  if err
				tester.docpad = docpad

				# init docpad in case the plugin is starting from scratch
				tester.docpad.action 'init', (err) ->
					if err and err.message isnt tester.docpad.getLocale().skeletonExists
						return done(err)  # care about the error providing it isn't the skeleton exists error

					# clean up the docpad out directory
					tester.docpad.action 'clean', (err) ->
						return done(err)  if err

						# install anything on the website that needs to be installed
						tester.docpad.action('install', done)

		# Chain
		@

	###*
	# Test Loaded
	# @method
	###
	testLoad: =>
		# Prepare
		tester = @

		# Test
		@test "load plugin #{tester.config.pluginName}", (done) ->
			tester.docpad.loadedPlugin tester.config.pluginName, (err,loaded) ->
				return done(err)  if err
				assert.ok(loaded)
				return done()

		# Chain
		@

	# Perform Server
	testServer: (next) =>
		# Prepare
		tester = @

		# Handle
		@test "server", (done) ->
			tester.docpad.action 'server', (err) ->
				return done(err)

		# Chain
		@

	###*
	# Test generate
	# @method
	###
	testGenerate: =>
		# Prepare
		tester = @

		# Test
		@test "generate", (done) ->
			tester.docpad.action 'generate', (err) ->
				return done(err)

		# Chain
		@

	###*
	# Test everything
	# @method {Object}
	###
	testEverything: =>
		# Prepare
		tester = @

		# Tests
		@testCreate()
		@testLoad()
		@testGenerate()
		@testServer()
		@testCustom?()

		# Finish
		@finish()

		# Chain
		@

	###*
	# Finish
	# @method finish
	###
	finish: ->
		# Prepare
		tester = @

		# Finish
		if tester.config.autoExit
			@test 'finish up', (next) ->
				tester.exit(next)

		# Chain
		@

###*
# Server tester
# @class ServerTester
# @extends PluginTester
# @constructor
###
testers.ServerTester =
class ServerTester extends PluginTester


###*
# Rednderer tester
# @class ServerTester
# @extends PluginTester
# @constructor
###
testers.RendererTester =
class RendererTester extends PluginTester
	# Test Generation
	testGenerate: ->
		# Prepare
		tester = @

		# Test
		@suite "generate", (suite,test) ->
			test 'action', (done) ->
				tester.docpad.action 'generate', (err) ->
					return done(err)

			suite 'results', (suite,test,done) ->
				# Get actual results
				balUtil.scanlist tester.docpadConfig.outPath, (err,outResults) ->
					return done(err)  if err

					# Get expected results
					balUtil.scanlist tester.config.outExpectedPath, (err,outExpectedResults) ->
						return done(err)  if err

						# Prepare
						outResultsKeys = Object.keys(outResults)
						outExpectedResultsKeys = Object.keys(outExpectedResults)

						# Check we have the same files
						test 'same files', ->
							outDifferenceKeys = difference(outExpectedResultsKeys, outResultsKeys)
							deepEqual(outDifferenceKeys, [], 'The following file(s) should have been generated')
							outDifferenceKeys = difference(outResultsKeys, outExpectedResultsKeys)
							deepEqual(outDifferenceKeys, [], 'The following file(s) should not have been generated')

						# Check the contents of those files match
						outResultsKeys.forEach (key) ->
							test "same file content for: #{key}", ->
								# Fetch file value
								actual = outResults[key]
								expected = outExpectedResults[key]

								# Remove empty lines
								if tester.config.removeWhitespace is true
									replaceLinesRegex = /\s+/g
									actual = actual.replace(replaceLinesRegex, '')
									expected = expected.replace(replaceLinesRegex, '')

								# Content regex
								if tester.config.contentRemoveRegex
									actual = actual.replace(tester.config.contentRemoveRegex, '')
									expected = expected.replace(tester.config.contentRemoveRegex, '')

								# Compare
								equal(actual, expected)

						# Forward
						done()

		# Chain
		@

###*
# Test a plugin
# test({pluginPath: String})
# @property test
###
testers.test =
test = (testerConfig, docpadConfig) ->
	# Configure
	testerConfig.testerClass ?= PluginTester
	testerConfig.pluginPath = pathUtil.resolve(testerConfig.pluginPath)
	testerConfig.pluginName ?= pathUtil.basename(testerConfig.pluginPath).replace('docpad-plugin-','')
	testerConfig.testerPath ?= pathUtil.join('out', "#{testerConfig.pluginName}.tester.js")
	testerConfig.testerPath = pathUtil.resolve(testerConfig.pluginPath, testerConfig.testerPath)  if testerConfig.testerPath

	# Create tester
	complete = ->
		# Accept string inputs for testerClass
		testerConfig.testerClass = testers[testerConfig.testerClass]  if typeof testerConfig.testerClass is 'string'

		# Create our tester
		new testerConfig.testerClass testerConfig, docpadConfig, (err,testerInstance) ->
			throw err  if err

			# Run the tests
			testerInstance.testEverything()

	# Load the tester file
	if testerConfig.testerPath
		safefs.exists testerConfig.testerPath, (exists) ->
			testerConfig.testerClass = require(testerConfig.testerPath)(testers)  if exists
			complete()

	# User the default tester
	else
		complete()

	# Chain
	return testers


# ---------------------------------
# Export Testers
module.exports = testers
