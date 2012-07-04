# RequirestestServer
request = require('request')
balUtil = require('bal-util')
DocPad = require(__dirname+'/../lib/docpad')
chai = require('chai')
expect = chai.expect
joe = require('joe')

# -------------------------------------
# Configuration

# Vars
port = 9779
rootPath = __dirname+'/../../test'
srcPath = rootPath+'/src'
outPath = rootPath+'/out'
outExpectedPath = rootPath+'/out-expected'
baseUrl = "http://localhost:#{port}"
testWait = 1000*60*5  # five minutes

# Configure DocPad
docpadConfig =
	growl: false
	port: port
	rootPath: rootPath
	logLevel: 7 # if process.env.TRAVIS_NODE_VERSION? then 7 else 5
	skipUnsupportedPlugins: false
	catchExceptions: false

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
docpad = null
logger = null


# -------------------------------------
# Tests

joe.suite 'docpad-core', (suite,test) ->

	test 'create', (done) ->
		docpad = DocPad.createInstance docpadConfig, (err) ->
			done(err)

	test 'clean', (done) ->
		docpad.action 'clean', (err) ->
			done(err)

	test 'install', (done) ->
		docpad.action 'install', (err) ->
			done(err)

	suite 'generate', (suite,test) ->
		test 'action', (done) ->
			docpad.action 'generate', (err) ->
				done(err)

		suite 'results', (suite,test) ->
			testMarkup = (markupFile) ->
				test "#{markupFile}", (done) ->
					balUtil.readFile "#{outExpectedPath}/#{markupFile}", (err,expected) ->
						return done(err)  if err
						balUtil.readFile "#{outPath}/#{markupFile}", (err,actual) ->
							return done(err)  if err
							# trim whitespace, to avoid util conflicts between node versions and other oddities
							actualString = actual.toString().replace(/\s+/mg,'')
							expectedString = expected.toString().replace(/\s+/mg,'')
							# check equality
							expect(actualString).to.be.equal(expectedString)
							done()

			testMarkup(markupFile)  for markupFile in [
				'.htaccess'
				'attributes-nolayout.txt'
				'attributes-withlayout.txt'
				'coffee-parser.html'
				'correct-layout.html'
				'docpad-config-collection.html'
				'docpad-config-events.html'
				'file-different-extensions.ext1'
				'file-different-extensions.ext2'
				'file-dir-test.txt'
				'file.with.many.extensions'
				'html.html'
				'local-require.html'
				'public-dir-test.txt'
				'test-layout-single.html'
				'test-layout-double.html'
			]


	suite 'server', (suite,test) ->

		test 'server action', (done) ->
			docpad.action 'server', (err) ->
				done(err)

		test 'ignored "ignored" documents"', (done) ->
			balUtil.exists "#{outPath}/ignored.html", (exists) ->
				expect(exists).to.be.false
				done()

		test 'ignored common patterns documents"', (done) ->
			balUtil.exists "#{outPath}/.svn", (exists) ->
				expect(exists).to.be.false
				done()

		test 'served generated documents', (done) ->
			request "#{baseUrl}/html.html", (err,response,actual) ->
				return done(err)  if err
				balUtil.readFile "#{outExpectedPath}/html.html", (err,expected) ->
					return done(err)  if err
					expect(actual.toString()).to.be.equal(expected.toString())
					done()

		test 'served dynamic documents - part 1/2', (done) ->
			request "#{baseUrl}/dynamic.html?name=ben", (err,response,actual) ->
				return done(err)  if err
				expected = 'hi ben'
				expect(actual.toString()).to.be.equal(expected)
				done()

		test 'served dynamic documents - part 2/2', (done) ->
			request "#{baseUrl}/dynamic.html?name=joe", (err,response,actual) ->
				return done(err)  if err
				expected = 'hi joe'
				expect(actual.toString()).to.be.equal(expected)
				done()

	test 'completed', (done) ->
		done()
		process.exit(0)
