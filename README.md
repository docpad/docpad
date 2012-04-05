# DocPad. Intuitive web development.

[![Flattr this project](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/344188/balupton-on-Flattr) 

Initially web development was pretty easy, you just wrote a bunch of files and you got your website. These days, it's a lot more complicated than that. Things like databases, synchronisation, legacy frameworks and languages all slow the entire process down into a painful crawl. _It doesn't have to be like that._

DocPad takes that good ol' simple approach of writing files and wraps it with the best modern innovations, providing an awesome intuitive, liberating and empowering solution for HTML5 web design & development.

At its core DocPad is a language agnostic document management system. This means you write your website as documents, in whatever language you wish, and DocPad will handle the compiling, templates and layouts for you. For static documents it will generate static files, for dynamic documents it'll re-render them on each request. You can utilise DocPad by itself, or use it as a module your own custom system. It's pretty cool, and well worth checking out. We love it.




## When would using DocPad be ideal?

- for learning and implementing new languages and web technologies into real-world applications
	- DocPad's ability to run a potential infinite amount of languages is amazing, and as you are always working with a real website you're never forced to re-implement anything into another system.

- for rapid prototyping of new interfaces which need to facilate changes quickly
	- The ability to get up and running as quickly as possible with DocPad really helps here, along with its support for pre-precessors you can quickly move about your codebase and rejig things when things need to change - without having to rewrite any architecture.

- for frontend prototypes which will be handed over to the backend developers for implementation
	- Often to gain layouts, templating, and pre-precessor support we'll have to implement a web framework, a templating engine, and code a custom build script for each of our pre-precessors that we use. This takes a lot of uncessary time, and complicates things during handover to the backend developers who then need to learn the tools that you've used. Using DocPad we abstract all that difficulty and handle it beautifully, allowing you to just focus on the files you want to write, and we'll provide you with the layout engine, templating engine, and pre-precessor support you need. When it comes to handover, the backend developers will have your source files, as well as the compiled files allowing them to use whichever is easiest for them.

- for simple websites like blogs, launch pages, etc
	- DocPad's static site generation abilities are great for this, and with DocPad's built-in support for dynamic documents we can also cater for the odd search page, enquiry form or twitter steam

- for thick client-side web applications
	- Combining DocPad's pre-precessor support and static site generation is amazing for developing thick client applications, as you can utilise the latest pre-precessors at any time, allowing you to focus on the problem, instead of how to implement the problem




## What features does it support?

- it's language agnostic, allowing you to write your documents in any language you wish, we already support over 10 languages (listed a few sections later)
- it will watch your source files for changes, and ensure your website is up to date automatically
- you'll get growl notifications every time we regenerate your website
- you can mix and match renderers, allowing you to combine languages e.g. eco and markdown with `file.html.md.eco`
- you can write both static and dynamic documents
	- for static documents a static output file will be generated
	- for dynamic documents they will be re-rendered on each request
- it provides a liquid layout engine allowing you to wrap a document in an infinite amount of layouts
- it provides an in-memory nosql database which you can query inside your documents or inside your app
- you can use DocPad as a module inside a bigger application, allowing you to utilise DocPad's generation abilities but do the heavy lifting in your own application
- it exposes the built-in [express.js](http://expressjs.com/) web server so you can extend it with your own routes and business logic
- it runs great on Linux, OSX, and Windows, as well as Node.js 0.4 and 0.6
- it provides automatic version checking letting you know when it's time to update
- you can add new features to DocPad easily and simply with its powerful plugin infrastucture
- it provides you with pre-made skeletons which can bootstrap your next project
- it provides optional server-side syntax highlighting with a [Pygments](http://pygments.org/) plugin
- it provides automatic clean urls support, and multiple url support out of the box



## What languages does it support?


### Markups

- [Markdown](http://daringfireball.net/projects/markdown/basics) to HTML `.html.md|markdown`
- [Eco](https://github.com/sstephenson/eco) to anything `.anything.eco`
- [CoffeeKup](http://coffeekup.org/) to anything `.anything.ck|coffeekup|coffee` and HTML to CoffeeKup `.ck|coffeekup|coffee.html`
- [Jade](http://jade-lang.com/) to anything `.anything.jade` and HTML to Jade `.jade.html`
- [HAML](http://haml-lang.com/) to anything `.anything.haml`
- [Hogan/Mustache](http://twitter.github.com/hogan.js/) to anything `.anything.hogan`
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

_Parsers are used inside the meta data areas of your content_



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

1. Great thanks! I think I will give it a go right now!



## Installing

1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

1. Install dependencies
		
		[sudo] npm install -g coffee-script

1. Install DocPad

		[sudo] npm install -g docpad
		[sudo] docpad install

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

DocPad is doing great these days, thanks to people like you! You can check out [a bunch of websites already using it here](https://github.com/bevry/docpad/wiki/Showcase), and [discover the awesomely handsome crew behind the community here](https://github.com/bevry/docpad/wiki/Users). Ocassionally we also hold [events and competitions](https://github.com/bevry/docpad/wiki/Events) where you can learn more about DocPad, hack with others together, and win some cool stuff! Nifty.

On that note, DocPad is awesomely extensible. You can [download other people's plugins](https://github.com/bevry/docpad/wiki/Extensions) and use them in real quick, or even [write your own in matters of minutes.](https://github.com/bevry/docpad/wiki/Extending)

[Best yet, definitely check out the entire wiki, as this has just been a small taste of it's awesomeness, and there is plenty awesomness left to be discovered.](https://github.com/bevry/docpad/wiki)

Thanks! DocPad loves you!!!




## History

You can discover the history inside the [History.md](https://github.com/bevry/docpad/blob/master/History.md#files) file




## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)
<br/>Copyright &copy; 2011 [Benjamin Lupton](http://balupton.com)
