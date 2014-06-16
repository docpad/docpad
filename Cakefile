# v1.3.20 June 16, 2014
# https://github.com/bevry/base


# =====================================
# Imports

fsUtil = require('fs')
pathUtil = require('path')


# =====================================
# Variables

WINDOWS          = process.platform.indexOf('win') is 0
NODE             = process.execPath
NPM              = (if WINDOWS then process.execPath.replace('node.exe', 'npm.cmd') else 'npm')
EXT              = (if WINDOWS then '.cmd' else '')
GIT              = "git"

APP_PATH         = process.cwd()
PACKAGE_PATH     = pathUtil.join(APP_PATH, "package.json")
PACKAGE_DATA     = require(PACKAGE_PATH)

MODULES_PATH     = pathUtil.join(APP_PATH, "node_modules")
DOCPAD_PATH      = pathUtil.join(MODULES_PATH, "docpad")
CAKE             = pathUtil.join(MODULES_PATH, "coffee-script/bin/cake")
COFFEE           = pathUtil.join(MODULES_PATH, "coffee-script/bin/coffee")
PROJECTZ         = pathUtil.join(MODULES_PATH, "projectz/bin/projectz")
DOCCO            = pathUtil.join(MODULES_PATH, "docco/bin/docco")
DOCPAD           = pathUtil.join(MODULES_PATH, "docpad/bin/docpad")
BISCOTTO         = pathUtil.join(MODULES_PATH, "biscotto/bin/biscotto")

config = {}
config.TEST_PATH           = "test"
config.DOCCO_SRC_PATH      = null
config.DOCCO_OUT_PATH      = "docs"
config.BISCOTTO_SRC_PATH   = null
config.BISCOTTO_OUT_PATH   = "docs"
config.COFFEE_SRC_PATH     = null
config.COFFEE_OUT_PATH     = "out"
config.DOCPAD_SRC_PATH     = null
config.DOCPAD_OUT_PATH     = "out"

for own key,value of (PACKAGE_DATA.cakeConfiguration or {})
	config[key] = value

for own key,value of config
	config[key] = pathUtil.resolve(APP_PATH, value)  if value


# =====================================
# Generic

{spawn, exec} = require('child_process')

safe = (next,fn) ->
	next ?= (err) -> console.log(err.stack ? err)
	fn ?= next  # support only one argument
	return (err) ->
		# success status code
		if err is 0
			err = null

		# error status code
		else if err is 1
			err = new Error('Process exited with error status code')

		# Error
		return next(err)  if err

		# Continue
		return fn()

finish = (err) ->
	throw err  if err
	console.log('OK')


# =====================================
# Actions

