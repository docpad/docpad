var Hyde = {

	/**
	 * Initialise Server
	 */
	init: function(){

		var app = express.createServer();

		app.get('/', function(req, res){
				res.send('Hello World');
		});

		app.listen(3000);

	}

};
