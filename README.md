# DocPad: It's Jekyll... but in Node.js


## Huh?

DocPad (like Jekyll) renders static markup documents into rich static documents. In other words:

- Before:

	- myDocPadWebsite/src
		- docs
			- posts
				- 2010-12-25 - Merry Christmas.md
			- index.md
		- layouts
			- post.md
			- default.md
		- public
			- style.css
			- someImage.png
			- someBook.pdf

- After:

	- myDocPadWebsite/out
		- site
			- index.html
			- posts
				- 2010-12-25 - Merry Christmas.html
			- public
				- syle.css
				- someImage.png
				- someBook.pdf


## Uses

* [Node.js](http://nodejs.org) - Server Side Javascript
* [Express.js](http://expressjs.com/) - The "Server" in Server Side Javascript
* [Markdown](http://daringfireball.net/projects/markdown/basics) - Markup Made Easy
* [Jade](https://github.com/visionmedia/jade) - HTML Made Easy
* [Eco](https://github.com/sstephenson/eco) - Templating Made Easy
* [Mongoose](https://github.com/learnboost/mongoose/) - MongoDB Made Easy
* [Async](https://github.com/caolan/async) - Asynchrounous Programming Made Easy


## Install

1. Install Node.js

	- On OSX
		
		1. [Install Git](http://git-scm.com/download)

		2. [Install Xcode](http://itunes.apple.com/us/app/xcode/id422352214?mt=12&ls=1)

		3. Run the following in terminal
			
				sudo chown -R $USER /usr/local
				git clone https://github.com/joyent/node.git && cd node && git checkout v0.4.7 && ./configure && make && sudo make install && cd .. && rm -Rf node
				curl http://npmjs.org/install.sh | sh
		
	- On Apt Linux (e.g. Ubuntu)

			sudo chown -R $USER /usr/local
			sudo apt-get update && sudo apt-get install curl build-essential openssl libssl-dev git
			git clone https://github.com/joyent/node.git && cd node && git checkout v0.4.7 && ./configure && make && sudo make install && cd .. && rm -Rf node
			curl http://npmjs.org/install.sh | sh
	
	- On Yum Linux (e.g. Fedora)
			
			sudo chown -R $USER /usr/local
			sudo yum -y install tcsh scons gcc-c++ glibc-devel openssl-devel git
			git clone https://github.com/joyent/node.git && cd node && git checkout v0.4.7 && ./configure && make && sudo make install && cd .. && rm -Rf node
			curl http://npmjs.org/install.sh | sh

	- On Windows

		Node.js is not currently available for direct stable use on Windows; the following instructions will run you through setting up a Ubuntu (Apt Linux) Virtual Machine allowing you to run Node.js stably (albeit indirectly) on Windows.

		1. [Download Ubuntu Disk Image](http://d235whtva55mz9.cloudfront.net/ubuntu-11.04-desktop-i386.iso)

		2. [Download & Install VMWare Player](http://www.vmware.com/products/player/overview.html)

		3. Open VMWare Player and Create/Install a Virtual Machine using the Ubuntu Disk Image as the Install Media

		4. With the new Ubuntu Virtual Machine, follow the Apt Linux instructions.

2. [Install MongoDB](http://www.mongodb.org/downloads#packages)

3. Install DocPad

		npm -g install docpad


## Usage

- To generate the rendered website, watch the files for changes, and run the docpad server
	
		docpad

- To generate a basic website structure in the current working directory

		docpad skeleton

- To regenerate the rendered website

		docpad generate

- To regenerate the rendered website automatically whenever we make a change to a file

		docpad watch

- To run the docpad server which will watch the files and provide a mangement interface for working with the file

		docpad server


## Features

### Generation

* Support layouts
* Support meta-data
* Support css (e.g. less and css)
* Support tempalting languages (e.g. eco)
* Support markup lanagues (e.g. markdown and jade)
* Support generation of a static website
* Support generation of PDF documents (not yet done)

### Server

* Serve the generated static website
* Support dynamic pages which won't be generated statically (not yet done)
* Add NowPad support for interface (not yet done)
* Add user management (not yet done)
* Add revision history (not yet done)
* Add deployment options (not yet done)


## History

- v0.3 May 7, 2011
	- Got the generation and server going

- v0.2 March 24, 2011
	- Prototyping with DisenchantCH

- v0.1 March 16, 2011
	- Initial Commit with Bergie


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)