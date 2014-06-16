# ---------------------------------
# Check node version right away

if process.versions.node.indexOf('0') is 0 and process.versions.node.split('.')[1] % 2 isnt 0
	console.log require('util').format(
		"""
		== WARNING ==
		   DocPad is running against an unstable version of Node.js (v%s to be precise).
		   Unstable versions of Node.js WILL break things! Do not use them with DocPad!
		   Run DocPad with a stable version of Node.js (e.g. v%s) for a stable experience.
		   For more information, visit: %s
		== WARNING ===
		"""
		process.versions.node, "0."+(process.versions.node.split('.')[1]-1), "http://docpad.org/unstable-node"
	)


# ---------------------------------
# Check for Local DocPad Installation

checkDocPad = ->
	# Skip if we explcitly want to use the global installation
	if '--global' in process.argv or '--g' in process.argv
		return startDocPad()

	# Prepare
	docpadUtil = require('../lib/util')

	# Skip if we are already the local installation
	if docpadUtil.isLocalDocPadExecutable()
		return startDocPad()

	# Skip if the local installation doesn't exist
	if docpadUtil.getLocalDocPadExecutableExistance() is false
		return startDocPad()

	# Forward to the local installation
	return docpadUtil.startLocalDocPadExecutable()

# ---------------------------------
# Start our DocPad Installation

startDocPad = ->
	# Require
	DocPad = require('../lib/docpad')
	ConsoleInterface = require('../lib/interfaces/console')

	# Fetch action
	action =
		# we should eventually do a load always
		# but as it is a big change of functionality, lets only do it inclusively for now
		if process.argv[1...].join(' ').indexOf('deploy') isnt -1  # if we are the deploy command
			'load'
		else  # if we are not the deploy command
			false

	# Create DocPad Instance
	DocPad.createInstance {action}, (err,docpad) ->
		# Check
		return console.log(err.stack)  if err

		# Create Console Interface
		new ConsoleInterface {docpad}, (err,consoleInterface) ->
			# Check
			return console.log(err.stack)  if err

			# Start
			consoleInterface.start()

# ---------------------------------
# Fire
checkDocPad()
