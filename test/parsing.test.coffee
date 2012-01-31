# Requires
assert = require('assert')
DocPad = require("#{__dirname}/../lib/docpad.coffee")


# -------------------------------------
# Configuration

# Configure DocPad
docpadConfig = 
	outPath: "#{__dirname}/out"
	srcPath: "#{__dirname}/src"

# Fail on an uncaught error
process.on 'uncaughtException', (err) ->
	throw err


# -------------------------------------
# Run

# Create docpad instance
docpad = DocPad.createInstance docpadConfig, (err) ->
	throw err  if err
	logger = docpad.logger
logger = docpad.logger


# -------------------------------------
# Test

tests =
	'parsing': ->
		docpad.action 'run', (err) ->
			throw err  if err
			assert.ok true


# -------------------------------------
# Export

# Export
module.exports = tests