#!/usr/bin/env coffee
<<<<<<< HEAD
require __dirname+'/../lib/docpad.coffee'
=======
docpad = require "#{__dirname}/../lib/docpad.coffee"
docpad.createInstance().action process.argv[2] || false
>>>>>>> docpad_balupton/v0.11
