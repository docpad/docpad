docpad = require __dirname+'/lib/docpad.coffee'
docpad.createInstance().action process.argv[2] || false