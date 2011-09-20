#!/usr/bin/env coffee
###
DocPad command line interface by Benjamin Lupton and ~eldios

$ docpad
> Welcome to DocPad!
> You current working directory isn't currently setup for docpad, would you like us to?
>     
###

# Requires
docpad = require "#{__dirname}/../lib/docpad.coffee"
fs = require 'fs'
program = require 'commander'
packageJSON = JSON.parse fs.readFileSync("#{__dirname}/../package.json").toString()
cwd = process.cwd()

# Options
program
	.version(
		packageJSON.version
	)
	.option(
		'-s, --skeleton <skeleton>'
		"The skeleton to create your project from, defaults to #{__dirname}/skeletons/bootstrap"
	)
	.option(
		'-p, --port <port>'
		"The port to use for the docpad server <port>, defaults to 9788"
		parseInt
	) 
	.option(
		'-d, --debug [level]'
		"The level of debug messages you would like to display, if specified defaults to 7, otherwise 6"
		parseInt
	)

# Load
program.parse process.argv
config = 	
	skeleton: program.skeleton
	port: program.port
	logLevel: if program.debug is true then 7 else 6

# Start
docpad.createInstance(config) or false

# Log
console.log config.logLevel