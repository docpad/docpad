# Requires
assert = require('assert')
fs = require('fs')
request = require('request')
util = require('bal-util')
DocPad = require("#{__dirname}/../lib/docpad.coffee")


# -------------------------------------
# Configuration

# Vars
port = 9779
outPath = "#{__dirname}/out"
outExpectedPath = "#{__dirname}/out-expected"
baseUrl = "http://localhost:#{port}"

# Configure DocPad
docpadConfig = 
	port: port
	rootPath: __dirname
	logLevel: 5

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
		docpad = DocPad.createInstance docpadConfig, (err) ->
			throw err  if err
			logger = docpad.logger
			done()

	it 'should run correctly', (done) ->
		docpad.action 'run', (err) ->
			throw err  if err
			done()

			describe 'generate', ->
				testMarkup = (markupName,markupFile) ->
					describe markupName, ->
						it "should generate #{markupName} files", (done) ->
							fs.readFile "#{outExpectedPath}/#{markupFile}", (err,expecting) ->
								throw err  if err
								fs.readFile "#{outPath}/#{markupFile}", (err,actual) ->
									throw err  if err
									assert.equal(
										expecting.toString()
										actual.toString()
									)
									done()
				testMarkup(markupName,markupFile)  for own markupName, markupFile of {
					coffeekup: 'coffeekup.html'
					haml: 'haml.html'
					jade: 'jade.html'
					markdown: 'markdown.html'
					stylus: 'stylus.css'
					'stylus-nib': 'stylus-nib.css'
				}

			describe 'plugins', ->
				describe 'cleanurls', ->
					it 'should support urls without an extension', (done) ->
						request "#{baseUrl}/markdown", (err,response,body) ->
							throw err  if err
							assert.equal(
								fs.readFileSync("#{outExpectedPath}/markdown.html").toString()
								body
							)
							done()
			
			describe 'server', ->
				
				it 'should serve generated documents', (done) ->
					request "#{baseUrl}/markdown.html", (err,response,body) ->
						throw err  if err
						assert.equal(
							fs.readFileSync("#{outExpectedPath}/markdown.html").toString()
							body
						)
						done()
				
				it 'should serve dynamic documents - part 1/2', (done) ->
					request "#{baseUrl}/dynamic.html?name=ben", (err,response,body) ->
						throw err  if err
						assert.equal(
							'hi ben'
							body
						)
						done()
					
				it 'should serve dynamic documents - part 2/2', (done) ->
					request "#{baseUrl}/dynamic.html?name=joe", (err,response,body) ->
						throw err  if err
						assert.equal(
							'hi joe'
							body
						)
						done()