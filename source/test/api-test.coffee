# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
{equal, errorEqual} = require('assert-helpers')
joe = require('joe')

# Local
docpadUtil = require('../lib/util')
locale = require('../lib/locale/en')


# =====================================
# Configuration

# Paths
docpadPath = pathUtil.join(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
renderPath = pathUtil.join(rootPath, 'render')
expectPath = pathUtil.join(rootPath, 'render-expected')

# Configure DocPad
docpadConfig =
	action: false
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
			console.log 'Creating DocPad with the configuration:\n' + docpadUtil.inspect(docpadConfig)

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

	# Render action
	suite 'render', (suite,test) ->
		# Check rendering stdin items
		items = [
			{
				testname: 'markdown without filename'
				input: '*awesome*'
				error: locale.filenameMissingError
			}
			{
				testname: 'markdown without extension'
				filename: 'file'
				input: '*awesome*'
				output: '*awesome*'
			}
			{
				testname: 'markdown with extension as filename'
				filename: 'markdown'
				input: '*awesome*'
				output: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with extension'
				filename: 'example.md'
				input: '*awesome*'
				output: '*awesome*'
			}
			{
				testname: 'markdown with extensions'
				filename: '.html.md'
				input: '*awesome*'
				output: '<p><em>awesome</em></p>'
			}
			{
				testname: 'markdown with filename'
				filename: 'example.html.md'
				input: '*awesome*'
				output: '<p><em>awesome</em></p>'
			}
		]
		items.forEach (item) ->
			test item.testname, (done) ->
				opts = {
					data: item.input
					filename: item.filename or null
					renderSingleExtensions: 'auto'
				}
				docpad.action 'render', opts, (err,result) ->
					if err
						if item.error?
							errorEqual(err, item.error, 'error was as expected')
						else
							return done(err)

					if item.output?
						equal(result.trim(), item.output, 'output')

					done()
