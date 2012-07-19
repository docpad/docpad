# RequirestestServer
balUtil = require('bal-util')
chai = require('chai')
expect = chai.expect
joe = require('joe')
_ = require('underscore')

# -------------------------------------
# Configuration

# Vars
port = 9780
docpadPath = __dirname+'/../..'
rootPath = docpadPath+'/test'
srcPath = rootPath+'/src'
outPath = rootPath+'/out'
outExpectedPath = rootPath+'/out-expected'
baseUrl = "http://localhost:#{port}"
testWait = 1000*60*5  # five minutes
cliPath = docpadPath+'/bin/docpad'

# Configure DocPad
docpadConfig =
	growl: false
	port: port
	rootPath: rootPath
	logLevel: if process.env.TRAVIS_NODE_VERSION? then 7 else 5
	skipUnsupportedPlugins: false
	catchExceptions: false


# -------------------------------------
# Tests

joe.suite 'docpad-render', (suite,test) ->

	test 'markdown-file', (done) ->
		command = [cliPath, 'render', 'src/documents/render-single-extensions-false.md']
		balUtil.spawn command, {cwd:rootPath}, (err,stdout,stderr,code,signal) ->
			console.log({stdout,err})
			done(err)
