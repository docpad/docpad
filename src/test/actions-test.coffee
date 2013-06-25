# RequirestestServer
superAgent = require('superagent')
balUtil = require('bal-util')
safefs = require('safefs')
DocPad = require('../lib/docpad')
{expect} = require('chai')
joe = require('joe')
_ = require('lodash')
pathUtil = require('path')

# -------------------------------------
# Configuration

# Paths
docpadPath = pathUtil.join(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
srcPath    = pathUtil.join(rootPath, 'src')
outPath    = pathUtil.join(rootPath, 'out')
expectPath = pathUtil.join(rootPath, 'out-expected')
cliPath    = pathUtil.join(docpadPath, 'bin', 'docpad')

# Params
port = 9779
baseUrl = "http://localhost:#{port}"
testWait = 1000*60*5  # five minutes

# Configure DocPad
docpadConfig =
	growl: false
	port: port
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

joe.suite 'docpad-actions', (suite,test) ->

	test 'create', (done) ->
		docpad = DocPad.createInstance docpadConfig, (err) ->
			done(err)

	test 'config', (done) ->
		expected = {a:'instanceConfig',b:'instanceConfig',c:'websiteConfig'}

		config = docpad.getConfig()
		{a,b,c} = config
		expect({a,b,c}).to.deep.equal(expected)

		templateData = docpad.getTemplateData()
		{a,b,c} = templateData
		expect({a,b,c}).to.deep.equal(expected)

		done()

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
			testMarkup = (key,actual,expected) ->
				test key, ->
					# trim whitespace, to avoid util conflicts between node versions and other oddities
					# also address the slash backslash issue with windows and unix
					actualString = actual.trim().replace(/\s+/g,'').replace(/[\\]/g, '/')
					expectedString = expected.trim().replace(/\s+/g,'').replace(/[\\]/g, '/')
					# check equality
					expect(actualString).to.be.equal(expectedString)

			test 'same files', (done) ->
				balUtil.scandir(
					path:outPath
					readFiles: true
					ignoreHiddenFiles: false
					next: (err,outList) ->
						balUtil.scandir(
							path: expectPath
							readFiles: true
							ignoreHiddenFiles: false
							next: (err,expectList) ->
								# check we have the same files
								expect(_.difference(Object.keys(outList),Object.keys(expectList))).to.be.empty
								# check the contents of those files match
								for own key,actual of outList
									expected = expectList[key]
									testMarkup(key,actual,expected)
								# done with same file check
								# start the markup tests
								done()
						)
				)

		test 'ignored "ignored" documents"', (done) ->
			safefs.exists "#{outPath}/ignored.html", (exists) ->
				expect(exists).to.be.false
				done()

		test 'ignored common patterns documents"', (done) ->
			safefs.exists "#{outPath}/.svn", (exists) ->
				expect(exists).to.be.false
				done()

	suite 'server', (suite,test) ->

		test 'server action', (done) ->
			docpad.action 'server', (err) ->
				done(err)

		test 'served generated documents', (done) ->
			superAgent.get "#{baseUrl}/html.html", (err,res) ->
				return done(err)  if err
				actual = res.text
				safefs.readFile "#{expectPath}/html.html", (err,expected) ->
					return done(err)  if err
					expect(actual.toString().trim()).to.be.equal(expected.toString().trim())
					done()

		test 'served custom urls', (done) ->
			superAgent.get "#{baseUrl}/my-custom-url", (err,res) ->
				return done(err)  if err
				actual = res.text
				safefs.readFile "#{expectPath}/custom-url.html", (err,expected) ->
					return done(err)  if err
					expect(actual.toString().trim()).to.be.equal(expected.toString().trim())
					done()

		test 'served dynamic documents - part 1/2', (done) ->
			superAgent.get "#{baseUrl}/dynamic.html?name=ben", (err,res) ->
				return done(err)  if err
				actual = res.text
				expected = 'hi ben'
				expect(actual.toString().trim()).to.be.equal(expected)
				done()

		test 'served dynamic documents - part 2/2', (done) ->
			superAgent.get "#{baseUrl}/dynamic.html?name=joe", (err,res) ->
				return done(err)  if err
				actual = res.text
				expected = 'hi joe'
				expect(actual.toString().trim()).to.be.equal(expected)
				done()

	test 'completed', (done) ->
		done()
		process.exit(0)
