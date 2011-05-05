(function(){

	// Requirements
	var
 	   fs = require("fs");

	/**
	 * Util
	 **/
	var util = {
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
			fs.stat(p,function(err,stats){
				if ( err ) {
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
			fs.stat(parentPath,function(err,stat){
				if ( err || !stat ) next();
				fs.readdir(parentPath,function(err,files){
					if ( err ) throw err;
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
