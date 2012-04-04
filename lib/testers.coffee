# Requires
path = require('path')
_ = underscore = require('underscore')
balUtil = require('bal-util')
eyes = require('eyes')
chai = require('chai')
expect = chai.expect
assert = chai.assert
DocPad = require(path.join __dirname, 'docpad.coffee')


# Tester
class Tester
	# Requires
	eyes: eyes
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
class PluginTester extends Tester
	# Configuration
	config:
		pluginName: null
		pluginPath: null
		outExpectedPath: null
	docpadConfig:
		logLevel: 5
		rootPath: null
		loadPlugins: null
		enableUnlistedPlugins: false
		enabledPlugins: null

	# DocPad Instance
	docpad: null
	
	# Logger Instance
	logger: null

	# Constructor
	constructor: (config) ->
		# Prepare
		config or= {}

		# Apply Configuration
		@config = _.extend({},PluginTester::config,@config,config)
		@docpadConfig = _.extend({},PluginTester::docpadConfig,@docpadConfig)

		# Extend Configuration
		@config.testPath ?= path.join(@config.pluginPath,'test')
		@config.outExpectedPath ?= path.join(@config.testPath,'out-expected')

		# Extend DocPad Configuration
		@docpadConfig.rootPath ?= @config.testPath
		@docpadConfig.outPath ?= path.join(@docpadConfig.rootPath,'out')
		@docpadConfig.srcPath ?= path.join(@docpadConfig.rootPath,'src')
		@docpadConfig.loadPlugins ?= [@config.pluginPath]
		defaultEnabledPlugins = {}
		defaultEnabledPlugins[@config.pluginName] = true
		@docpadConfig.enabledPlugins ?= defaultEnabledPlugins

	# Create DocPad Instance
	createInstance: (next) ->
		# Prepare
		tester = @
		docpadConfig = _.extend({},@docpadConfig)

		# Create Instance
		@docpad = DocPad.createInstance docpadConfig, (err) ->
			return next(err)  if err
			tester.logger = tester.docpad.logger
			return next(err)

		# Chain
		@

	# Perform Generation
	performGeneration: (next) ->
		# Prepare
		docpad = @docpad

		# Handle
		docpad.action 'generate', next

		# Chain
		@

	# Test Creation
	testCreation: (next) ->
		# Prepare
		tester = @

		# Test
		describe "#{@config.pluginName}: create", ->
			it 'should create a docpad instance successfully', (done) ->
				@timeout(20*1000)
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
		describe "#{@config.pluginName}: load", ->
			it 'should load the plugin correctly', (done) ->
				@timeout(20*1000)
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
		describe "#{@config.pluginName}: generate", ->
			it 'should generate successfully', (done) ->
				@timeout(20*1000)
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


# Renderer Tester
class RendererTester extends PluginTester
	# Test everything
	test: (next) ->
		# Prepare
		tester = @

		# Group
		tasks = new balUtil.Group(next)

		# Run tests
		@testCreation (err) ->
			tasks.push (complete) ->
				tester.testLoaded(complete)
			tasks.push  (complete) ->
				tester.testGeneration(complete)
			tasks.sync()

		# Chain
		@


# Export Testers
module.exports = {
	Tester,
	PluginTester,
	RendererTester,
	underscore,
	balUtil,
	eyes,
	chai,
	expect,
	assert
}