actions =
	clean: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Add compilation paths
		args = ['-Rf', config.COFFEE_OUT_PATH, config.DOCPAD_OUT_PATH, config.DOCCO_OUT_PATH]

		# Add common ignore paths
		for path in [APP_PATH, config.TEST_PATH]
			args.push(
				pathUtil.join(path,  'build')
				pathUtil.join(path,  'components')
				pathUtil.join(path,  'bower_components')
				pathUtil.join(path,  'node_modules')
				pathUtil.join(path,  '*out')
				pathUtil.join(path,  '*log')
			)

		# rm
		console.log('clean')
		spawn('rm', args, {stdio:'inherit', cwd:APP_PATH}).on('close', safe next)

	install: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('npm install (for app)')
			spawn(NPM, ['install'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step2)
		step2 = ->
			return step3()  if !config.TEST_PATH or !fsUtil.existsSync(config.TEST_PATH)
			console.log('npm install (for test)')
			spawn(NPM, ['install'], {stdio:'inherit', cwd:config.TEST_PATH}).on('close', safe next, step3)
		step3 = ->
			return step4()  if !fsUtil.existsSync(DOCPAD_PATH)
			console.log('npm install (for docpad tests)')
			spawn(NPM, ['install'], {stdio:'inherit', cwd:DOCPAD_PATH}).on('close', safe next, step4)
		step4 = next

		# Start
		step1()

	compile: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('cake install')
			actions.install(opts, safe next, step2)
		step2 = ->
			return step3()  if !config.COFFEE_SRC_PATH or !fsUtil.existsSync(COFFEE)
			console.log('coffee compile')
			spawn(NODE, [COFFEE, '-co', config.COFFEE_OUT_PATH, config.COFFEE_SRC_PATH], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step3)
		step3 = ->
			return step4()  if !config.DOCPAD_SRC_PATH or !fsUtil.existsSync(DOCPAD)
			console.log('docpad generate')
			spawn(NODE, [DOCPAD, 'generate'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step4)
		step4 = next

		# Start
		step1()

	watch: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('cake install')
			actions.install(opts, safe next, step2)
		step2 = ->
			return step3()  if !config.COFFEE_SRC_PATH or !fsUtil.existsSync(COFFEE)
			console.log('coffee watch')
			spawn(NODE, [COFFEE, '-wco', config.COFFEE_OUT_PATH, config.COFFEE_SRC_PATH], {stdio:'inherit', cwd:APP_PATH}).on('close', safe)  # background
			step3()  # continue while coffee runs in background
		step3 = ->
			return step4()  if !config.DOCPAD_SRC_PATH or !fsUtil.existsSync(DOCPAD)
			console.log('docpad run')
			spawn(NODE, [DOCPAD, 'run'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe)  # background
			step4()  # continue while docpad runs in background
		step4 = next

		# Start
		step1()

	test: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('cake compile')
			actions.compile(opts, safe next, step2)
		step2 = ->
			console.log('npm test')
			spawn(NPM, ['test'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step3)
		step3 = next

		# Start
		step1()

	prepublish: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('cake compile')
			actions.compile(opts, safe next, step2)
		step2 = ->
			return step3()  if !fsUtil.existsSync(PROJECTZ)
			console.log('projectz compile')
			spawn(NODE, [PROJECTZ, 'compile'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step3)
		step3 = ->
			return step4()  if !config.DOCCO_SRC_PATH or !fsUtil.existsSync(DOCCO)
			console.log('docco compile')
			exec("#{NODE} #{DOCCO} -o #{config.DOCCO_OUT_PATH} #{config.DOCCO_SRC_PATH}", {stdio:'inherit', cwd:APP_PATH}, safe next, step4)
		step4 = ->
			return step5()  if !config.BISCOTTO_SRC_PATH or !fsUtil.existsSync(BISCOTTO)
			console.log('biscotto compile')
			exec("""#{BISCOTTO} --name #{PACKAGE_DATA.title or PACKAGE_DATA.name} --title "#{PACKAGE_DATA.title or PACKAGE_DATA.name} API Documentation" --readme README.md --output-dir #{config.BISCOTTO_OUT_PATH} #{config.BISCOTTO_SRC_PATH} - LICENSE.md HISTORY.md""", {stdio:'inherit', cwd:APP_PATH}, safe next, step5)
		step5 = ->
			console.log('cake test')
			actions.test(opts, safe next, step5)
		step5 = next

		# Start
		step1()

	publish: (opts,next) ->
		# Prepare
		(next = opts; opts = {})  unless next?

		# Steps
		step1 = ->
			console.log('cake prepublish')
			actions.prepublish(opts, safe next, step2)
		step2 = ->
			console.log('npm publish')
			spawn(NPM, ['publish'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step3)
		step3 = ->
			console.log('git tag')
			spawn(GIT, ['tag', 'v'+PACKAGE_DATA.version, '-a'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step4)
		step4 = ->
			console.log('git push origin master')
			spawn(GIT, ['push', 'origin', 'master'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step5)
		step5 = ->
			console.log('git push tags')
			spawn(GIT, ['push', 'origin', '--tags'], {stdio:'inherit', cwd:APP_PATH}).on('close', safe next, step6)
		step6 = next

		# Start
		step1()


# =====================================
# Commands

commands =
	clean:       'clean up instance'
	install:     'install dependencies'
	compile:     'compile our files (runs install)'
	watch:       'compile our files initially, and again for each change (runs install)'
	test:        'run our tests (runs compile)'
	prepublish:  'prepare our package for publishing'
	publish:     'publish our package (runs prepublish)'

Object.keys(commands).forEach (key) ->
	description = commands[key]
	fn = actions[key]
	task key, description, (opts) ->  fn(opts, finish)
