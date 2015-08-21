# =====================================
# Requires

# Standard Library
pathUtil = require('path')

# External
safefs = require('safefs')
safeps = require('safeps')
{equal} = require('assert-helpers')
joe = require('joe')

# Local
docpadUtil = require('../lib/util')


# =====================================
# Configuration

# Paths
docpadPath = pathUtil.join(__dirname, '..', '..')
rootPath   = pathUtil.join(docpadPath, 'test')
renderPath = pathUtil.join(rootPath, 'render')
outPath    = pathUtil.join(rootPath, 'render-out')
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
				testname: 'markdown without extension'
				filename: ''
				stdin: '*awesome*'
				stdout: '*awesome*'
				error: 'Error: filename is required'
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
		]
		items.forEach (item) ->
			test item.testname, (done) ->
				command = ['node', cliPath, '--global', 'render']
				command.push(item.filename)  if item.filename
				opts = {stdin:item.stdin, cwd:rootPath, output:false}
				safeps.spawn command, opts, (err,stdout,stderr,status,signal) ->
					stdout = (stdout or '').toString().trim()
					return done(err)  if err
					return done()  if item.error and stdout.indexOf(item.error)
					equal(
						stdout
						item.stdout
						'output'
					)
					done()

		# Works with out path
		test 'outPath', (done) ->
			item = {
				in: '*awesome*'
				out: '<p><em>awesome</em></p>'
				outPath: pathUtil.join(outPath, 'outpath-render.html')
			}
			command = ['node', cliPath, '--global', 'render', 'markdown', '-o', item.outPath]
			opts = {stdin:item.in, cwd:rootPath, output:false}
			safeps.spawn command, opts, (err,stdout,stderr,status,signal) ->
				stdout = (stdout or '').toString().trim()
				return done(err)  if err
				equal(
					stdout
					''
				)
				safefs.readFile item.outPath, (err,data) ->
					return done(err)  if err
					result = data.toString().trim()
					equal(
						result
						item.out
						'output'
					)
					done()
