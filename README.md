# DocPad. Streamlined web development. [![Build Status](https://secure.travis-ci.org/bevry/docpad.png?branch=master)](http://travis-ci.org/bevry/docpad)

Hi! I'm DocPad, I streamline the web development process and help close the gap between experts and beginners. I've been used in production by big and small companies for over a year and a half now to create [plenty of amazing and powerful web sites and applications](https://github.com/bevry/docpad/wiki/Showcase) quicker than ever before. What makes me different is instead of being a box to cram yourself into and hold you back, I'm a freeway to what you want to accomplish, just getting out of your way and allowing you to create stuff quicker than ever before without limits. Leave the redudant stuff up to me, so you can focus on the awesome stuff.

Discover my features below, or skip ahead to the installation instructions to get started with a [fully functional pre-made website](https://github.com/bevry/docpad/wiki/Skeletons) in a few minutes from reading this.

## Features

### Out of the box

- Competely file based meaning there is no pesky databases that need to be installed, and for version control you get to use systems like Git and SVN which you're already use to (You can still hook in remote data sources if you want, DocPad doesn't impose any limits on you, ever)
- Choose from plenty of community maintained [pre-made websites](https://github.com/bevry/docpad/wiki/Skeletons) to use for your next project instead of starting from scratch everytime
- Write your documents in any language, markup, templating engine, or pre-processor you wish (we're truly agnostic thanks to your plugin system). You can even mix and match them when needed by combining their extensions in a rails like fashion (e.g. `coffee-with-some-eco.js.coffee.eco`)
- Changes to your website are automatically recompiled through our built in watch system, saving you time
- Add meta data to the top of your files to be used by templating engines to display non-standard information such as titles and descriptions for your documents
- Display custom listings of content with our powerful [Query Engine](https://github.com/bevry/query-engine/) available to your templating engines
- Abstract out generic headers and footers into layouts using our nested layout system
- For simple static websites easily deploy your generated website to any web server like apache or github pages. For dynamic projects deploy them to servers like [heroku](http://www.heroku.com/) or [nodejitsu](http://nodejitsu.com/) to take advantage of custom routing with [express.js](http://expressjs.com/). [Deploy guide here](https://github.com/bevry/docpad/wiki/Hosting)
- Built-in server to save you from having to startup your own, for dynamic deployments this even supports things like clean urls, custom routes and server-side logic
- Robust architecture and powerful plugin system means that you are never boxed in unlike traditional CMS systems, instead you can always [extend DocPad](https://github.com/bevry/docpad/wiki/Extending) to do whatever you need it to do, and you can even write to bundle common custom functionality and distribute them through the amazing node package manager [npm](http://npmjs.org/)
- Built in support for dynamic documents (e.g. search pages, signup forms, etc.), so you can code pages that change on each request by just adding `dynamic: true` to your document's meta data (exposes the [express.js](http://expressjs.com/) `req` and `res` objects to your templating engine)
- You can use it standalone, or even easily include it within your existing systems with our [API](https://github.com/bevry/docpad/wiki/API)


### With our amazing community maintained plugins

- Use the [Live Reload](https://github.com/bevry/docpad-extras/tree/master/plugins/livereload) plugin to automatically refresh your web browser whenever a change is made, this is amazing
- Pull in remote RSS/Atom/JSON feeds into your templating engines allowing you to display your latest twitter updates or github projects easily and effortlessly using the [Feedr Plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/feedr/)
- Support for every templating engine and pre-processor under the sun, including  but not limited to CoffeeScript, CoffeeKup, ECO, HAML, Handlebars, Jade, Less, Markdown, PHP, Ruby, SASS and Stylus - [the full listing is here](https://github.com/bevry/docpad/wiki/Plugins)
- Use the [Partials Plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/partials/) to abstract common pieces of code into their own individual file that can be included as much as you want
- Syntax highlight code blocks automatically with our [Pygments Plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/pygments/)
- Get SEO friendly clean URLs with our [Clean URLs Plugin](https://github.com/bevry/docpad-extras/tree/master/plugins/cleanurls/) (dynamic deployments only)
- Lint your code automatically with our Lint Plugin - under construction, coming soon
- Concatenate and minify your JavaScript and CSS assets making page loads faster for your users with our Minify Plugin - under construction, coming soon
- Install common javascript libraries like jQuery, Backbone and Underscore directly from the command line - under construction, coming soon
- Automatically translate your entire website into other languages with our Translation Plugin - under construction, coming soon
- Add a admin interface to your website allowing you to edit, save and preview your changes on live websites then push them back to your source repository with the Admin Plugin - under construction, coming soon
- Pretty much if DocPad doesn't already do something, it is trivial to [write a plugin](https://github.com/bevry/docpad/wiki/Extending) to do it, seriously DocPad can accomplish anything, it never holds you back, there are no limits, it's like super powered guardian angel
- There are also [plenty of other plugins](https://github.com/bevry/docpad/wiki/Plugins) not listed here that are still definitely worth checking out! :)


## People love DocPad

All sorts of people love DocPad, from first time web developers to even industry leaders and experts. In fact, people even migrate to DocPad from other systems as they love it so much. Here are some our [favourite tweets](https://twitter.com/#!/DocPad/favorites) of what people are saying about DocPad :)

[![Some favourite tweets about DocPad](https://raw.github.com/bevry/docpad/dev/docs/favs.gif)](https://twitter.com/#!/DocPad/favorites)




## Installing

1. [Install Node.js](https://github.com/bevry/community/wiki/Installing-Node)

1. Install DocPad

	``` bash
	[sudo] npm install -fg docpad@6.6
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