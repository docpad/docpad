# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
safefs = require('safefs')
safeps = require('safeps')
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
outPath    = pathUtil.join(rootPath, 'render-actual-' + Math.floor(Math.random() * 100000))
expectPath = pathUtil.join(rootPath, 'render-expected')
cliPath    = pathUtil.join(docpadPath, 'bin', 'docpad')
nodePath   = null


# -------------------------------------
# Tests

joe.suite 'docpad-render', (suite,test) ->

	suite 'files', (suite,test) ->
		# Check render physical files
		items = [
			{
				filename: 'markdown-with-extension.md'
				stdout: '*awesome*'
			}
			{
				filename: 'markdown-with-extensions.html.md'
				stdout: '<p><em>awesome</em></p>'
			}
		]
		items.forEach (item) ->
			test item.filename, (done) ->
				# IMPORTANT THAT ANY OPTIONS GO AFTER THE RENDER CALL, SERIOUSLY
				# OTHERWISE the sky falls down on scoping, seriously, it is wierd
				command = ['node', cliPath, '--global', '--silent', 'render', pathUtil.join(renderPath,item.filename)]
				opts = {cwd:rootPath, output:false}
				safeps.spawn command, opts, (err,stdout,stderr,status,signal) ->
					stdout = (stdout or '').toString().trim()
					return done(err)  if err
					equal(
						stdout
						item.stdout
						'output'
					)
					return done()

	suite 'stdin', (suite,test) ->
		# Check rendering stdin items
		items = [
			{
				testname: 'markdown without filename'
				stdin: '*awesome*'
				error: locale.filenameMissingError
			}
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
			{
				testname: 'markdown with extension as filename, with -o'
				filename: 'markdown'
				stdin: '*awesome*'
				output: '<p><em>awesome</em></p>'
				outpath: pathUtil.join(outPath, 'outpath-render.html')
			}
		]
		items.forEach (item) ->
			test item.testname, (done) ->
				command = ['node', cliPath, '--global', 'render']
				command.push(item.filename)  if item.filename
				command.push('-o', item.outpath)  if item.outpath
				opts = {
					stdin: item.stdin,
					cwd: rootPath,
					output: false
				}
				safeps.spawn command, opts, (err,stdout,stderr,status,signal) ->
					stdout = (stdout or '').toString().trim()
					stderr = (stderr or '').toString().trim()

					if err
						if item.error?
							errorEqual(err, item.error, 'error was as expected')
						else
							return done(err)

					if item.stdout?
						equal(stdout, item.stdout, 'stdout')

					if item.stderr?
						equal(stderr, item.stderr, 'stderr')

					return done()  unless item.outpath

					safefs.readFile item.outpath, (err,data) ->
						return done(err)  if err

						if item.output?
							equal(data.toString().trim(), item.output, 'output')

						done()
