# DocPad: It's Like Jekyll.

DocPad (like Jekyll) is a static website generator, unlike Jekyll it's written in CoffeeScript+Node.js instead of Ruby, and also allows the template engine complete access to the document model. This means you have unlimited power as a CMS and the simplicity of a notepad.


## Huh?

1. Say you were to create the following website structure:

	> - myWebsite
		- src
			- documents
			- files
			- layouts

2. And you were to create the following files:

	- A layout at `src/layouts/default.html`, which contains
		
		``` html
		<html>
			<head><title><%=@Document.title%></title></head>
			<body>
				<%-@content%>
			</body>
		</html>
		```

	- And a layout at `src/layouts/post.html`, which contains:

		``` html
		---
		layout: default
		---
		<h1><%=@Document.title%></h1>
		<div><%-@content%></div>
		```

	- And a document at `src/documents/posts/hello.md`, which contains:

		``` html
		---
		layout: post
		title: Hello World!
		---
		Hello **World!**
		```

3. Then when you generate your website with docpad you will get a html file at `out/posts/hello.html`, which contains:

	``` html
	<html>
		<head><title>Hello World!</title></head>
		<body>
			<h1>Hello World!</h1>
			<div>Hello <strong>World!</strong></div>
		</body>
	</html>
	```

4. And any files that you have in `src/files` will be copied to the `out` directory. E.g. `src/files/styles/style.css` -> `out/styles/style.css`

5. Allowing you to easily generate a website which only changes (and automatically updates) when a document changes (which when you think about it; is the majority of websites)

6. Cool, now what was with the `<%=...%>` and `<%-...%>` parts which were substituted away?

	- This is possible because we parse the documents and layouts through a template rendering engine. The template rendering engine we use is [Eco](https://github.com/sstephenson/eco) which allows you to do some pretty nifty things. In fact we can display the all titles and links of our posts with the following html:
		
		``` html
		<% for Document in @Documents: %>
			<% if Document.url.indexOf('/posts') is 0: %>
				<a href="<%= Document.url %>"><%= Document.title %></a><br/>
			<% end %>
		<% end %>
		```

6. Cool that makes sense... now how did `Hello **World!**` in our document get converted into `Hello <strong>World!</strong>`?

	- That was possible as that file was a [Markdown](http://daringfireball.net/projects/markdown/basics) file (i.e. it had the `.md` extension). Markdown is a great markup language as with it you have an extremely simple and readable document which generates a rich semantic HTML document. DocPad also supports a series of other markup languages which are listed later on.


## Installing

1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

1. Install CoffeeScript
		
		npm -g install coffee-script

1. Install DocPad

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

- To run the docpad server which allows you to access the generated website in a web browser

		docpad server


## Created With

### General

* [Node.js](http://nodejs.org) - Server Side Javascript
* [Express.js](http://expressjs.com) - The "Server" in Server Side Javascript
* [Query-Engine](https://github.com/balupton/query-engine.npm) - The MongoDB Query-Engine without the Database
* [CoffeeScript](http://jashkenas.github.com/coffee-script) - JavaScript Made Easy
* [Async](https://github.com/caolan/async) - Asynchrounous Programming Made Easy

### Markup Languges

* [Markdown](http://daringfireball.net/projects/markdown/basics) - Markup Made Easy
* [Jade](https://github.com/visionmedia/jade) - HTML Made Easy

### Template Engines

* [Eco](https://github.com/sstephenson/eco) - Templating Made Easy


## Learning

[To learn more about DocPad (including using and extending it) visit its wiki here](https://github.com/balupton/docpad/wiki)


## History

- v0.9 July 6, 2011
	- No longer uses MongoDB/Mongoose! We now use [Query-Engine](https://github.com/balupton/query-engine.npm) which doesn't need any database server :)

- v0.8 May 23, 2011
	- Now supports mutliple skeletons
	- Structure changes

- v0.7 May 20, 2011
	- Now supports multiple docpad instances
	
- v0.6 May 12, 2011
	- Moved to CoffeeScript
	- Removed highlight.js (should be a plugin or client-side feature)

- v0.5 May 9, 2011
	- Pretty big clean

- v0.4 May 9, 2011
	- The CLI is now working as documented

- v0.3 May 7, 2011
	- Got the generation and server going

- v0.2 March 24, 2011
	- Prototyping with [disenchant](https://github.com/disenchant)

- v0.1 March 16, 2011
	- Initial commit with [bergie](https://github.com/bergie)


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)