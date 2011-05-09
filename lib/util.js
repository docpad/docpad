(function(){
	// Requireutilnts
	var
		fs = require("fs"),
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
		 * Recursively scan a directory
		 * @param {Path} parentPath
		 */
		scandir: function(parentPath,fileAction,dirAction,next,relativePath){
			// Prepare
			var
				completed = 0, total = 0, complete = function(){
					completed++;
					if ( completed === total ) {
						if ( next ) next();
					}
				};
			
			// Cycle
			fs.readdir(parentPath,function(err,files){
				// Error
				if ( err ) {
					console.log('Failed to read:',parentPath);
					throw err;
				}
				// Skip
				else if ( !files.length ) {
					if ( next ) next();
					return;
				}
				// Cycle
				else {
					files.forEach(function(file){
						// Increment
						++total;

						// Prepare
						var
							fileFullPath = parentPath+'/'+file,
							fileRelativePath = (relativePath ? relativePath+'/' : '')+file;
						
						// Stat
						fs.stat(fileFullPath,function(err,fileStat){
							// Error
							if ( err ) throw err;
							// Directory
							else if ( fileStat.isDirectory() ) {
								// Recurse
								util.scandir(fileFullPath,fileAction,dirAction,function(){
									// Dir Action
									if ( dirAction ) {
										dirAction(fileFullPath,fileRelativePath,complete);
									}
									else {
										complete();
									}
								},fileRelativePath);
							}
							// File
							else {
								// File Action
								if ( fileAction ) {
									fileAction(fileFullPath,fileRelativePath,complete);
								}
								else {
									complete();
								}
							}
						});
					});
				}
			});
		},

		/**
		 * Recursively copy a directory
		 * @param {Path} sourcePath
		 * @param {Path} targetPath
		 */
		cpdir: function(srcPath,outPath,next){
			util.scandir(
				// Path
				srcPath,
				// File Action
				function(fileSrcPath,fileRelativePath,next){
					var fileOutPath = outPath+'/'+fileRelativePath;
					util.ensurePath(path.dirname(fileOutPath),function(){
						util.cp(fileSrcPath,fileOutPath,function(err){
							if ( err ) throw err;
							else if ( next ) next();
						});
					});
				},
				// Dir Action
				false,
				// Next
				next
			);
		},

		/**
		 * Recursively remove a directory
		 * @param {Path} src
		 */
		rmdir: function(parentPath,next){
			path.exists(parentPath,function(exists){
				if ( !exists ) {
					if ( next ) next();
				}
				else {
					util.scandir(
						// Path
						parentPath,
						// File Action
						function(fileFullPath,fileRelativePath,next){
							fs.unlink(fileFullPath,function(err){
								if ( err ) throw err;
								else if ( next ) next();
							});
						},
						// Dir Action
						function(fileFullPath,fileRelativePath,next){
							fs.rmdir(fileFullPath,function(err){
								if ( err ) throw err;
								else if ( next ) next();
							});
						},
						// Next
						function(){
							fs.rmdir(parentPath,function(err){
								if ( err ) throw err;
								else if ( next ) next();
							});
						}
					);
				}
			});
		}

	};

	// Export
	module.exports = util;

})();
