# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"
path = require 'path'
fs = require 'fs'
sys = require 'sys'
url = require 'url'

# Define Plugin
class AliasPlugin extends DocpadPlugin
	# Plugin Name
	name: 'alias'
	aliases: {}

	# Plugin priority
	priority: 100

	constructor: ->
		@aliases = {}

	# Parsing all files has finished
	contextualizeFinished: ({docpad,logger,util},next) ->
		# Prepare
		documents = docpad.documents

		# Find documents
		that = @
		documents.find {}, (err, docs, length) ->
			docs.forEach (document) ->
        if document.aliases
          document.aliases.forEach (alias) ->
          	if document.url
              that.aliases[alias] = document.url.toLowerCase()
      next()

	# Insert your add-on configuration
	serverBeforeConfiguration: ({docpad,server},next) ->
    that = @
    docpad.server.all '/', (req,res,next) ->
      p = req.param 'p', null
      if p
        if that.aliases[req.url.toLowerCase()]
          res.redirect(that.aliases[req.url.toLowerCase()], 301)
          res.end()
        else
          next()
      else
        next()

	# Run when the server setup has finished
	serverFinished: ({docpad,server},next) ->
		that = @
		docpad.server.all /\/[a-z0-9\-]+\/?$/i, (req,res,next) =>
			if !req.url.toLowerCase().match('\/$')
        req.url = req.url + '/'
			if that.aliases[req.url.toLowerCase()]
        res.redirect(that.aliases[req.url.toLowerCase()], 301)
        res.end()
  		else
        next()

# Export
module.exports = AliasPlugin
