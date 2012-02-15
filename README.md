# DocPad. Intuitive web development.

<a href="http://flattr.com/thing/344188/balupton-on-Flattr" target="_blank">
<img src="http://api.flattr.com/button/flattr-badge-large.png" alt="Flattr this project" title="Flattr this project" border="0" /></a>

Initially web development was pretty easy, you just wrote a bunch of files and you got your website. These days, it's a lot more complicated than that. Things like databases, synchronisation, legacy frameworks and languages all slow the entire process down into a painful crawl. _It doesn't have to be like that._

DocPad takes that good ol' simple approach of writing files and wraps it with the best modern innovations, providing an awesome intuitive, liberating and empowering solution for HTML5 web design & development.


## What the features of DocPad?

- it is language agnostic, allowing you to write your documents in any language you wish, we already support over 10 languages (listed a few sections later)
- can mix and match renderers, allowing you to combine languages e.g. eco and markdown with `file.html.md.eco`
- supports static and dynamic documents
	- for static documents a static output file will be generated
	- for dynamic documents they will be re-rendered on each request
- provides a liquid layout engine allowing you to wrap a document in an infinite amount of layouts
- provides a in-memory nosql database which you can query inside your documents or inside your app
- can be used as a module inside a bigger application, allowing you to utilise DocPad's generation abilities but do the heavy lifting in your own application
- runs great on linux, osx, and windows, as well as node 0.4 and 0.6
- automatic version checking so you know when it's time to update
- provides an amazingly easy and simple, but yet powerful plugin infrastructure
- provides skeletons which can bootstrap your next DocPad project


## When would using DocPad be ideal?

- for prototyping new interfaces which need to accommodate rapid change
	- The ability to get up and running as quickly as possible with DocPad really helps here, along with it's support for pre-precessors and static site generation you can quickly move about your codebase and regig things when things need to change - without having to rewrite any architecture.

- for frontend prototypes which will be handed over to the backend developers for implementation
	- Often to gain layouts, templating, and pre-precessor support we'll have to implement a web framework, a templating engine, and code a custom build script for each of our pre-precessors that we use. This takes a lot of uncessary time, and complicates things during handover to the backend developers who then need to learn the tools that you've used. Using DocPad we abstract all that difficulty and handle it beautifully, allowing you to just focus on the files you want to write, and we'll provide you with the layout engine, templating engine, and pre-precessor support you need. When it comes to handover, the backend developers will have your source files, as well as the compiled files allowing them to use whichever is easiest for them.

- for simple websites like blogs, launch pages, etc
	- DocPad's static site generation abilities are great for this, and with DocPad's built-in support for dynamic documents we can also cater for the odd search page, enquiry form or twitter steam

- for thick client-side web applications
	- Combining DocPad's pre-precessor support and static site generation is amazing for developing thick client applications, as you can utilise the latest pre-precessors at any time, allowing you to focus on the problem, instead of how to implement the problem



## How does it work?

1. Say you were to create the following website structure:

	> - myWebsite
		- src
			- documents
			- layouts
			- public

1. And you were to create the following files:

	- A layout at `src/layouts/default.html.eco`, which contains
		
		``` html
		<html>
			<head><title><%=@document.title%></title></head>
			<body>
				<%-@content%>
			</body>
		</html>
		```

	- And another layout at `src/layouts/post.html.eco`, which contains:

		``` html
		---
		layout: default
		---
		<h1><%=@document.title%></h1>
		<div><%-@content%></div>
		```

	- And a document at `src/documents/posts/hello.html.md`, which contains:

		``` html
		---
		layout: post
		title: Hello World!
		---
		Hello **World!**
		```

1. Then when you generate your website with DocPad you will get a html file at `out/posts/hello.html`, which contains:

	``` html
	<html>
		<head><title>Hello World!</title></head>
		<body>
			<h1>Hello World!</h1>
			<div>Hello <strong>World!</strong></div>
		</body>
	</html>
	```

1. And any files that you have in `src/public` will be copied to the `out` directory. E.g. `src/public/styles/style.css` -> `out/styles/style.css`

1. Allowing you to easily generate a website which only changes (and automatically updates) when a document changes (which when you think about it; is the majority of websites)

