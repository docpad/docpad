# Requires
pathUtil = require('path')
_ = underscore = require('underscore')
balUtil = require('bal-util')
chai = require('chai')
expect = chai.expect
assert = chai.assert
request = require('request')
CSON = require('cson')
DocPad = require(__dirname+'/docpad')

# Prepare
pluginPort = 3183
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

# Tester
testers.Tester =
class Tester
	# Requires
	chai: chai
	expect: expect
	assert: assert

	# Test
	test: ->
		# Run all your tests here
		# ...

		# Chain
		@


# Plugin Tester
testers.PluginTester =
class PluginTester extends Tester
	# Configuration
	config:
		pluginName: null
		pluginPath: null
		outExpectedPath: null
	docpadConfig:
		port: pluginPort++
		growl: false
		logLevel: (if ('-d' in process.argv) then 7 else 5)
		rootPath: null
		pluginPaths: null
		enableUnlistedPlugins: false
		enabledPlugins: null

	# DocPad Instance
	docpad: null

	# Logger Instance
	logger: null

	# Constructor
	constructor: (config) ->
		# Apply Configuration
		@config = _.extend({},PluginTester::config,@config,config or {})
		@docpadConfig = _.extend({},PluginTester::docpadConfig,@docpadConfig)

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

	# Create DocPad Instance
	createInstance: (next) ->
		# Prepare
		tester = @
		docpadConfig = _.extend({},@docpadConfig)

		# Create Instance
		@docpad = DocPad.createInstance docpadConfig, (err) ->
			return next(err)  if err
			tester.logger = tester.docpad.logger
			tester.docpad.action 'clean', (err) ->
				return next(err)  if err
				tester.docpad.action 'install', (err) ->
					return next(err)

		# Chain
		@

	# Perform Server
	performServer: (next) ->
		# Prepare
		docpad = @docpad

		# Handle
		docpad.action 'server', (err) ->
			next(err)

		# Chain
		@

	# Perform Generation
	performGeneration: (next) ->
		# Prepare
		docpad = @docpad

		# Handle
		docpad.action 'generate', (err) ->
			next(err)

		# Chain
		@

	# Test Creation
	testCreation: (next) ->
		# Prepare
		tester = @

		# Test
		describe "create", ->
			it 'should create a docpad instance successfully', (done) ->
				@timeout(60*5000)
				tester.createInstance (err) ->
					done(err)
					next()

		# Chain
		@

	# Test Loaded
	testLoaded: (next) ->
		# Prepare
		config = @config
		docpad = @docpad

		# Test
		describe "#{@config.pluginName} load", ->
			it 'should load the plugin correctly', (done) ->
				@timeout(60*5000)
				docpad.loadedPlugin config.pluginName, (err,loaded) ->
					return done(err)  if err
					expect(loaded).to.be.ok
					done()
					next()

		# Chain
		@

	# Test Generation
	testGeneration: (next) ->
		# Prepare
		tester = @
		docpad = @docpad

		# Test
		describe "#{@config.pluginName} generate", ->
			it 'should generate successfully', (done) ->
				@timeout(60*5000)
				# Test
				tester.performGeneration (err) ->
					return done(err)  if err
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
							next()

		# Chain
		@


# Server Tester
testers.ServerTester =
class ServerTester extends PluginTester
	# Test everything
	test: (next) ->
		# Prepare
		tester = @

		# Group
		tasks = new balUtil.Group(next)

		# Create
		tester.testCreation ->
			# Generate
			tester.performGeneration (err) ->
				throw err  if err
				# Serve
				tester.performServer (err) ->
					throw err  if err
					# Create Tests
					tasks.push (complete) ->
						tester.testLoaded(complete)
					tasks.push  (complete) ->
						tester.testServer(complete)
					# Run Tests
					tasks.sync()

		# Chain
		@

	# Test server
	testServer: (next) ->
		next?()


# Renderer Tester
testers.RendererTester =
class RendererTester extends PluginTester
	# Test everything
	test: (next) ->
		# Prepare
		tester = @

		# Group
		tasks = new balUtil.Group(next)

		# Create
		tester.testCreation ->
			# Create Tests
			tasks.push (complete) ->
				tester.testLoaded(complete)
			tasks.push  (complete) ->
				tester.testGeneration(complete)
			# Run Tests
			tasks.sync()

		# Chain
		@


# Test a plugin
# test({pluginPath: String})
testers.test =
test = (pluginDetails) ->
	# Configure
	pluginDetails.pluginPath = pathUtil.resolve(pluginDetails.pluginPath)
	pluginDetails.pluginName ?= pathUtil.basename(pluginDetails.pluginPath)
	pluginDetails.testerPath ?= pathUtil.join('out', "#{pluginDetails.pluginName}.tester.js")
	pluginDetails.testerPath = pathUtil.resolve(pluginDetails.pluginPath, pluginDetails.testerPath)

	# Test the plugin's tester
	describe pluginDetails.pluginName, ->
		testerClass = require(pluginDetails.testerPath)(testers)
		testerInstance = new testerClass(
			pluginName: pluginDetails.pluginName
			pluginPath: pluginDetails.pluginPath
		)
		testerInstance.test ->

	# Chain
	@

# Export Testers
module.exports = testers