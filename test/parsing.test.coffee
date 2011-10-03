# Requires
assert = require 'assert'
Docpad = require __dirname+'/../lib/docpad.coffee'

# -------------------------------------
# Data

# Files
files =
	noMetaData: '''
		This is a page with no meta data
		'''
	
	withMetaData: '''
		---
		title: "Some awesome title goes here"
		date: "2011-12-25"
		---

		This is a page with meta data
		'''


# -------------------------------------
# Tests

# Tests
tests =
	'parsing-noMetaData': ->
		docpad = Docpad.createInstance()
		file = docpad.createFile source: files.noMetaData

# -------------------------------------
# Export

# Export
module.exports = tests