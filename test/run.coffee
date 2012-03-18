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
					"coffee-parser": 'coffee-parser.html'
					coffeekup: 'coffeekup.html'
					eco: 'eco.html'
					eruby: 'eruby.html'
					haml: 'haml.html'
					hogan: 'hogan.html'
					jade: 'jade.html'
					'layout (1/2)': 'layout-single.html'
					'layout (2/2)': 'layout-double.html'
					less: 'less.css'
					markdown: 'markdown.html'
					move: 'move.js'
					php: 'php.html'
					'pygments-html-layout': 'pygments-html-layout.html'
					'pygments-html': 'pygments-html.html'
					'pygments-markdown': 'pygments-markdown.html'
					'related (1/2)': 'related-1.html'
					'related (2/2)': 'related-2.html'
					roy: 'roy.js'
					ruby: 'ruby.html'
					sass: 'sass.css'
					stylus: 'stylus.css'
					'stylus-nib': 'stylus-nib.css'
				}

			describe 'server', ->
				
				it 'should serve generated documents', (done) ->
					request "#{baseUrl}/markdown.html", (err,response,body) ->
						throw err  if err
						fs.readFile "#{outExpectedPath}/markdown.html", (err,actual) ->
							throw err  if err
							assert.equal(
								actual.toString()
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
			
			describe 'plugins', ->
				describe 'cleanurls', ->
					it 'should support urls without an extension', (done) ->
						request "#{baseUrl}/markdown", (err,response,body) ->
							throw err  if err
							fs.readFile "#{outExpectedPath}/markdown.html", (err,actual) ->
								throw err  if err
								assert.equal(
									actual.toString()
									body
								)
								done()