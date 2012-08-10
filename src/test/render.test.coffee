# RequirestestServer
balUtil = require('bal-util')
chai = require('chai')
expect = chai.expect
joe = require('joe')
_ = require('underscore')
pathUtil = require('path');

# -------------------------------------
# Configuration

# Vars
docpadPath = __dirname+'/../..'
rootPath = docpadPath+'/test'
renderPath = rootPath+'/render'
outPath = rootPath+'/render-out'
expectPath = rootPath+'/render-expected'
cliPath = pathUtil.resolve(docpadPath+'/bin/docpad')
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
				command = [nodePath, cliPath, 'render', pathUtil.resolve(renderPath+'/'+input.filename)]
				balUtil.spawn command, {cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					console.log({expect:stdout,toEqual:input})
					expect(stdout).to.equal(input.stdout)
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
				testname: 'markdown with extension'
				filename: 'markdown'
				stdin: '*awesome*'
				stdout: '<p><em>awesome</em></p>'
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
				command = [cliPath, 'render']
				command.push(input.filename)  if input.filename
				balUtil.spawn command, {stdin:input.stdin,cwd:rootPath}, (err,stdout,stderr,code,signal) ->
					return done(err)  if err
					expect(stdout).to.equal(input.stdout)
					done()

		# Works with out path
		test 'outPath', (done) ->
			input = {
				in: '*awesome*'
				out: '<p><em>awesome</em></p>'
				outPath: outPath+'/outpath-render.html'
			}
			balUtil.spawn [cliPath, 'render', 'markdown', '-o', input.outPath], {stdin:input.in, cwd:rootPath}, (err,stdout,stderr,code,signal) ->
				return done(err)  if err
				expect(stdout).to.equal('')
				balUtil.readFile outPath+'/outpath-render.html', (err,data) ->
					return done(err)  if err
					result = data.toString()
					expect(result).to.equal(input.out)
					done()
