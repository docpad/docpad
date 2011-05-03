// Requirements
var
	mongoose = require('mongoose'),
	fs = require("fs"),
	yaml = require('yaml'),
	es5 = require("es5-shim"),
	express = require('express'),
	gfm = require("github-flavored-markdown"),
	path = require('path'),
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
		
		// Schemas
		var
			LayoutSchema = new Schema({
				id: ObjectId,
				path: String,
				body: String
			}),
			DocumentSchema = new Schema({
				id: ObjectId,
				path: String,
				body: String
			});

		// Models
		mongoose.model('Layout',LayoutSchema);
		mongoose.model('Document',DocumentSchema);

		// Generate
		this.generate();

		// Server
		var app = express.createServer();

		// Route Document
		app.get(/^(.*)/, DocPad.documentAction);

		// Listen
		app.listen(9778);
	},

	generate: function(){
		// 1. Cycle through the layouts
		// 2. Cycle through the documents
		
		// Prepare
		var
			LayoutModel = mongoose.model('Layout'),
			DocumentModel = mongoose.model('Document'),
			layoutsSrcPath = this.options.srcPath+'/layouts',
			layoutsOutPath = this.options.outPath+'/layouts',
			docsSrcPath = this.options.srcPath+'/docs',
			docsOutPath = this.options.outPath+'/docs',
			publicSrcPath = this.options.srcPath+'/public',
			publicOutPath = this.options.outPath+'/public',
			layoutModel = mongoose.model('Layout'),
			DocumentModel = mongoose.model('Document'),
			parseFile = function(fileFullPath,fileRelativePath,callback){
				// Prepare
				var
					fileMeta = {},
					fileData = '',
					fileSplit = [],
					fileHead = '',
					fileBody = '';
				
				// Read the file
				fileData = fs.readFile(fileFullPath,function(err,data){
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
					fileMeta.fullPath = fileFullPath;
					fileMeta.relativePath = fileRelativePath;
					fileMeta.body = fileBody;

					// Store FileMeta
					callback(fileMeta);
				});
			},
			parseFiles = function(fullPath,relativePath,callback){
				// Prepare
				fs.readdirSync(fullPath).forEach(function(file,key){
					// Prepare
					var
						fileFullPath = fullPath+'/'+file,
						fileRelativePath = relativePath+'/'+file,
						fileStat = fs.statSync(fileFullPath);

					// Handle
					if ( fileStat.isDirectory() ) {
						// Recurse
						parseFiles(fileFullPath,fileRelativePath,callback);
					}
					else {
						// Parse File
						parseFile(fileFullPath,fileRelativePath,callback);
					}
				});
			};
		
		// Clean Database
		LayoutModel.remove({},function(err){
			if ( err ) throw err;
		});
		DocumentModel.remove({},function(err){
			if ( err ) throw err;
		});
		
		// Parse Layouts
		parseFiles(layoutsSrcPath,'',function(fileMeta){
			// Prepare
			var Layout = new LayoutModel(), key;

			// Apply
			for ( key in fileMeta ) {
				if ( fileMeta.hasOwnProperty(key) ) {
					Layout[key] = fileMeta[key];
				}
			}

			// Save
			Layout.save(function(err){
				if ( err ) throw err;
				console.log('Parsed Layout:',Layout.relativePath);
			});
		});

		// Parse Documents
		parseFiles(docsSrcPath,'',function(fileMeta){
			// Prepare
			var Document = new DocumentModel(), key;

			// Apply
			for ( key in fileMeta ) {
				if ( fileMeta.hasOwnProperty(key) ) {
					Document[key] = fileMeta[key];
				}
			}

			// Save
			Document.save(function(err){
				if ( err ) throw err;
				console.log('Parsed Document:',Document.relativePath);
			});
		});
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
