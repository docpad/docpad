# Requires
fs = require('fs')
request = require('request')
DocPad = require("#{__dirname}/../lib/docpad")
chai = require('chai')
expect = chai.expect


# -------------------------------------
# Configuration

# Vars
port = 9779
srcPath = "#{__dirname}/src"
outPath = "#{__dirname}/out"
outExpectedPath = "#{__dirname}/out-expected"
baseUrl = "http://localhost:#{port}"
testWait = 1000*60*5  # five minutes

# Configure DocPad
docpadConfig =
	growl: false
	port: port
	rootPath: __dirname
	logLevel: 5
	skipUnsupportedPlugins: false

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
docpad = null
logger = null


# -------------------------------------
# Tests

describe 'core', ->

	it 'should instantiate correctly', (done) ->
		@timeout(testWait)
		docpad = DocPad.createInstance docpadConfig, (err) ->
			throw err  if err
			done()

	it 'should install correctly', (done) ->
		@timeout(testWait)
		docpad.action 'install', (err) ->
			throw err  if err
			done()

	it 'should run correctly', (done) ->
		@timeout(testWait)
		docpad.action 'run', (err) ->
			throw err  if err
			done()

			describe 'generate', ->
				testMarkup = (markupFile) ->
					describe markupFile, ->
						it "should generate #{markupFile} files", (done) ->
							@timeout(testWait)
							fs.readFile "#{outExpectedPath}/#{markupFile}", (err,expected) ->
								throw err  if err
								fs.readFile "#{outPath}/#{markupFile}", (err,actual) ->
									throw err  if err
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
					'.htaccess'
					'html.html'
					'coffee-parser.html'
					'test-layout-single.html'
					'test-layout-double.html'
				]

			describe 'server', ->

				it 'should ignore "ignored" documents"', (done) ->
					path.exists "#{outPath}/ignored.html", (exists) ->
						expect(exists).to.be.false
						done()

				it 'should ignore common patterns documents"', (done) ->
					path.exists "#{outPath}/.svn", (exists) ->
						expect(exists).to.be.false
						done()

				it 'should serve generated documents', (done) ->
					request "#{baseUrl}/html.html", (err,response,actual) ->
						throw err  if err
						fs.readFile "#{outExpectedPath}/html.html", (err,expected) ->
							throw err  if err
							expect(actual.toString()).to.be.equal(expected.toString())
							done()

				it 'should serve dynamic documents - part 1/2', (done) ->
					request "#{baseUrl}/dynamic.html?name=ben", (err,response,actual) ->
						throw err  if err
						expected = 'hi ben'
						expect(actual.toString()).to.be.equal(expected)
						done()

				it 'should serve dynamic documents - part 2/2', (done) ->
					request "#{baseUrl}/dynamic.html?name=joe", (err,response,actual) ->
						throw err  if err
						expected = 'hi joe'
						expect(actual.toString()).to.be.equal(expected)
						done()
