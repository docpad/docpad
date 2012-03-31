#!/usr/bin/env coffee
path = require('path')
DocPad = require(path.join __dirname, '..', 'lib', 'docpad.coffee')
ConsoleInterface = require(path.join __dirname, '..', 'lib', 'interfaces', 'console.coffee')

# Create Program
program = require(path.join __dirname, '..', 'node_modules', 'commander', 'index.js')

# Configure Instance
docpadConfig = {}
docpadConfig.skeleton = program.skeleton  if program.skeleton
docpadConfig.port = program.port  if program.port

# Create Instance
docpad = DocPad.createInstance docpadConfig, (err) ->
	# Check
	throw err  if err

	# Create Console Interface
	consoleInterface = new ConsoleInterface({docpad,program})

	# Start
	consoleInterface.start()