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
		}
	};

	// Export
	module.exports = util;

})();
