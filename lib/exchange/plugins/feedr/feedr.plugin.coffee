# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	balUtil = require('bal-util')
	request = require('request')
	_ = require('underscore')
	path = require('path')
	fs = require('fs')

	# Define Plugin
	class FeedrPlugin extends BasePlugin
		# Plugin Name
		name: 'feedr'

		# Render Before
		# Read the feeds here
		renderBefore: ({templateData}, next) ->
			# Prepare
			feedr = @
			feeds = @config.feeds or {}
			templateData.feeds = {}

			# Tasks
			tasks = new balUtil.Group (err) ->
				return next?(err)

			# Feeds
			_.each feeds, (feedData,feedName) ->
				tasks.push ->
					feedr.readFeed feedName, feedData, (err,body) ->
						return tasks.complete(err)  if err
						templateData.feeds[feedName] = body
						return tasks.complete(err)

			# Async
			tasks.async()

		# Read Feeds
		readFeed: (feedName,feedData,next) ->
			# Prepare
			feedData.path = "/tmp/docpad-feedr-#{feedName}"

			# Write the feed
			writeFeed = (body) ->
				# Store the parsed data in the cache somewhere
				fs.writeFile feedData.path, JSON.stringify(body), (err) ->
					# Check
					return next?(err)  if err

					# Return the parsed data
					return next?(null,body)

			# Get the file via reading the cached copy
			viaCache = ->
				# Check the the file exists
				path.exists feedData.path, (exists) ->
					# Check it exists
					return next?()  unless exists

					# It does exist, so let's continue to read the cached fie
					fs.readFile feedData.path, (err,data) ->
						# Check
						return next?(err)  if err

						# Parse the cached data
						body = JSON.parse data.toString()

						# Rreturn the parsed cached data
						return next?(null,body)

			# Get the file via doing a new request
			viaRequest = ->
				request feedData.url, (err,response,body) ->
					# If the request fails then we should revert to the cache
					return viaCache()  if err

					# Trim the requested data
					body = body.trim()

					# Parse the requested data
					if /^[\[\{]/.test(body)
						# json
						result = eval(body)
						writeFeed(result)
					else if /^</.test(body)
						# xml
						fs = require("fs")
						xml2js = require("xml2js")
						parser = new xml2js.Parser()
						parser.on 'end', (result) ->
							writeFeed(result)
						parser.parseString(body)
					else
						# jsonp
						body = body.replace(/^[a-z0-9]+/gi, '')
						eval('result = '+body)
						writeFeed(result)

			# Check if we should get the data from the cache or do a new request
			balUtil.isPathOlderThan feedData.path, 1000*60*5, (err,older) ->
				# Check
				return next?(err)  if err

				# The file doesn't exist, or exists and is old
				if older is null or older is true
					# Refresh
					viaRequest()
				# The file exists and relatively new
				else
					# Get from cache
					viaCache()

			# Chain
			@