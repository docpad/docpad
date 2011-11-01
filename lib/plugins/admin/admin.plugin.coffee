# Requires
DocpadPlugin = require "#{__dirname}/../../plugin.coffee"

# Define Plugin
class AdminPlugin extends DocpadPlugin
	# Plugin Name
	name: 'admin'

# Export Plugin
module.exports = AdminPlugin