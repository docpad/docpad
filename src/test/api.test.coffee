# RequirestestServer
{expect} = require('chai')
joe = require('joe')
pathUtil = require('path')

# -------------------------------------
# Configuration

# Paths
docpadPath = pathUtil.join(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
renderPath = pathUtil.join(rootPath, 'render')
expectPath = pathUtil.join(rootPath, 'render-expected')
cliPath    = pathUtil.join(docpadPath, 'bin', 'docpad')

# Configure DocPad
docpadConfig =
	growl: false
	port: 9780
	rootPath: rootPath
	logLevel: if process.env.TRAVIS_NODE_VERSION? then 7 else 5
	skipUnsupportedPlugins: false
	catchExceptions: false
	environments:
		development:
			a: 'instanceConfig'
			b: 'instanceConfig'
			templateData:
				a: 'instanceConfig'
				b: 'instanceConfig'

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
docpad = null


# -------------------------------------
# Tests

joe.suite 'docpad-api', (suite,test) ->

	# Create a DocPad Instance
	test 'createInstance', (done) ->
		docpad = require('../main').createInstance(docpadConfig,done)

	# Render some input
	suite 'render', (suite,test) ->
		# Check rendering stdin inputs
		inputs = [
			{
				testname: 'markdown without extension'
				filename: ''
				stdin: '*awesome*'
				stdout: '*awesome*'
			}
			{
				testname: 'markdown with extension as filename'
				filename: 'markdown'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with extension'
				filename: 'example.md'
				stdin: '*awesome*'
				stdout: '*awesome*'
			}
			{
				testname: 'markdown with extensions'
				filename: '.html.md'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with filename'
				filename: 'example.html.md'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
			}
		]
		inputs.forEach (input) ->
			test input.testname, (done) ->
				opts =
					data: input.stdin
					filename: input.filename
					renderSingleExtensions: 'auto'
				docpad.action 'render', opts, (err,result) ->
					return done(err)  if err
					expect(result.trim()).to.equal(input.stdout)
					done()
