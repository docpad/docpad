# Remote
{expect} = require('chai')

# Local
docpadUtil = require('../lib/util')

# Prepare
module.exports = testUtil =
	# Expect
	expect: (actual, expected, name) ->
		try
			expect(actual, name).to.equal(expected)
		catch err
			inspect 'actual:', docpadUtil.inspect(actual), 'expected:', docpadUtil.inspect(expected)
			throw err

	# Expect Deep
	expectDeep: (actual, expected, name) ->
		try
			expect(actual, name).to.deep.equal(expected)
		catch err
			inspect 'actual:', docpadUtil.inspect(actual), 'expected:', docpadUtil.inspect(expected)
			throw err
