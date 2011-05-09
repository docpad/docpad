(function(){
	// Requirements
	var
 	   fs = require("fs")
		path = require('path');

	/**
	 * Util
	 **/
	var util = {
		/**
		 * Copy a file
		 * @param {Path} src
		 * @param {Path} dst
		 */
		cp: function(src,dst,next){
			fs.readFile(src,'binary',function(err,data){
				if ( err ) throw err;
				fs.writeFile(dst,data,'binary',function(err){
					if ( err ) throw err;
					if ( next ) next();
				});
			});
		},


		/**
		 * Recursively copy a directory
		 * @param {Path} sourcePath
		 * @param {Path} targetPath
		 */
		cpdir: function(sourcePath,targetPath,remove,next){
			// Prepare
			var
				me = this,
				completed = 0, total = 0, complete = function(){
					completed++;
					if ( completed === total ) {
						if ( next ) next();
					}
				},
				_mkdir = function(){
					fs.mkdir(targetPath,0700,_readdir);
				},
				_readdir = function(){
					fs.readdirSync(sourcePath).forEach(function(file){
						++total;

						// Prepare
						var
							sourceFilePath = sourcePath+'/'+file,
							targetFilePath = targetPath+'/'+file,
							sourceFileStat = fs.statSync(sourceFilePath);

						// Handle
						if ( sourceFileStat.isDirectory() ) {
							// Recurse
							me.cpdir(sourceFilePath,targetFilePath,false,complete);
						}
						else {
							// Copy
							me.cp(sourceFilePath,targetFilePath,complete);
						}
					});
				};
			
			// Handle
			remove = remove || false;

			// Check
			path.exists(targetPath,function(exists){
				if ( !exists ) {
					_mkdir();
				}
				else {
					if ( remove ) {
						me.rmdir(targetPath,function(){
							_mkdir();
						});
					}
					else {
						_readdir();
					}
				}
			});

			// Done
			return true;
		},

		/**
		 * Get the parent path
		 * @param {Path} p
		 * @return {Path} parentPath
		 */
		getParentPathSync: function(p){
			var parentPath = p.replace(/[\/\\][^\/\\]+$/,'');
			return parentPath;
		},

		/**
		 * Ensure Path Exists
		 * @param {Path} p
		 */
		ensurePath: function(p,next){
			p = p.replace(/[\/\\]$/,'');
			path.exists(p,function(exists){
				if ( !exists ) {
					var parentPath = util.getParentPathSync(p);
					util.ensurePath(parentPath,function(){
						fs.mkdir(p,0700,function(err){
							next();
						});
					});
				}
				else {
					next();
				}
			});
		},

		/**
		 * Recursively remove a directory
		 * @param {Path} src
		 */
		rmdir: function(parentPath,next){
			// Prepare
			var
				completed = 0, total = 0, complete = function(){
					completed++;
					if ( completed === total ) {
						fs.rmdir(parentPath,function(err){
							if ( err ) throw err;
							next();
						});
					}
				};

			// Check
			path.exists(parentPath,function(exists){
				if ( !exists ) {
					next();
					return;
				}
				fs.readdir(parentPath,function(err,files){
					if ( err ) {
						console.log('Failed to read: '+parentPath);
						throw err;
					}
					files.forEach(function(file){
						++total;
						
						// Prepare
						var filePath = parentPath+'/'+file;
						
						// Stat
						fs.stat(filePath,function(err,stat){
							if ( err ) throw err;
							// Handle
							if ( stat.isDirectory() ) {
								// Recurse
								util.rmdir(filePath,function(err){
									if ( err ) throw err;
									complete();
								});
							}
							else {
								// Delete
								fs.unlink(filePath,function(err){
									if ( err ) throw err;
									complete();
								});
							}
						});
					});
				});
			});
		}

	};

	// Export
	module.exports = util;

})();