1. Cool, now what was with the `<%=...%>` and `<%-...%>` parts which were substituted away?

	- This is possible because we parse the documents and layouts through a template rendering engine. The template rendering engine used in this example was [Eco](https://github.com/sstephenson/eco) (hence the `.eco` extensions of the layouts). Templating engines allows you to do some pretty nifty things, in fact we could display all the titles and links of our posts with the following:
		
		``` html
		<% for document in @documents: %>
			<% if document.url.indexOf('/posts') is 0: %>
				<a href="<%= document.url %>"><%= document.title %></a><br/>
			<% end %>
		<% end %>
		```

1. Cool that makes sense... now how did `Hello **World!**` in our document get converted into `Hello <strong>World!</strong>`?

	- That was possible as that file was a [Markdown](http://daringfireball.net/projects/markdown/basics) file (hence the `.md` extension it had). Markdown is fantastic for working with text based documents, as it really allows you to focus in on your content instead of the syntax for formatting the document!



## Supports

### Markups

- [Markdown](http://daringfireball.net/projects/markdown/basics) to HTML `.html.md|markdown`
- [Eco](https://github.com/sstephenson/eco) to anything `.anything.eco`
- [CoffeeKup](http://coffeekup.org/) to anything `.anything.ck|coffeekup|coffee` and HTML to CoffeeKup `.ck|coffeekup|coffee.html`
- [Jade](http://jade-lang.com/) to anything `.anything.jade` and HTML to Jade `.jade.html`
- [HAML](http://haml-lang.com/) to anything `.anything.haml`
- [Ruby](http://www.ruby-lang.org/) to anything `.anything.rb|ruby`
- [ERuby](http://en.wikipedia.org/wiki/ERuby) to anything `.anything.erb`
- [PHP](http://php.net/) to anything `.anything.php`

### Styles

- [Stylus](http://learnboost.github.com/stylus/) to CSS `.css.styl|stylus`
- [LessCSS](http://lesscss.org/) to CSS `.css.less`
- [SASS](http://sass-lang.com/) to CSS `.css.sass|scss`

### Scripts

- [CoffeeScript](http://coffeescript.org/) to JavaScript `.js.coffee` and JavaScript to CoffeeScript `.coffee.js`
- [Roy](http://roy.brianmckenna.org/) to JavaScript `.js.roy`
- [Move](http://movelang.org/) to JavaScript `.js.move`

### Parsers

- [YAML](https://github.com/visionmedia/js-yaml) with `--- yaml` (default)
- [CoffeeScript](http://jashkenas.github.com/coffee-script/) with `--- coffee`



## About

DocPad is doing great these days. You can check out [a bunch of websites already using it here](https://github.com/bevry/docpad/wiki/Showcase), and [discover the awesomely handsome crew behind the community here](https://github.com/bevry/docpad/wiki/Users). Ocassionally we also hold [events and competitions](https://github.com/bevry/docpad/wiki/Events) where you can learn more about DocPad, hack with others together, and win some cool stuff! Nifty.

On that note, DocPad is awesomely extensible. You can [download other people's plugins](https://github.com/bevry/docpad/wiki/Extensions) and use them in real quick, or even [write your own in matters of minutes.](https://github.com/bevry/docpad/wiki/Extending)

[Best yet, definitely check out the entire wiki, as this has just been a small taste of it's awesomeness, and there is plenty awesomness left to be discovered.](https://github.com/bevry/docpad/wiki)

Thanks. DocPad loves you!!!



## Installing

1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

1. Install dependencies
		
		npm install -g coffee-script

1. Install DocPad

		npm install -g docpad

1. _or... [install the cutting edge version](https://github.com/bevry/docpad/wiki/Testing)_

1. If you also want growl notifications (OSX), then install [the growl command line tool here](http://growl.cachefly.net/GrowlNotify-1.3.zip)

_Getting errors? [Try troubleshooting](https://github.com/bevry/docpad/wiki/Troubleshooting)_



## Using

- Firstly, make a directory for your new website and cd into it

	``` bash
	mkdir my-new-website
	cd my-new-website
	```

- To get started, simply run the following - it will run all the other commands at once
	
	``` bash
	docpad run
	```

- To generate a basic website structure in the current working directory if we don't already have one

	``` bash
	docpad scaffold
	```

- To regenerate the rendered website

	``` bash
	docpad generate
	```

- To regenerate the rendered website automatically whenever we make a change to a file

	``` bash
	docpad watch
	```

- To run the DocPad server which allows you to access the generated website in a web browser

	``` bash
	docpad server
	```

- To render an individual file with DocPad programatically (will output to stdout)

	``` bash
	docpad render filePath
	```

	E.g. To render a markdown file and save the result to an output file, we would use:
	
	``` bash
	docpad render inputMarkdownFile.html.md > outputMarkdownFile.html
	```

- To render stdin with DocPad programatically (will output to stdout)

	``` bash
	echo $content | docpad render sampleFileNameWithExtensions
	```

	E.g. To render passed markdown content and save the result to a file, we would use:
	
	``` bash
	echo "**awesome**" | docpad render input.html.md > output.html
	```


_Getting errors? [Try troubleshooting](https://github.com/bevry/docpad/wiki/Troubleshooting)_



## Thanks

DocPad wouldn't be possible if it wasn't for the following libaries _(in alphabetical order)_

- [Alexis Sellier's](https://github.com/cloudhead) [Less.js](https://github.com/cloudhead/less.js) - Leaner CSS

- [Benjamin Lupton's](https://github.com/balupton) [Bal-Util](https://github.com/balupton/bal-util.npm) - Node.js made easy
- [Benjamin Lupton's](https://github.com/balupton) [Caterpillar](https://github.com/balupton/caterpillar.npm) - Logging made easy
- [Benjamin Lupton's](https://github.com/balupton) [Query-Engine](https://github.com/balupton/query-engine.npm) - The MongoDB Query-Engine without the Database
- [Benjamin Lupton's](https://github.com/balupton) [Watchr](https://github.com/balupton/watchr) - Node.js recursive directory watching made easy
- [Brandon Bloom's](https://github.com/brandonbloom) [Html2CoffeeKup](https://github.com/brandonbloom/html2coffeekup) - HTML to CoffeeKup Converter
- [Brian McKenna's](http://brianmckenna.org/) [Roy](https://bitbucket.org/puffnfresh/roy) - JavaScript melded with static language features

- [Don Park's](https://github.com/donpark) [Html2Jade](https://github.com/donpark/html2jade) - HTML to Jade Converter

- [Isaac Z. Schlueter's](https://github.com/isaacs) [Github-Flavored-Markdown](https://github.com/isaacs/github-flavored-markdown) - Github's flavor of markdown
- [Isaac Z. Schlueter's](https://github.com/isaacs) [NPM](https://github.com/isaacs/npm) - The node package manager

- [Jeremy Ashkenas'](https://github.com/jashkenas) [CoffeeScript](http://jashkenas.github.com/coffee-script) - JavaScript made easy
- [Jeremy Ashkenas/DocumentCloud's](https://github.com/documentcloud/underscore) [Underscore](https://github.com/documentcloud/underscore) - The utility-belt library for JavaScript

- [Maurice Machado's](https://github.com/mauricemach) [CoffeeKup](https://github.com/mauricemach/coffeekup) - Markup as CoffeeScript

- [Rasmus Andersson's](https://github.com/rsms) [Move](https://github.com/rsms/move) - A simple, functional-biased, powerful javascript pre-precessor
- [Ryan Dahl's](https://github.com/ry) [Node.js](http://nodejs.org) - Server Side Javascript	

- [Sam Stephenson's](https://github.com/sstephenson) [Eco](https://github.com/sstephenson/eco) - Embedded CoffeeScript templates

- [Tim Caswell's](https://github.com/creationix) [Haml.js](https://github.com/creationix/haml-js) - Markup haiku
- [TJ Holowaychuk's](https://github.com/visionmedia) [Commander.js](https://github.com/visionmedia/commander.js) - Console apps made easy
- [TJ Holowaychuk's](https://github.com/visionmedia) [Express.js](https://github.com/visionmedia/express) - The "Server" in Server Side Javascript
- [TJ Holowaychuk's](https://github.com/visionmedia) [Jade](https://github.com/visionmedia/jade) - A robust, elegant, feature rich template engine
- [TJ Holowaychuk's](https://github.com/visionmedia) [Mocha](https://github.com/visionmedia/mocha) - Simple, Flexible, Fun Unit Testing
- [TJ Holowaychuk's](https://github.com/visionmedia) [Node-Growl](https://github.com/visionmedia/node-growl) - Notifications made easy
- [TJ Holowaychuk's](https://github.com/visionmedia) [Sass.js](https://github.com/visionmedia/sass.js) - Syntactically awesome stylesheets
- [TJ Holowaychuk/LearnBoost's](https://github.com/learnboost) [Stylus](https://github.com/learnboost/stylus) - Expressive, robust, feature-rich CSS language
- [TJ Holowaychuk's](https://github.com/visionmedia) [YAML](https://github.com/visionmedia/js-yaml) - Data made easy


## History

You can discover the history inside the [History.md](https://github.com/bevry/docpad/blob/master/History.md#files) file


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)
<br/>Copyright &copy; 2011 [Benjamin Lupton](http://balupton.com)
