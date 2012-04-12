# Requires
assert = require('assert')
fs = require('fs')
request = require('request')
DocPad = require("#{__dirname}/../lib/docpad.coffee")
chai = require('chai')
expect = chai.expect


# -------------------------------------
# Configuration

# Vars
port = 9779
outPath = "#{__dirname}/out"
outExpectedPath = "#{__dirname}/out-expected"
baseUrl = "http://localhost:#{port}"

# Configure DocPad
docpadConfig = 
	growl: false
	port: port
	rootPath: __dirname
	logLevel: 5
	enabledPlugins:
		pygments: true

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
		@timeout(60000)
		docpad = DocPad.createInstance docpadConfig, (err) ->
			throw err  if err
			logger = docpad.logger
			done()

	it 'should run correctly', (done) ->
		@timeout(60000)
		docpad.action 'run', (err) ->
			throw err  if err
			done()

			describe 'generate', ->
				testMarkup = (markupName,markupFile) ->
					describe markupName, ->
						it "should generate #{markupName} files", (done) ->
							@timeout(5000)
							fs.readFile "#{outExpectedPath}/#{markupFile}", (err,expected) ->
								throw err  if err
								fs.readFile "#{outPath}/#{markupFile}", (err,actual) ->
									throw err  if err
									expect(actual.toString()).to.be.equal(expected.toString())
									done()
				testMarkup(markupName,markupFile)  for own markupName, markupFile of {
					"html": 'html.html'
					"coffee-parser": 'coffee-parser.html'
					'layout (1/2)': 'layout-single.html'
					'layout (2/2)': 'layout-double.html'
				}

			describe 'server', ->
				
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
			