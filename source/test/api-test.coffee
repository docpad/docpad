# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
{equal} = require('assert-helpers')
joe = require('joe')

# Local
docpadUtil = require('../lib/util')


# =====================================
# Configuration

# Paths
docpadPath = pathUtil.join(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
renderPath = pathUtil.join(rootPath, 'render')
expectPath = pathUtil.join(rootPath, 'render-expected')
cliPath    = pathUtil.join(docpadPath, 'bin', 'docpad')

# Configure DocPad
docpadConfig =
	action: false
	port: 9780
	rootPath: rootPath
	logLevel: docpadUtil.getDefaultLogLevel()
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
	suite 'create', (suite,test) ->
		test 'output configuration', ->
			console.log 'Creating DocPad with the configuration:\n'+require('../lib/util').inspect(docpadConfig)

		test 'create DocPad instance without an action', (done) ->
			docpad = require('../lib/docpad').create(docpadConfig, done)

		test 'load action', (done) ->
			docpad.action('load', done)

		test 'ready action', (done) ->
			docpad.action('ready', done)

	# Instantiate Files
	suite 'models', (suite,test) ->
		# Document
		suite 'document', (suite,tet) ->
			# Prepare
			document = null
			documentAttributes =
				meta:
					relativePath: "some/relative/path.txt"

			# Test
			test 'create', ->
				# Create
				document = docpad.createDocument(documentAttributes)

				# Add logging
				document.on('log', console.log.bind(console))

				# Checks
				equal(
					document.getMeta('relativePath')
					documentAttributes.meta.relativePath
					'meta relativePath'
				)
				equal(
					document.get('relativePath')
					documentAttributes.meta.relativePath
					'attr relativePath'
				)

			# Load
			test 'load', (complete) ->
				document.load (err) ->
					# Check
					return complete(err)  if err

					# Check
					equal(
						document.getMeta('relativePath')
						documentAttributes.meta.relativePath
						'relativePath'
					)

					# Complete
					return complete()

	# Render some input
	suite 'render', (suite,test) ->
		# Check rendering stdin inputs
		inputs = [
			{
				testname: 'markdown without extension'
				filename: 'file'
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
					equal(
						result.trim()
						input.stdout
						'output'
					)
					done()
