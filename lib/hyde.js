// Requirements
var
	express = require('express'),
	gfm = require("github-flavored-markdown"),
	fs = require('fs'),
	path = require('path'),
	dep = require(__dirname+'/dep.js');

// Hyde
var Hyde = {

	/**
	 * Options
	 */
	options: {
		rootPath: '.',
		format: ['md','html']
	},

	/**
	 * Initialise Server
	 */
	init: function(){
		// Config
		Hyde.options.rootPath = fs.realpathSync(Hyde.options.rootPath);

		// Server
		var app = express.createServer();

		// Route Homepage
		app.get('/', function(req, res){
			res.send('Signup Page');
		});

		// Route Users
		app.get('/user/:id', Hyde.userAction);

		// Route Document
		app.get(/^\/user\/([^\/]+)\/(.+)/, Hyde.documentAction);

		// Listen
		app.listen(3000);
	},

	/**
	 * Send back a user homepage
	 */
	userAction: function(req, res){
		res.send('user ' + req.params.id);
	},

	/**
	 * Send back a user homepage
	 */
	documentAction: function(req, res){
		// Prepare
		var
			user = req.params[0],
			file = req.params[1];
			requestPath = Hyde.options.rootPath+'/_users/'+user+'/_documents/'+file;

		// Get supported extension
		var filePath = Hyde.getSupportedFile(requestPath);

		// Check if the supported file exists
		if ( !filePath ) {
			console.log('missing: ['+filePath+'] ['+requestPath+']');
			return Hyde.missingAction(req,res);
		}

		// Return the rendered supported file
		var fileResult = Hyde.renderSupportedFile(filePath);

		// Wrap it in the template
		res.send(fileResult);
		//var path = './_users/'+res.params.id+'/'+res.params[1];
	},

	/**
	 * Send back a 404 page
	 */
	missingAction: function(req,res) {
		res.send(req.params);
	},

	/**
	 * Render the Supported File
	 */
	renderSupportedFile: function(filePath){
		// Prepare
		var
			extension = path.extname(filePath),
			result = false;

		// Render
		switch ( extension ) {
			case '.md':
				result = gfm.parse(fs.readFileSync(filePath).toString());
				break;

			case '.html':
				result = fs.readFileSync(filePath).toString();
				break;

			default:
				break;
		}

		// Return
		return result;
	},

	/**
	 * Get Support File
	 */
	getSupportedFile: function(filePath){
		// Prepare
		var result = false;

		// Handle
		Hyde.options.format.each(function(key,value){
			var fullPath = filePath+'.'+value;
			if ( path.existsSync(fullPath) ) {
				result = fullPath;
				return false;
			}
		});

		// Return
		return result;
	}
};

Hyde.init();
