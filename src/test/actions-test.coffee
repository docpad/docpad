# =====================================
# Requires

# Standard Library
util = require('util')
pathUtil = require('path')

# External
{difference} = require('underscore')
superAgent = require('superagent')
scandir = require('scandirectory')
safefs = require('safefs')
{equal, deepEqual} = require('assert-helpers')
joe = require('joe')

# Local
DocPad = require('../lib/docpad')
docpadUtil = require('../lib/util')


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
port = 9770
hostname = "0.0.0.0"
baseUrl = "http://#{hostname}:#{port}"
testWait = 1000*60*5  # five minutes

# Configure DocPad
docpadConfig =
	port: port
	hostname: hostname
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

joe.suite 'docpad-actions', (suite,test) ->

	test 'create', (done) ->
		docpad = DocPad.createInstance docpadConfig, (err) ->
			done(err)

	test 'config', (done) ->
		expected = {a:'instanceConfig', b:'instanceConfig', c:'websiteConfig'}
		config = docpad.getConfig()
		{a,b,c} = config
		deepEqual(
			{a,b,c}
			expected
		)

		templateData = docpad.getTemplateData()
		{a,b,c} = templateData
		deepEqual(
			{a,b,c}
			expected
		)

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

		test 'writeSource', (done) ->
			file = docpad.getFileAtPath('writesource.txt.eco')
			file.writeSource(done)

		suite 'results', (suite,test) ->
			testMarkup = (key,actual,expected) ->
				test key, ->
					# trim whitespace, to avoid util conflicts between node versions and other oddities
					# also address the slash backslash issue with windows and unix
					actualString = actual.trim().replace(/\s+/g,'').replace(/([abc])[\\]+/g, '$1/')
					expectedString = expected.trim().replace(/\s+/g,'').replace(/([abc])[\\]+/g, '$1/')

					# check equality
					equal(
						actualString
						expectedString
					)

			test 'same files', (done) ->
				scandir(
					path: outPath
					readFiles: true
					ignoreHiddenFiles: false
					next: (err,outList) ->
						scandir(
							path: expectPath
							readFiles: true
							ignoreHiddenFiles: false
							next: (err,expectList) ->
								# check we have the same files
								deepEqual(
									difference(
										Object.keys(outList)
										Object.keys(expectList)
									)
									[]
									'difference to be empty'
								)

								# check the contents of those files match
								for own key,actual of outList
									expected = expectList[key]
									testMarkup(key, actual, expected)

								# done with same file check
								# start the markup tests
								done()
						)
				)

		test 'ignored "ignored" documents"', (done) ->
			safefs.exists "#{outPath}/ignored.html", (exists) ->
				equal(exists, false)
				done()

		test 'ignored common patterns documents"', (done) ->
			safefs.exists "#{outPath}/.svn", (exists) ->
				equal(exists, false)
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
					equal(
						actual.toString().trim()
						expected.toString().trim()
					)
					done()

		test 'served custom urls', (done) ->
			superAgent.get "#{baseUrl}/my-custom-url", (err,res) ->
				return done(err)  if err
				actual = res.text
				safefs.readFile "#{expectPath}/custom-url.html", (err,expected) ->
					return done(err)  if err
					equal(
						actual.toString().trim()
						expected.toString().trim()
					)
					done()

		test 'supports secondary urls - part 1/2', (done) ->
			superAgent.get "#{baseUrl}/my-secondary-urls1", (err,res) ->
				return done(err)  if err

				deepEqual(
					res.redirects
					['http://0.0.0.0:9770/secondary-urls.html']
					'redirects to be as expected'
				)

				actual = res.text
				safefs.readFile "#{expectPath}/secondary-urls.html", (err,expected) ->
					return done(err)  if err
					equal(
						actual.toString().trim()
						expected.toString().trim()
					)
					done()

		test 'supports secondary urls - part 2/2', (done) ->
			superAgent.get "#{baseUrl}/my-secondary-urls2", (err,res) ->
				return done(err)  if err

				deepEqual(
					res.redirects
					['http://0.0.0.0:9770/secondary-urls.html']
					'redirects to be as expected'
				)

				actual = res.text
				safefs.readFile "#{expectPath}/secondary-urls.html", (err,expected) ->
					return done(err)  if err
					equal(
						actual.toString().trim()
						expected.toString().trim()
					)
					done()

		test 'served dynamic documents - part 1/2', (done) ->
			superAgent.get "#{baseUrl}/dynamic.html?name=ben", (err,res) ->
				return done(err)  if err
				actual = res.text
				expected = 'hi ben'
				equal(
					actual.toString().trim()
					expected
				)
				done()

		test 'served dynamic documents - part 2/2', (done) ->
			superAgent.get "#{baseUrl}/dynamic.html?name=joe", (err,res) ->
				return done(err)  if err
				actual = res.text
				expected = 'hi joe'
				equal(
					actual.toString().trim()
					expected
				)
				done()

	test 'close the close', ->
		docpad.getServer(true).serverHttp.close()
