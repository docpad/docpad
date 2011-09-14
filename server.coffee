docpad = require __dirname+'/lib/docpad.coffee'
program = require 'commander'

program
	.version('0.0.1')
	.option('-c, --command <cmd>'				, 'Launch specific command (skeleton|generate|watch|server)<cmd>')
	.option('-r, --rootpath <root>'			, 'Use specified <root> path or defaults to .')
	.option('-o, --outpath <out>'				, 'Use specified <out> path or defaults to ./out')
	.option('-s, --srcpath <src>'				, 'Use specified <src> path or defaults to ./src')
	.option('-S, --skeletonspath <skel>', 'Use specified <skel> skeleton path or defaults to ./skeleton')
	.option('-m, --maxage <maxage>'			, 'Set maxAge at the specified <maxage> value')
	.option('-l, --listen <port>'				, 'Make server listen on <port> or defaults to 9788', parseInt) 
	.option('-z, --server'							, 'wth is this? ** FIX ME **')
	.parse(process.argv)

config = {
	'command'				: ( if (program.command 			is true) then 'cmd' else undefined ),
	'rootPath'			: ( if (program.rootpath 			is true) then 'root' else './' ),
	'outPath'				: ( if (program.outpath 			is true) then 'out' else './out' ),
	'srcPath'				: ( if (program.srcpath 			is true) then 'src' else './src' ),
	'skeletonsPath'	: ( if (program.skeletonspath is true) then 'skel' else './skeletons' ),
	'maxAge'				: ( if (program.maxage 				is true) then 'maxage' else undefined ),
	'port'					: ( if (program.listen 				is true) then 'port' else 9788 ),
	'server'				: ( program.server? )
}
#create a config object and call the istance with the
#docpad.createInstance(config).action process.argv[2] || false
console.log(config)