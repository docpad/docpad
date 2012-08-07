# RequirestestServer
balUtil = require('bal-util')
chai = require('chai')
expect = chai.expect
joe = require('joe')
_ = require('underscore')

# -------------------------------------
# Configuration

# Vars
docpadPath = __dirname+'/../..'
rootPath = docpadPath+'/test'
renderPath = rootPath+'/render'
outPath = rootPath+'/render-out'
expectPath = rootPath+'/render-expected'
cliPath = docpadPath+'/bin/docpad'


# -------------------------------------
# Tests

joe.suite 'docpad-render', (suite,test) ->

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
			command = [cliPath, 'render', renderPath+'/'+input.filename]
			balUtil.spawn command, {cwd:rootPath}, (err,stdout,stderr,code,signal) ->
				return done(err)  if err
				expect(stdout).to.equal(input.stdout)
				done()

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
