// Requirements
var
	mongoose = require('mongoose'),
	util = require(__dirname+'/util.js'),
	fs = require('fs'),
	yaml = require('yaml'),
	es5 = require('es5-shim'),
	express = require('express'),
	gfm = require('github-flavored-markdown'),
	eco = require('eco'),
	path = require('path'),
	async = require('async'),
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
		this.LayoutSchema = new Schema({
			id: ObjectId,
			layout: String,
			fullPath: String,
			relativePath: String,
			relativeBase: String,
			body: String,
			content: String,
			date: String,
			title: String
		}),
		this.DocumentSchema = new Schema({
			id: ObjectId,
			layout: String,
			fullPath: String,
			relativePath: String,
			relativeBase: String,
			body: String,
			content: String,
			contentRendered: String,
			date: String,
			title: String
		});

		// Models
		mongoose.model('Layout',this.LayoutSchema);
		mongoose.model('Document',this.DocumentSchema);
		this.LayoutModel = mongoose.model('Layout'),
		this.DocumentModel = mongoose.model('Document'),

		// Generate
		this.generate(function(){
			console.log('Website Generated');
		});

		// Server
		var app = express.createServer();

		// Route Document
		app.get(/^(.*)/, DocPad.documentAction);

		// Listen
		app.listen(9778);
	},

	/**
	 * Clean the Database
	 */
	generateClean: function(next){
		async.parallel([
			function(callback){
				DocPad.LayoutModel.remove({},function(err){
					if ( err ) throw err;
					console.log('Cleaned Layouts');
					callback();
				});
			},
			function(callback){
				DocPad.DocumentModel.remove({},function(err){
					if ( err ) throw err;
					console.log('Cleaned Documents');
					callback();
				});
			}
		],
		function(){
			console.log('Cleaned Files');
			next();
		});
	},

	/**
	 * Parse the Files
	 */
	generateParse: function(next){
		// Prepare
		var
			layoutsSrcPath = this.options.srcPath+'/layouts',
			layoutsOutPath = this.options.outPath+'/layouts',
			docsSrcPath = this.options.srcPath+'/docs',
			docsOutPath = this.options.outPath+'/docs',
			publicSrcPath = this.options.srcPath+'/public',
			publicOutPath = this.options.outPath+'/public',
			parseFile = function(fileFullPath,fileRelativePath,next){
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
					}
					else {
						// Extract Parts
						fileBody = fileData;
					}

					// Markup
					fileMeta.extension = path.extname(fileFullPath);
					switch ( fileMeta.extension ) {
						case '.md':
							fileMeta.content = gfm.parse(fileBody);
							break;
						
						case '.html':
						default:
							fileMeta.content = fileBody;
							break;
					}

					// Update Meta
					fileMeta.fullPath = fileFullPath;
					fileMeta.relativePath = fileRelativePath;
					fileMeta.relativeBase = (path.dirname(fileRelativePath)+'/'+path.basename(fileRelativePath,path.extname(fileRelativePath))).replace(/\/+/g,'/');
					fileMeta.body = fileBody;
					fileMeta.title = fileMeta.title || path.basename(fileFullPath);
					fileMeta.date = fileMeta.data || '2010-01-01';

					// Store FileMeta
					next(fileMeta);
				});
			},
			parseFiles = function(fullPath,callback,next){
				// Queue
				var completed = 0, total = 1, complete = function(){
					++completed;
					if ( completed === total ) {
						next();
					}
				};

				// Wrapper
				_parseFiles = function(fullPath,relativePath,callback){
					// Read
					fs.readdir(fullPath,function(err, files){
						// Update
						total += files.length;
						complete();
						
						// Cycle
						files.forEach(function(file){
							// Prepare
							var
								fileFullPath = fullPath+'/'+file,
								fileRelativePath = relativePath+'/'+file,
								fileStat = fs.statSync(fileFullPath);

							// Handle
							if ( fileStat.isDirectory() ) {
								// Recurse
								_parseFiles(fileFullPath,fileRelativePath,callback);
							}
							else {
								// Parse File
								parseFile(fileFullPath,fileRelativePath,function(fileMeta){
									callback(fileMeta,function(){
										complete();
									});
								});
							}
						});
					});
				};

				// Start Parsing
				_parseFiles(fullPath,'',callback);
			};
		
		// Parse Files
		async.parallel([
			// Layouts
			function(callback){
				// Parse Layouts
				parseFiles(
					// Full Path
					layoutsSrcPath,
					// One Parsed
					function(fileMeta,next){
						// Prepare
						var Layout = new DocPad.LayoutModel(), key;

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
							next();
						});
					},
					// All Parsed
					function(){
						console.log('Parsed Layouts');
						callback();
					}
				);
			},
			// Documents
			function(callback){
				// Parse Documents
				parseFiles(
					// Full Path
					docsSrcPath,
					// One Parsed
					function(fileMeta,next){
						// Prepare
						var Document = new DocPad.DocumentModel(), key;

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
							next();
						});
					},
					// All Parsed
					function(){
						console.log('Parsed Documents');
						callback();
					}
				);
			}
		],
		function(err){
			if ( err ) throw err;
			console.log('Parsed Files');
			next();
		});
	},

	generateRender: function(next){
		// Prepare
		var
			_render = function(Document,templateData){
				return eco.render(Document.content,templateData);
			},
			_renderRecursive = function(content,child,templateData,next){
				// Handle Parent
				if ( child.layout ) {
					// Find Parent
					DocPad.LayoutModel.findOne({relativeBase:'/'+child.layout},function(err,parent){
						// Prepare
						if ( err ) { throw err; }
						else if ( !parent ) { throw new Error('Could not find the layout ['+child.layout+']'); }

						// Render Parent
						templateData.content = content;
						content = _render(parent,templateData);

						// Recurse
						_renderRecursive(content,parent,templateData,next);
					});
				}
				else {
					// Loner
					next(content);
				}
			},
			render = function(Document,templateData,next){
				// Render Original
				var renderedContent = _render(Document,templateData);

				// Wrap in Parents
				_renderRecursive(renderedContent,Document,templateData,function(contentRendered){
					Document.contentRendered = contentRendered;
					Document.save(function(err){
						if ( err ) throw err;
						next();
					});
				});
			},
			completed = 0, total = 0, complete = function(){
				completed++;
				if ( completed === total ) {
					console.log('Rendered Files');
					next();
				}
			};


		// Find Documents
		DocPad.DocumentModel.find({}, function (err, Documents) {
			if ( err ) throw err;
			// Render Documents
			Documents.forEach(function(Document){
				++total;
				render(
					Document,
					{
						Documents: Documents,
						DocumentModel: DocPad.DocumentModel,
						Document: Document
					},
					complete
				);
			});
		});
	},

	generateWrite: function(next){
		var
			completed = 0, total = 0, complete = function(){
				completed++;
				if ( completed === total ) {
					console.log('Rendered Files');
					next();
				}
			};

		// Find Documents
		DocPad.DocumentModel.find({}, function (err, Documents) {
			if ( err ) throw err;
			// Render Documents
			Documents.forEach(function(Document){
				++total;

				// Prepare
				var fileFullPath = DocPad.options.outPath+Document.relativePath;
				
				// Ensure Path
				util.ensurePath(path.dirname(fileFullPath),function(){
					// Write Document
					fs.writeFile(fileFullPath,Document.contentRendered,function(err){
						if ( err ) throw err;
						complete();
					});
				});
			});
		});
	},

	/**
	 * Generate the Static Website
	 * 1. Clean the Database
	 * 2. Parse the Source files
	 * 3. Render the Source Files
	 */
	generate: function(next){
		// Clean Database
		DocPad.generateClean(function(){
			DocPad.generateParse(function(){
				DocPad.generateRender(function(){
					DocPad.generateWrite(function(){
						next();
					})
				})
			})
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
