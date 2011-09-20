#!/usr/bin/env coffee
docpad = require (__dirname + '/../lib/docpad.coffee')
fs = require('fs')
packageJSON = JSON.parse(fs.readFileSync(__dirname + '/../package.json'))
program = require 'commander'
cwd = process.cwd()


program
	.version(packageJSON.version)
	.option('-c, --cmd <cmd>'						, 'Launch specific command (skeleton|generate|watch|server|all) <cmd>')
	.option('-r, --rootpath <root>'			, 'Use specified <root> path or defaults to ' + cwd )
	.option('-o, --outpath <out>'				, 'Use specified <out> path or defaults to ' + cwd + '/out')
	.option('-s, --srcpath <src>'				, 'Use specified <src> path or defaults to ' + cwd + '/src')
	.option('-S, --skeletonspath <skel>', 'Use specified <skel> skeletons starting setup or defaults to ' + cwd + '/skeletons/bootstrap')
	.option('-m, --maxage <maxage>'			, 'Set maxAge at the specified <maxage> value')
	.option('-l, --listen <port>'				, 'Make server listen on <port> or defaults to 9788', parseInt) 
	.option('-z, --server'							, 'wth is this? ** FIX ME **')
	.option('-d, --debug'								, 'enable Debug')
	.parse(process.argv)

config = 	
	command				: ( program.cmd 		 											),
	rootPath			: ( program.rootpath or cwd 							),
	outPath				: ( program.outpath  or cwd + '/out'			),
	srcPath				: ( program.srcpath  or cwd + '/src'			),
	skeletonsPath	: ( program.skeletonspath or __dirname+'/../skeletons' ),
	maxAge				: ( program.maxage 				),
	port					: ( program.listen 				),
	server				: ( program.server 				)

##create a config object and call the istance with the
if (program.cmd)
	docpad.createInstance(config) or false
else 
	program.emit('help')
	