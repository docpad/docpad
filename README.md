# DocPad: It's Like Jekyll.

DocPad (like Jekyll) is a static website generator, unlike Jekyll it is written in Node.js and allows the templating engine access to the documents. This means you have the unlimited power of a CMS while having the simplicity of a notepad.

## Huh?

1. Say if you create the following directory structure:

	- myWebsite
		- src
			- docs
			- layouts
			- public

2. And you create the following files:

	- A layout at `src/layouts/default.html`, which contains
		
		``` html
		<html>
			<head><title><%=Document.title%></title></head>
			<body>
				<%-content%>
			</body>
		</html>
		```

	- And a layout at `src/layouts/post.html`, which contains:

		``` html
		---
		layout: default
		---
		<h1><%=Document.title%></h1>
		<div><%-content%></div>
		```

	- And a document at `src/docs/posts/hello.md`, which contains:

		``` html
		---
		layout: post
		title: Hello World!
		---
		Hello **World!**
		```

3. Then when you generate your website a html file will be created at `out/posts/hello.html`, which contains:

	``` html
	<html>
		<head><title>Hello World!</title></head>
		<body>
			<h1>Hello World!</h1>
			<div>Hello <strong>World!</strong></div>
		</body>
	</html>
	```

4. And any files that you have in `src/public` will be copied to the `out` directory. E.g. `src/public/styles/style.css' -> `out/styles/style.css`

5. Allowing you to really easily generate a website which only changes when the documents change (which when you think about it, is really all you need for the majority of websites)

6. Cool, now what was with the `<%=...%>` and `<%-...%>` parts which were substituted away?

	- This is possible because we parse all the documents and layouts through a template rendering engine. The template rendering engine we use is [Eco](https://github.com/sstephenson/eco) which allows you to do some pretty nifty things. In fact we can display the titles and links to all posts with the following html:

			<% for Document in @Documents: %>
				<% if Document.url.indexOf('/posts') == 0: %>
					<a href="<%= Document.url %>"><%= Document.title %></a><br/>
				<% end %>
			<% end %>

6. Cool that makes sense... now how did `Hello **World!**` in our document get converted into `Hello <strong>World!</strong>`?

	- That was possible that file was a [Markdown](http://daringfireball.net/projects/markdown/basics) file (i.e. it had the `.md` extension). Markdown is a great markup language as with it you have an extremely simple and readable document which generates a rich semantic HTML document. DocPad also supports a series of other markup languages as explain later on in this readme.


## Install

SWEET! I want to USE IT! Let's do it!

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


## Using

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



## Built Upon

* [Node.js](http://nodejs.org) - Server Side Javascript
* [Express.js](http://expressjs.com/) - The "Server" in Server Side Javascript
* [Mongoose](https://github.com/learnboost/mongoose/) - MongoDB Made Easy
* [Async](https://github.com/caolan/async) - Asynchrounous Programming Made Easy

### Markup Languges

* [Markdown](http://daringfireball.net/projects/markdown/basics) - Markup Made Easy
* [Jade](https://github.com/visionmedia/jade) - HTML Made Easy

### Template Engines

* [Eco](https://github.com/sstephenson/eco) - Templating Made Easy


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

- v0.5 May 9, 2011
	- Pretty big clean

- v0.4 May 9, 2011
	- The CLI is now working as documented

- v0.3 May 7, 2011
	- Got the generation and server going

- v0.2 March 24, 2011
	- Prototyping with DisenchantCH

- v0.1 March 16, 2011
	- Initial Commit with Bergie


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)