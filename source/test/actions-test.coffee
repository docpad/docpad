# =====================================
# Requires

# Standard Library
util = require('util')
pathUtil = require('path')

# External
{difference} = require('underscore')
scandir = require('scandirectory')
safefs = require('safefs')
{equal, deepEqual} = require('assert-helpers')
kava = require('kava')

# Local
DocPad = require('../lib/docpad')
docpadUtil = require('../lib/util')


# -------------------------------------
# Configuration

# Paths
docpadPath = pathUtil.resolve(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
srcPath    = pathUtil.join(rootPath, 'src')
outPath    = pathUtil.join(rootPath, 'out-actual-' + Math.floor(Math.random() * 100000))
expectPath = pathUtil.join(rootPath, 'out-expected')

# Params
testWait = 1000*60*5  # five minutes

# Configure DocPad
docpadConfig =
	rootPath: rootPath
	outPath: outPath
	logLevel: docpadUtil.getTestingLogLevel()
	catchExceptions: false
	b: 'instanceConfig'  # overwrite
	c: 'instanceConfig'  # insert
	templateData:
		b: 'instanceConfig templateData'    # overwrite
		c: 'instanceConfig templateData'    # insert
	environments:
		development:
			b: 'instanceConfig development'  # overwrite
			c: 'instanceConfig development'  # insert
			templateData:
				b: 'instanceConfig templateData development'    # overwrite
				c: 'instanceConfig templateData development'    # insert

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err

# Local globals
docpad = null


# -------------------------------------
# Tests

kava.suite 'docpad-actions', (suite,test) ->

	test 'create', (done) ->
		docpad = DocPad.create(docpadConfig, done)

	test 'config', ->
		expected = {a:'websiteConfig development', b:'instanceConfig development', c:'instanceConfig development'}
		config = docpad.getConfig()
		{a,b,c} = config
		deepEqual(
			{a,b,c}
			expected,
			"config matched"
		)

	test 'config templateData', ->
		expected = {a:'websiteConfig templateData development', b:'instanceConfig templateData development', c:'instanceConfig templateData development'}
		templateData = docpad.getTemplateData()
		{a,b,c} = templateData
		deepEqual(
			{a,b,c}
			expected,
			"template data matched"
		)

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
