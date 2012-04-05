# Export Plugin Tester
module.exports = (testers) ->
	# Define My Tester
	class MyTester extends testers.ServerTester
		testServer: (next) ->
			# Requires
			docpad = @docpad
			assert = testers.assert
			request = testers.request
			fs = require('fs')

			# Prepare
			baseUrl = "http://localhost:#{docpad.config.port}"
			outExpectedPath = @config.outExpectedPath

			# Test
			describe 'cleanurls server', ->
				it 'should support urls without an extension', (done) ->
					request "#{baseUrl}/welcome", (err,response,body) ->
						throw err  if err
						fs.readFile "#{outExpectedPath}/welcome.html", (err,actual) ->
							throw err  if err
							assert.equal(
								actual.toString()
								body
							)
							done()
							next?()