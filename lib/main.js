// Requirements
var
	fs = require("fs"),
	yaml = require('yaml'),
	es5 = require("es5-shim"),
	express = require('express'),
	gfm = require("github-flavored-markdown"),
	path = require('path'),
	mongoose = require('mongoose'),
	Schema = mongoose.Schema,
	ObjectId = Schema.ObjectId;

// DocPad
var DocPad = {
	/**
	 * Options
	 */
	options: {
		rootPath: null,
		outPath: 'out',
		srcPath: 'src',
		dsn: 'mongodb://localhost/docpad',
		markups: ['md','html'],
		templates: ['ejs']
	},

	/**
	 * Initialise Server
	 */
	init: function(){
		// Config
		this.options.rootPath = process.cwd();
		this.options.srcPath = this.options.rootPath+'/'+this.options.srcPath;
		this.options.outPath = this.options.rootPath+'/'+this.options.outPath;
		
		// Connect
		mongoose.connect(this.options.dsn);

		// Generate
		this.generate();

		return;

		// Server
		var app = express.createServer();

		// Route Document
		app.get(/^(.*)/, DocPad.documentAction);

		// Listen
		app.listen(3000);
	},

	generate: function(){
		// 1. Cycle through the layouts
		// 2. Cycle through the documents
		
		// Prepare
		var
			layoutsSrcPath = this.options.srcPath+'/layouts',
			layoutsOutPath = this.options.outPath+'/layouts',
			docsSrcPath = this.options.srcPath+'/docs',
			docsOutPath = this.options.outPath+'/docs',
			publicSrcPath = this.options.srcPath+'/public',
			publicOutPath = this.options.outPath+'/public',
			parseFile = function(filePath,callback){
				// Prepare
				var
					fileMeta = {},
					fileData = '',
					fileSplit = [],
					fileHead = '',
					fileBody = '';
				
				// Read the file
				fileData = fs.readFile(filePath,function(err,data){
					// Fetch
					if ( err ) throw err;
					fileData = data.toString();
					
					// Extract Yaml Header
					fileSplit = fileData.split(/---+/);
					if ( fileSplit.length === 3 && !fileSplit[0] ) {
						// Extract Parts
						fileHead = fileSplit[1];
						fileBody = fileSplit[2];
						fileMeta = yaml.eval(fileHead);
						// Parse File Head
					}
					else {
						// Extract Parts
						fileBody = fileData;
					}
					
					// Update Meta
					fileMeta.body = fileBody;

					// Store FileMeta
					callback(fileMeta);
				});
			},
			fetchLayouts = function(parentPath){
				// Prepare
				fs.readdirSync(parentPath).forEach(function(file,key){
					// Prepare
					var
						fileSrcPath = layoutsSrcPath+'/'+file,
						fileOutPath = layoutsOutPath+'/'+file,
						fileStat = fs.statSync(fileSrcPath);

					// Handle
					if ( fileStat.isDirectory() ) {
						// Recurse
						fetchLayouts(fileSrcPath);
					}
					else {
						// Parse File
						parseFile(fileSrcPath);
					}
				});
			},
			fetchDocs = function(parentPath){
			},
			layouts, docs;
		
		// Fetch Layouts and Docs
		layouts = fetchLayouts(layoutsSrcPath);
	},

	/**
	 * Send back a user homepage
	 */
	documentAction: function(req, res){
		// Prepare
		var
			user = req.params[0],
			file = req.params[1];
			requestPath = Hyde.options.rootPath+'/users/'+user+'/documents/'+file;

		// Check if the request path already exists
		if ( path.existsSync(requestPath) )	{
			return res.send(fs.readFileSync(requestPath).toString());
		}

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

DocPad.init();
