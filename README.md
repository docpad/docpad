# DocPad. Intuitive web development. [![Build Status](https://secure.travis-ci.org/bevry/docpad.png?branch=master)](http://travis-ci.org/bevry/docpad)

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
	- DocPad's static site generation abilities are great for this, and with DocPad's built-in support for dynamic documents we can also cater for the odd search page, enquiry form or twitter stream

- for thick client-side web applications
	- Combining DocPad's pre-precessor support and static site generation is amazing for developing thick client applications, as you can utilise the latest pre-precessors at any time, allowing you to focus on the problem, instead of how to implement the problem



## Benefits over other Static Site Generators

- Truly language agnostic, able to code your documents in any markup or pre-precessor that you like, you can even mix and match them!
    - _[see what markups are already supported](https://github.com/bevry/docpad/wiki/Plugins)_
- Great for any type of website, not just for blogging
    - _[discover existing websites already built with DocPad](https://github.com/bevry/docpad/wiki/Showcase)_
- Get started from scratch with a fully functional website in a few minutes
    - _[you can use an already built website as the basis of your new one](https://github.com/bevry/docpad/wiki/Skeletons)_
- Highly extensible and easy to use plugin system
    - _[pretty much if DocPad doesn't already do something, it's trivial to get a plugin to do it](https://github.com/bevry/docpad/wiki/Extending)_
- Easy to extend the server with custom routes, or use DocPad as module in an even bigger system
    - _[it's easier than you think, find out how](https://github.com/bevry/docpad/wiki/API)_
- Deploy easily to plenty of free Node.js hosting providers, or even just deploy it to plenty of free static file servers like GitHub Pages and more
    - _[view our hosting guide](https://github.com/bevry/docpad/wiki/Hosting)_
- Built in support for dynamic documents (e.g. search pages, signup forms, etc.), so you can code pages that change on each request
    - _documentation coming soon_



## Installing

1. [Install Node.js](https://github.com/bevry/community/wiki/Installing-Node)

1. Install DocPad

	``` bash
	[sudo] npm install -g -f docpad@6.5
	[sudo] docpad install
	```

1. If you also want growl notifications (OSX), then download and install the `GrowlNotify` tool from the [Growl Download Page](http://growl.info/downloads)

_Getting errors? [Try troubleshooting](https://github.com/bevry/docpad/wiki/Troubleshooting)_



## Quick Start

Once you've installed, you can get started with a brand new spunky functional website in a matter of minutes, by just running:

``` bash
mkdir my-new-website
cd my-new-website
docpad run
```

This will create your website, watch for changes, and launch the DocPad server. It will ask you if you would like to base your website from an [already existing one](https://github.com/bevry/docpad/wiki/Skeletons "DocPad allows people to share their existing websites as skeletons, to help bootstrap your next website. You can discover a listing of them here.") to get started even quicker.

Once done, simply go to [http://localhost:9778/](http://localhost:9778/) to view your new website :) or when your website uses a different port, go to the url that `docpad run` mentions



## What next?

Here are some quick links to help you get started:

- [Getting Started](https://github.com/bevry/docpad/wiki/Getting-Started)
- [Frequently Asked Questions](https://github.com/bevry/docpad/wiki/FAQ)
- [Showcase and Examples](https://github.com/bevry/docpad/wiki/Showcase)
- [Guides and Tutorials](https://github.com/bevry/docpad/wiki/Guides)
- [Hosting Guide](https://github.com/bevry/docpad/wiki/Hosting)
- [Extension Guide](https://github.com/bevry/docpad/wiki/Extending)
- [Plugins](https://github.com/bevry/docpad/wiki/Plugins)
- [Skeletons](https://github.com/bevry/docpad/wiki/Skeletons)
- [Troubleshooting](https://github.com/bevry/docpad/wiki/Troubleshooting)
- [Support Forum](https://groups.google.com/forum/#!forum/docpad)
- [Bug Tracker](https://github.com/bevry/docpad/issues)
- IRC Chat Room: `#docpad` on freenode
- [Everything else](https://github.com/bevry/docpad/wiki)



## History

You can discover the version history inside the [History.md](https://github.com/bevry/docpad/blob/master/History.md#files) file



## License

Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)
<br/>Copyright &copy; 2011 [Benjamin Lupton](http://balupton.com)



## Special Thanks

Special thanks to all our wonderful contributors who have helped shaped the DocPad core of today:

- [Benjamin Lupton](https://github.com/balupton)
- [eldios](https://github.com/eldios)
- [Changwoo Park](https://github.com/pismute)
- [Todd Anglin](https://github.com/toddanglin)
- [Olivier Bazoud](https://github.com/obazoud)
- [Zhao Lei](https://github.com/firede)
- [Aaron Powell](https://github.com/aaronpowell)
- [Andrew Patton](https://github.com/acusti)
- [Paul Armstrong](https://github.com/paularmstrong)
- [Sorin Ionescu](https://github.com/sorin-ionescu)
- [Ferrari Lee](https://github.com/Ferrari)
- [Ben Barber](https://github.com/barberboy)
- [Nick Crohn](https://github.com/ncrohn)
- [Bruno Héridet](https://github.com/Delapouite)
- [Sven Vetsch](https://github.com/disenchant)

Also thanks to all the countless others who have continued to raise DocPad even higher by submitting plugins, issues reports, discussion topics, IRC chat messages, and praise on twitter. We love you.

Lastly, thank YOU for giving us a go, believing us, and loving us. We love you too.

Sincerely, the DocPad team

[![Flattr this project](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/344188/balupton-on-Flattr)