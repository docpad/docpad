# Export Plugin Tester
module.exports = (testers) ->
	# Define My Tester
	class MyTester extends testers.ServerTester
		testServer: (next) ->
			# Requires
			docpad = @docpad
			expect = testers.expect
			request = testers.request
			fs = require('fs')

			# Prepare
			baseUrl = "http://localhost:#{docpad.config.port}"
			outExpectedPath = @config.outExpectedPath

			# Test
			describe 'cleanurls server', ->
				it 'should support urls without an extension', (done) ->
					request "#{baseUrl}/welcome.html", (err,response,actual) ->
						throw err  if err
						fs.readFile "#{outExpectedPath}/welcome.html", (err,expected) ->
							throw err  if err
							expect(actual.toString()).to.equal(expected.toString())
							done()
							next?()