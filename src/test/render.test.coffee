# RequirestestServer
balUtil = require('bal-util')
chai = require('chai')
expect = chai.expect
joe = require('joe')
_ = require('underscore')
pathUtil = require('path')

# -------------------------------------
# Configuration

# Vars
docpadPath = pathUtil.join(__dirname,'..','..')
rootPath = pathUtil.join(docpadPath,'test')
renderPath = pathUtil.join(rootPath,'render')
outPath = pathUtil.join(rootPath,'render-out')
expectPath = pathUtil.join(rootPath,'render-expected')
cliPath = pathUtil.join(docpadPath,'bin','docpad')
nodePath = null

# -------------------------------------
# Tests

joe.suite 'docpad-render', (suite,test) ->

	test 'nodePath', (done) ->
		balUtil.getNodePath (err,result) ->
			return done(err)  if err
			nodePath = result
			return done()

	suite 'files', (suite,test) ->
		# Check render physical files
		inputs = [
			{
				filename: 'markdown-with-extension.md'
				stdout: '*awesome*'
			}
			{
				filename: 'markdown-with-extensions.html.md'
				stdout: '<p><em>awesome</em></p>'
			}
		]
		balUtil.each inputs, (input) ->
			test input.filename, (done) ->
				command = [nodePath, cliPath, 'render', pathUtil.join(renderPath,input.filename)]
				balUtil.spawn command, {cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					expect(stdout.trim()).to.equal(input.stdout)
					done()

	suite 'stdin', (suite,test) ->
		# Check rendering stdin inputs
		inputs = [
			{
				testname: 'markdown without extension'
				filename: ''
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
		]
		balUtil.each inputs, (input) ->
			test input.testname, (done) ->
				command = [nodePath, cliPath, 'render']
				command.push(input.filename)  if input.filename
				balUtil.spawn command, {stdin:input.stdin,cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					expect(stdout.trim()).to.equal(input.stdout)
					done()

		# Works with out path
		test 'outPath', (done) ->
			input = {
				in: '*awesome*'
				out: '<p><em>awesome</em></p>'
				outPath: pathUtil.join(outPath,'outpath-render.html')
			}
			balUtil.spawn [nodePath, cliPath, 'render', 'markdown', '-o', input.outPath], {stdin:input.in, cwd:rootPath}, (err,stdout,stderr,code,signal) ->
				return done(err)  if err
				expect(stdout).to.equal('')
				balUtil.readFile input.outPath, (err,data) ->
					return done(err)  if err
					result = data.toString()
					expect(result.trim()).to.equal(input.out)
					done()