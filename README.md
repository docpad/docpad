# DocPad. It makes web development intuitive again.

Initially web development was pretty easy, you just wrote a bunch of files and you got your website. These days, it's a lot more complicated than that. Things like databases, synchronisation, legacy frameworks and languages all slow the entire process down into a painful crawl. _It doesn't have to be like that._

DocPad takes that good ol' simple approach of writing files and wraps it with the best modern innovations, providing an awesome intuitive, liberating and empowering solution for HTML5 web design & development.


## Let's take a look

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

1. Then when you generate your website with docpad you will get a html file at `out/posts/hello.html`, which contains:

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

### Styles

- [Stylus](http://learnboost.github.com/stylus/) to CSS `.css.styl|stylus`
- [LessCSS](http://lesscss.org/) to CSS `.css.less`
- [SASS](http://sass-lang.com/) to CSS `.css.sass|scss`

### Scripts

- [CoffeeScript](http://jashkenas.github.com/coffee-script/) to JavaScript `.js.coffee` and JavaScript to CoffeeScript `.coffee.js`

### Parsers

- [YAML](https://github.com/visionmedia/js-yaml) with `--- yaml` (default)
- [CoffeeScript](http://jashkenas.github.com/coffee-script/) with `--- coffee`

### Features

- Runs on Node.js 0.4, 0.5, and 0.6
- Can run on windows
- Dynamic documents
	- Allows you to have documents that re-render on each request
- Ability to extend the server yourself
	- This allows you to utilise docpad while adding in your own server-side logic
- Version checking
	- Always stay up to date
- Mix and match renderers; e.g. `file.html.md.eco`
- Easy plugin infrastructure



## About

DocPad is getting pretty popular these days... you can check out [a bunch of websites already using it here](https://github.com/balupton/docpad/wiki/Showcase), and [discover the awesomely handsome crew behind the community here](https://github.com/balupton/docpad/wiki/Users). Ocassionally we also hold [events and competitions](https://github.com/balupton/docpad/wiki/Events) where you can learn more about docpad, hack with others together, and win some cool stuff! Nifty.

On that note, DocPad is awesomely extensible. You can [download other people's plugins](https://github.com/balupton/docpad/wiki/Extensions) and use them in real quick, or even [write your own in matters of minutes.](https://github.com/balupton/docpad/wiki/Extending)

[Best yet, definitely check out the entire wiki, as this has just been a small taste of it's awesomeness, and there is plenty awesomness left to be discovered.](https://github.com/balupton/docpad/wiki)

Thanks. DocPad loves you.



## Installing

1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

1. Install dependencies
		
		npm install -g coffee-script

1. Install DocPad

		npm install -g docpad

1. _or... [install the cutting edge version](https://github.com/balupton/docpad/wiki/Testing)_

1. If you also want growl notifications (OSX), then install [the growl command line tool here](http://growl.cachefly.net/GrowlNotify-1.3.zip)

_Getting errors? [Try troubleshooting](https://github.com/balupton/docpad/wiki/Troubleshooting)_



## Using

- Firstly, make a directory for your new website and cd into it

		mkdir my-new-website
		cd my-new-website

- To get started, simply run the following - it will run all the other commands at once
	
		docpad run

- To generate a basic website structure in the current working directory if we don't already have one

		docpad scaffold

- To regenerate the rendered website

		docpad generate

- To regenerate the rendered website automatically whenever we make a change to a file

		docpad watch

- To run the docpad server which allows you to access the generated website in a web browser

		docpad server

_Getting errors? [Try troubleshooting](https://github.com/balupton/docpad/wiki/Troubleshooting)_



## History

- v2.2 November 14, 2011
	- Windows support!
	- Now uses [Benjamin Lupton's](https://github.com/balupton) [Watchr](https://github.com/balupton/watchr) as the watcher library
		- Provides windows support
	- Now uses [Tim Caswell's](https://github.com/creationix) [Haml.js](https://github.com/creationix/haml-js) as the haml library
		- Provides windows support
	- Bug fixes
		- Works with zero documents
		- Works with empty `package.json`
		- Fixed mime-type problems with documents

- v2.1 November 10, 2011
	- Support for dynamic documents
		- These are re-rendered on each request, must use the docpad server
		- See the search example in the [kitchensink skeleton](https://github.com/balupton/kitchensink.docpad)
	- Removed deprecated `@Document`, `@Documents`, and `@Site` from the `templateData` (the variables available to the templates). Use their lowercase equivalants instead. This can cause backwards compatibility problems with your templates, the console will notify you if there is a problem.
	- Fixed `docpad --version` returning `null` instead of the docpad version

- v2.0 November 8, 2011
	- [Upgrade guide for 1.x users](https://github.com/balupton/docpad/wiki/Upgrading)
	- Tested and working on Node 0.4, 0.5, and 0.6
		- Windows support is still to come - [track it's progress here](https://github.com/balupton/docpad/issues/26)
	- Configurable via `package.json`
		- DocPad is now configurable via it's and your website's `package.json` file
	- New plugin architecture
		- Plugins must now be isolated in their own directory
		- Plugins can now have their own `package.json` file
			- Use this for specifying plugin configuration, dependencies, etc
		- Plugin events have been renamed to before/after
			- New before/after events have been added
		- `docpad` and `logger` are now local variables, rather than passed arguments
			- Arguments are still kept for backwards compatibility - this may change
	- Generation changes
		- Rendering is now a 2-pass process
		- Contextualize is now a sub-step of parse, instead of it's own main step
			- Better simplicity, less complexity
		- Documents can now have multiple urls
			- These are customisable via the document's `urls` array property
	- Plugin Changes
		- REST plugin supports saving document data via POST (disabled by default)
		- Administration plugin adds front-end admin functionality (disabled by default)
			- See the client side editing example in the [kitchensink skeleton](https://github.com/balupton/kitchensink.docpad)
		- SASS plugin
			- Adds [SASS](http://sass-lang.com/) to CSS support
				- Uses [TJ Holowaychuk's](https://github.com/visionmedia) [Sass.js](https://github.com/visionmedia/sass.js)
		- Coffee Plugin
			- Removed CoffeeCSS support as was playing up

- v1.4 October 22, 2011
	- Template engines now have access to node.js's `require`
	- Less Plugin
		- Added [LessCSS](http://lesscss.org/) to CSS support
			- Uses [Alexis Sellier's](https://github.com/cloudhead) [Less.js](https://github.com/cloudhead/less.js)
	- Fixed NPM warning about incorrect property name
	- Logged errors will now also output their stacktraces for easier debugging
	- If an error occurs during rendering of a document, docpad will let us know which document it happened on

- v1.3 October 3, 2011
	- Parsing is now split into two parts `parsing` and `contextualizing`
		- Contextualizing is used to determine the result filename, and title if title was not set
	- The code is now more concise
		- File class moved to `lib/file.coffee`
		- Prototypes moved to `lib/prototypes.coffee`
		- Version checking moved to bal-util
	- File properties have changed
		- `basename` is extensionless
		- `filename` now contains the file's extnesions
		- `id` is now the `relativeBase` instead of the `slug`
		- `extensionRendered` is the result extension
		- `filenameRendered` is the result filename: `"#{basename}.#{extensionRendered}"
		- `title` if now set to `filenameRendered` if not set
	- Added support for different meta parsers, starting with [CoffeeScript](http://jashkenas.github.com/coffee-script/) and [YAML](https://github.com/visionmedia/js-yaml) support. YAML is still the default meta parser.
	- The YAML dependency is specifically set now to v0.2.1 as the newer version has a bug in it.
	- Fixed multiple renderers for a single document. E.g. `file.html.md.eco`
	- Now also supports using `###` along with `---` for wrapping the meta data
	- Supports the `public` alias for the `files` directory

- v1.2 September 29, 2011
	- Plugins now conform to a .plugin.coffee naming standard
	- Dependencies now allow for minor patches
	- Stylus Plugin
		- Added [Stylus](http://learnboost.github.com/stylus/) to CSS support
			- Uses [TJ Holowaychuk's](https://github.com/learnboost) [Stylus](https://github.com/learnboost/stylus)
	- Jade Plugin
		- Added HTML to [Jade](http://jade-lang.com/) support
			- Uses [Don Park's](https://github.com/donpark) [Html2Jade](https://github.com/donpark/html2jade)
	- Coffee Plugin
		- Added [CoffeeCSS](https://github.com/aeosynth/ccss) to CSS support
			- Uses [James Campos's](https://github.com/aeosynth) [CCSS](https://github.com/aeosynth/ccss)
	- Fixed incorrect date sorting for documents
		- Thanks to [Olivier Bazoud](https://github.com/obazoud) for the heads up

- v1.1 September 28, 2011
	- Added [Buildr](http://github.com/balupton/buildr.npm) Plugin so you can now bundle your scripts and styles together :-)
	- The `action` method now supports an optional callback
		- Thanks to [#41](https://github.com/balupton/docpad/pull/41) by [Aaron Powell](https://github.com/aaronpowell)
	- Added a try..catch around the version detection to ensure it never kills docpad if something goes wrong
	- Skeletons have been removed from the repository due to circular references. The chosen skeleton is now pulled during the skeleton action. We also now perform a recursive git submodule init and update, as well as a npm install if necessary.

- v1.0 September 20, 2011
	- [Upgrade guide for v0.x users](https://github.com/balupton/docpad/wiki/Upgrading)
	- The concept of template engines and markup languages have been merged into the concept of renderers
	- Coffee Plugin
		- Added [CoffeeKup](http://coffeekup.org/) to anything and HTML to CoffeeKup support
			- Uses [Maurice Machado's](https://github.com/mauricemach) [CoffeeKup](https://github.com/mauricemach/coffeekup) and [Brandon Bloom's](https://github.com/brandonbloom) [Html2CoffeeKup](https://github.com/brandonbloom/html2coffeekup)
		- Added [CoffeeScript](http://jashkenas.github.com/coffee-script/) to JavaScript and JavaScript to CoffeeScript support
			- Uses [Jeremy Ashkenas's](https://github.com/jashkenas) [CoffeeScript](https://github.com/jashkenas/coffee-script/) and [Rico Sta. Cruz's](https://github.com/rstacruz) [Js2Coffee](https://github.com/rstacruz/js2coffee)
	- Added a [Commander.js](https://github.com/visionmedia/commander.js) based CLI
		- Thanks to [~eldios](https://github.com/eldios)
	- Added support for [Growl](http://growl.info/) notificaitons
	- Added asynchronous version comparison

- v0.10 September 14, 2011
	- Plugin infrastructure
	- Better logging through [Caterpillar](https://github.com/balupton/caterpillar.npm)
	- HAML Plugin
		- Added [HAML](http://haml-lang.com/) to anything support
			- Uses [TJ Holowaychuk's](https://github.com/visionmedia) [HAML](https://github.com/visionmedia/haml.js)
	- Jade Plugin
		- Added [Jade](http://jade-lang.com/) to anything support
			- Uses [TJ Holowaychuk's](https://github.com/visionmedia) [Jade](https://github.com/visionmedia/jade)

- v0.9 July 6, 2011
	- No longer uses MongoDB/Mongoose! We now use [Query-Engine](https://github.com/balupton/query-engine.npm) which doesn't need any database server :)
	- Watching files now working even better
	- Now supports clean urls :)

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



## Thanks

DocPad wouldn't be possible if it wasn't for the following libaries _(in alphabetical order)_

- [Alexis Sellier's](https://github.com/cloudhead) [Less.js](https://github.com/cloudhead/less.js) - Leaner CSS
- [Andrew Schaaf's](https://github.com/tafa) [Watch-Tree](https://github.com/tafa/node-watch-tree) - Node.js file watching made easy

- [Benjamin Lupton's](https://github.com/balupton) [Bal-Util](https://github.com/balupton/bal-util.npm) - Node.js made easy
- [Benjamin Lupton's](https://github.com/balupton) [Caterpillar](https://github.com/balupton/caterpillar.npm) - Logging made easy
- [Benjamin Lupton's](https://github.com/balupton) [Query-Engine](https://github.com/balupton/query-engine.npm) - The MongoDB Query-Engine without the Database
- [Benjamin Lupton's](https://github.com/balupton) [Watchr](https://github.com/balupton/watchr) - Node.js recursive directory watching made easy
- [Brandon Bloom's](https://github.com/brandonbloom) [Html2CoffeeKup](https://github.com/brandonbloom/html2coffeekup)- HTML to CoffeeKup Converter

- [Don Park's](https://github.com/donpark) [Html2Jade](https://github.com/donpark/html2jade) - HTML to Jade Converter

- [James Campos'](https://github.com/aeosynth) [CCSS](https://github.com/aeosynth/ccss) - CSS as CoffeeScript
- [Jeremy Ashkenas'](https://github.com/jashkenas) [CoffeeScript](http://jashkenas.github.com/coffee-script) - JavaScript made easy
- [Jeremy Ashkenas/DocumentCloud's](https://github.com/documentcloud/underscore) [Underscore](https://github.com/documentcloud/underscore) - The utility-belt library for JavaScript

- [Maurice Machado's](https://github.com/mauricemach) [CoffeeKup](https://github.com/mauricemach/coffeekup) - Markup as CoffeeScript

- [Sam Stephenson's](https://github.com/sstephenson) [Eco](https://github.com/sstephenson/eco) - Embedded CoffeeScript templates

- [Tim Caswell's](https://github.com/creationix) [Haml.js](https://github.com/creationix/haml-js) - Markup haiku
- [TJ Holowaychuk's](https://github.com/visionmedia) [Commander.js](https://github.com/visionmedia/commander.js) - Console apps made easy
- [TJ Holowaychuk's](https://github.com/visionmedia) [Express.js](https://github.com/visionmedia/express) - The "Server" in Server Side Javascript
- [TJ Holowaychuk's](https://github.com/visionmedia) [Jade](https://github.com/visionmedia/jade) - A robust, elegant, feature rich template engine
- [TJ Holowaychuk's](https://github.com/visionmedia) [Node-Growl](https://github.com/visionmedia/node-growl) - Notifications made easy
- [TJ Holowaychuk's](https://github.com/visionmedia) [Sass.js](https://github.com/visionmedia/sass.js) - Syntactically awesome stylesheets
- [TJ Holowaychuk/LearnBoost's](https://github.com/learnboost) [Stylus](https://github.com/learnboost/stylus) - Expressive, robust, feature-rich CSS language
- [TJ Holowaychuk's](https://github.com/visionmedia) [YAML](https://github.com/visionmedia/js-yaml) - Data made easy

- [Ryan Dahl's](https://github.com/ry) [Node.js](http://nodejs.org) - Server Side Javascript	


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)