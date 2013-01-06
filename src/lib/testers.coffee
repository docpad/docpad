# Requires
pathUtil = require('path')
_ = underscore = require('underscore')
balUtil = require('bal-util')
joe = require('joe')
chai = require('chai')
expect = chai.expect
assert = chai.assert
request = require('request')
CSON = require('cson')
DocPad = require(__dirname+'/docpad')

# Prepare
pluginPort = 2000+process.pid
testers = {
	underscore,
	balUtil,
	chai,
	expect,
	assert,
	request,
	CSON,
	DocPad
}

# Plugin Tester
testers.PluginTester =
class PluginTester
	# Requires
	chai: chai
	expect: expect
	assert: assert

	# Configuration
	config:
		pluginName: null
		pluginPath: null
		autoExit: true
		testPath: null
		outExpectedPath: null
	docpadConfig:
		port: null
		growl: false
		logLevel: (if ('-d' in process.argv) then 7 else 5)
		rootPath: null
		outPath: null
		srcPath: null
		pluginPaths: null
		enableUnlistedPlugins: false
		enabledPlugins: null
		skipUnsupportedPlugins: false
		catchExceptions: false
		environment: null

	# DocPad Instance
	docpad: null

	# Logger Instance
	logger: null

	# Constructor
	constructor: (config={},docpadConfig={},next) ->
		# Apply Configuration
		tester = @
		@config = balUtil.deepExtendPlainObjects({}, PluginTester::config ,@config, config)
		@docpadConfig = balUtil.deepExtendPlainObjects({}, PluginTester::docpadConfig, @docpadConfig, docpadConfig)
		@docpadConfig.port ?= ++pluginPort
		@config.testerName ?= @config.pluginName

		# Extend Configuration
		@config.testPath or= pathUtil.join(@config.pluginPath,'test')
		@config.outExpectedPath or= pathUtil.join(@config.testPath,'out-expected')

		# Extend DocPad Configuration
		@docpadConfig.rootPath or= @config.testPath
		@docpadConfig.outPath or= pathUtil.join(@docpadConfig.rootPath,'out')
		@docpadConfig.srcPath or= pathUtil.join(@docpadConfig.rootPath,'src')
		@docpadConfig.pluginPaths ?= [@config.pluginPath]
		defaultEnabledPlugins = {}
		defaultEnabledPlugins[@config.pluginName] = true
		@docpadConfig.enabledPlugins or= defaultEnabledPlugins

		# Test API
		joe.describe @config.testerName, (suite,task,complete) ->
			tester.describe = tester.suite = suite
			tester.it = tester.test = task
			tester.done = tester.exit = complete
			next?(null,tester)

		# Chain
		@

	# Create DocPad Instance
	testCreate: ->
		# Prepare
		tester = @
		docpadConfig = @docpadConfig

		# Create Instance
		@test "create", (done) ->
			DocPad.createInstance docpadConfig, (err,docpad) ->
				return done(err)  if err
				tester.docpad = docpad
				tester.logger = docpad.logger
				tester.docpad.action 'clean', (err) ->
					return done(err)  if err
					tester.docpad.action 'install', (err) ->
						return done(err)

		# Chain
		@

	# Test Loaded
	testLoad: ->
		# Prepare
		tester = @

		# Test
		@test "load plugin #{tester.config.pluginName}", (done) ->
			tester.docpad.loadedPlugin tester.config.pluginName, (err,loaded) ->
				return done(err)  if err
				expect(loaded).to.be.ok
				return done()

		# Chain
		@

	# Perform Server
	testServer: (next) ->
		# Prepare
		tester = @

		# Handle
		@test "server", (done) ->
			tester.docpad.action 'server', (err) ->
				return done(err)

		# Chain
		@

	# Test Generate
	testGenerate: ->
		# Prepare
		tester = @

		# Test
		@test "generate", (done) ->
			tester.docpad.action 'generate', (err) ->
				return done(err)

		# Chain
		@

	# Test everything
	testEverything: ->
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

	# Finish
	finish: ->
		# Prepare
		tester = @

		# Finish
		if tester.config.autoExit
			@test 'finish up', (done) ->
				done()
				tester.exit()
				if tester.config.autoExit isnt 'safe'
					process.exit()

		# Chain
		@


# Server Tester
testers.ServerTester =
class ServerTester extends PluginTester


# Renderer Tester
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

			test 'results', (done) ->
				# Get actual results
				balUtil.scantree tester.docpadConfig.outPath, (err,outResults) ->
					return done(err)  if err
					# Get expected results
					balUtil.scantree tester.config.outExpectedPath, (err,outExpectedResults) ->
						return done(err)  if err
						# Test results
						expect(outResults).to.eql(outExpectedResults)
						# Forward
						done()

		# Chain
		@

# Test a plugin
# test({pluginPath: String})
testers.test =
test = (testerConfig, docpadConfig) ->
	# Configure
	testerConfig.pluginPath = pathUtil.resolve(testerConfig.pluginPath)
	testerConfig.pluginName ?= pathUtil.basename(testerConfig.pluginPath)
	testerConfig.testerPath ?= pathUtil.join('out', "#{testerConfig.pluginName}.tester.js")
	testerConfig.testerPath = pathUtil.resolve(testerConfig.pluginPath, testerConfig.testerPath)

	# Test the plugin's tester
	testerClass = require(testerConfig.testerPath)(testers)
	new testerClass testerConfig, docpadConfig, (err,testerInstance) ->
		throw err  if err
		testerInstance.testEverything()

	# Chain
	return testers

# Export Testers
module.exports = testers