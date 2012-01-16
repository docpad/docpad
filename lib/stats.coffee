###
The Stats Tracker for DocPad
Not currently in use, and will undergo further refinements before it is put in use
###

# =====================================
# Requires

# Necessary
util = require 'bal-util'
EventSystem = util.EventSystem

# Local
require "#{__dirname}/prototypes.coffee"


# =====================================
# Stats package

class Stats
	# Variables
	docpad: null
	queue: []
	userConfig: null
	algorithm: 'sha256'

	# Setup our stats tracker
	constructor: ({docpad}) ->
		# Destroy references
		@userConfig = {}

		# Prepare
		@docpad = docpad
		@userConfig = docpad.userConfig
		stats = @

		# Start listening
		@listen()

		# Start loading
		stats.start 'loading', (err) ->
			# Error
			throw err  if err

			# Async
			tasks = new util.Group (err) ->
				# Error
				throw err  if err
				# Finish loading
				stats.finish 'loading'
			tasks.total = 2
		
			# Fetch the user's email
			exec 'git config --get user.email', {}, (err, email) ->
				user.email = (email or '').trim() or null
				tasks.complete(err)
			
			# Fetch the user's github username
			exec 'git config --get github.user', {}, (err, username) ->
				user.username = (username or '').trim() or null
				tasks.complete(err)
	

	loadUserConfig: (next) ->
		"~/.docpad.json"

	# ---------------------------------
	# Events

	listen: ->
		# Prepare
		docpad = @docpad

		# Generated finished
		#docpad.on 'error', (err) ->
		#	@log 'error', err