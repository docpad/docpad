[![DocPad Logo](http://d.pr/i/cfmt+)](http://docpad.org "Visit the DocPad Website")

<!-- TITLE/ -->

# DocPad. Streamlined web development.

<!-- /TITLE -->


<!-- BADGES/ -->

[![Build Status](http://img.shields.io/travis-ci/bevry/docpad.png?branch=master)](http://travis-ci.org/bevry/docpad "Check this project's build status on TravisCI")
[![NPM version](http://badge.fury.io/js/docpad.png)](https://npmjs.org/package/docpad "View this project on NPM")
[![Dependency Status](https://david-dm.org/bevry/docpad.png?theme=shields.io)](https://david-dm.org/bevry/docpad)
[![Development Dependency Status](https://david-dm.org/bevry/docpad/dev-status.png?theme=shields.io)](https://david-dm.org/bevry/docpad#info=devDependencies)<br/>
[![Gittip donate button](http://img.shields.io/gittip/docpad.png)](https://www.gittip.com/docpad/ "Donate weekly to this project using Gittip")
[![Flattr donate button](http://img.shields.io/flattr/donate.png?color=yellow)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](http://img.shields.io/paypal/donate.png?color=yellow)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](http://img.shields.io/bitcoin/donate.png?color=yellow)](https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a "Donate once-off to this project using BitCoin")
[![Wishlist browse button](http://img.shields.io/wishlist/browse.png?color=yellow)](http://amzn.com/w/2F8TXKSNAFG4V "Buy an item on our wishlist for us")

<!-- /BADGES -->


Hi! I'm DocPad, I streamline the web development process and help close the gap between experts and beginners. I've been used in production by big and small companies for over a year and a half now to create [plenty of amazing and powerful web sites and applications](http://docpad.org/docs/showcase) quicker than ever before. What makes me different is instead of being a box to cram yourself into and hold you back, I'm a freeway to what you want to accomplish, just getting out of your way and allowing you to create stuff quicker than ever before without limits. Leave the redudant stuff up to me, so you can focus on the awesome stuff.

Discover my features below, or skip ahead to the installation instructions to get started with a [fully functional pre-made website](http://docpad.org/docs/skeletons) in a few minutes from reading this.

**[Watch the Screencast!](http://www.youtube.com/watch?v=hvQCXDWh7Wg&feature=share&list=PLYVl5EnzwqsQs0tBLO6ug6WbqAbrpVbNf)**


## Features

### Out of the box

- Competely file based meaning there is no pesky databases that need to be installed, and for version control you get to use systems like Git and SVN which you're already use to (You can still hook in remote data sources if you want, DocPad doesn't impose any limits on you, ever)
- Choose from plenty of community maintained [pre-made websites](http://docpad.org/docs/skeletons) to use for your next project instead of starting from scratch everytime
- Write your documents in any language, markup, templating engine, or pre-processor you wish (we're truly agnostic thanks to your plugin system). You can even mix and match them when needed by combining their extensions in a rails like fashion (e.g. `coffee-with-some-eco.js.coffee.eco`)
- Changes to your website are automatically recompiled through our built in watch system
- Add meta data to the top of your files to be used by templating engines to display non-standard information such as titles and descriptions for your documents
- Display custom listings of content with our powerful [Query Engine](https://github.com/bevry/query-engine/) available to your templating engines
- Abstract out generic headers and footers into layouts using our nested layout system
- For simple static websites easily deploy your generated website to any web server like apache or github pages. For dynamic projects deploy them to servers like [heroku](http://www.heroku.com/) or [nodejitsu](http://nodejitsu.com/) to take advantage of custom routing with [express.js](http://expressjs.com/). [Deploy guide here](http://docpad.org/docs/deploy)
- Built-in server to save you from having to startup your own, for dynamic deployments this even supports things like clean urls, custom routes and server-side logic
- Robust architecture and powerful plugin system means that you are never boxed in unlike traditional CMS systems, instead you can always [extend DocPad](http://docpad.org/docs/extend) to do whatever you need it to do, and you can even write to bundle common custom functionality and distribute them through the amazing node package manager [npm](http://npmjs.org/)
- Built in support for dynamic documents (e.g. search pages, signup forms, etc.), so you can code pages that change on each request by just adding `dynamic: true` to your document's meta data (exposes the [express.js](http://expressjs.com/) `req` and `res` objects to your templating engine)
- You can use it standalone, or even easily include it within your existing systems with our [API](http://docpad.org/docs/api)


### With our amazing community maintained plugins

- Use the [Live Reload](http://docpad.org/plugin/livereload/) plugin to automatically refresh your web browser whenever a change is made, this is amazing
- Pull in remote RSS/Atom/JSON feeds into your templating engines allowing you to display your latest twitter updates or github projects easily and effortlessly using the [Feedr Plugin](http://docpad.org/plugin/feedr/)
- Support for every templating engine and pre-processor under the sun, including  but not limited to CoffeeScript, CoffeeKup, ECO, HAML, Handlebars, Jade, Less, Markdown, PHP, Ruby, SASS and Stylus - [the full listing is here](http://docpad.org/docs/plugins)
- Use the [Partials Plugin](http://docpad.org/plugin/partials) to abstract common pieces of code into their own individual file that can be included as much as you want
- Syntax highlight code blocks automatically with either our [Highlight.js Plugin](http://docpad.org/plugin/highlightjs/) or [Pygments Plugin](http://docpad.org/plugin/pygments/)
- Get SEO friendly clean URLs with our [Clean URLs Plugin](http://docpad.org/plugin/cleanurls/) (dynamic deployments only)
- Lint your code automatically with our Ling Plugins: [jshint](https://github.com/jking90/docpad-plugin-jshint) and [coffeelint](https://github.com/jking90/docpad-plugin-coffeelint)
- Concatenate and minify your JavaScript and CSS assets making page loads faster for your users with our Minify Plugins: [htmlmin](https://github.com/robloach/docpad-plugin-htmlmin) and [grunt](https://gist.github.com/balupton/3898915)
- Install common javascript libraries like jQuery, Backbone and Underscore directly from the command line - under construction, coming soon
- Automatically translate your entire website into other languages with our Translation Plugin - under construction, coming soon
- Add a admin interface to your website allowing you to edit, save and preview your changes on live websites then push them back to your source repository with the [Admin Plugins](http://docpad.org/docs/plugins#admin-interfaces)
- Pretty much if DocPad doesn't already do something, it is trivial to [write a plugin](http://docpad.org/docs/extend) to do it, seriously DocPad can accomplish anything, it never holds you back, there are no limits, it's like super powered guardian angel
- There are also [plenty of other plugins](http://docpad.org/docs/plugins) not listed here that are still definitely worth checking out! :)


## People love DocPad

All sorts of people love DocPad, from first time web developers to even industry leaders and experts. In fact, people even migrate to DocPad from other systems as they love it so much. Here are some our [favourite tweets](https://twitter.com/#!/DocPad/favorites) of what people are saying about DocPad :)

[![Some favourite tweets about DocPad](https://github.com/bevry/designs/raw/master/docpad/favourites/docpad-favs.gif)](https://twitter.com/#!/DocPad/favorites)




## Install

[Click here for our latest Install Instructions.](http://docpad.org/docs/install)


## Quick Start

[Click here to skip ahead to our latest Quick Start Guide.](http://docpad.org/docs/start)


## What next?

Here are some quick links to help you get started:

- [Getting Started](http://docpad.org/docs/intro)
- [Frequently Asked Questions](http://docpad.org/docs/faq)
- [Showcase and Examples](http://docpad.org/docs/showcase)
- [Guides and Tutorials](http://docpad.org/docs/)
- [Deployment Guide](http://docpad.org/docs/deploy)
- [Extension Guide](http://docpad.org/docs/extend)
- [Plugins](http://docpad.org/docs/plugins)
- [Skeletons](http://docpad.org/docs/skeletons)
- [Troubleshooting](http://docpad.org/docs/troubleshoot)
- [Support Channels](http://docpad.org/support)
- [Bug Tracker](http://docpad.org/issues)
- [IRC Chat Room: `#docpad` on freenode](http://webchat.freenode.net?channels=docpad)
- [Everything else](http://docpad.org/docs/)


<!-- HISTORY/ -->

## History
[Discover the change history by heading on over to the `HISTORY.md` file.](https://github.com/bevry/docpad/blob/master/HISTORY.md#files)

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

## Contribute

[Discover how you can contribute by heading on over to the `CONTRIBUTING.md` file.](https://github.com/bevry/docpad/blob/master/CONTRIBUTING.md#files)

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

## Backers

### Maintainers

These amazing people are maintaining this project:

- Benjamin Lupton <b@lupton.cc> (https://github.com/balupton)

### Sponsors

These amazing people have contributed finances to this project:

- Myplanet Digital <hello@myplanetdigital.com> (http://www.myplanetdigital.com)
- Meeho! <info@meeho.net> (http://www.meeho.net)

Become a sponsor!

[![Gittip donate button](http://img.shields.io/gittip/docpad.png)](https://www.gittip.com/docpad/ "Donate weekly to this project using Gittip")
[![Flattr donate button](http://img.shields.io/flattr/donate.png?color=yellow)](http://flattr.com/thing/344188/balupton-on-Flattr "Donate monthly to this project using Flattr")
[![PayPayl donate button](http://img.shields.io/paypal/donate.png?color=yellow)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QB8GQPZAH84N6 "Donate once-off to this project using Paypal")
[![BitCoin donate button](http://img.shields.io/bitcoin/donate.png?color=yellow)](https://coinbase.com/checkouts/9ef59f5479eec1d97d63382c9ebcb93a "Donate once-off to this project using BitCoin")
[![Wishlist browse button](http://img.shields.io/wishlist/browse.png?color=yellow)](http://amzn.com/w/2F8TXKSNAFG4V "Buy an item on our wishlist for us")

### Contributors

These amazing people have contributed code to this project:

- [Aaron Powell](https://github.com/aaronpowell) <me@aaron-powell.com> — [view contributions](https://github.com/bevry/docpad/commits?author=aaronpowell)
- [Adrian Olaru](https://github.com/adrianolaru) <agolaru@gmail.com> — [view contributions](https://github.com/bevry/docpad/commits?author=adrianolaru)
- [Alex](https://github.com/amesarosh) — [view contributions](https://github.com/bevry/docpad/commits?author=amesarosh)
- [Alroniks](https://github.com/Alroniks) — [view contributions](https://github.com/bevry/docpad/commits?author=Alroniks)
- [Andrew Patton](https://github.com/acusti) <andrew@acusti.ca> — [view contributions](https://github.com/bevry/docpad/commits?author=acusti)
- [Ashnur](https://github.com/ashnur) — [view contributions](https://github.com/bevry/docpad/commits?author=ashnur)
- [Ben Barber](https://github.com/barberboy) — [view contributions](https://github.com/bevry/docpad/commits?author=barberboy)
- [Benjamin Lupton](https://github.com/balupton) <b@lupton.cc> — [view contributions](https://github.com/bevry/docpad/commits?author=balupton)
- [Bruno Héridet](https://github.com/Delapouite) — [view contributions](https://github.com/bevry/docpad/commits?author=Delapouite)
- [Changwoo Park](https://github.com/pismute) <pismute@gmail.com> — [view contributions](https://github.com/bevry/docpad/commits?author=pismute)
- [Chase Colman](https://github.com/chase) <chase@infinityatlas.com> — [view contributions](https://github.com/bevry/docpad/commits?author=chase)
- [eldios](https://github.com/eldios) <lele@amicofigo.com> — [view contributions](https://github.com/bevry/docpad/commits?author=eldios)
- [Ferrari Lee](https://github.com/Ferrari) <shiyung@gmail.com> — [view contributions](https://github.com/bevry/docpad/commits?author=Ferrari)
- [Homme Zwaagstra](https://github.com/homme) <hrz@geodata.soton.ac.uk> — [view contributions](https://github.com/bevry/docpad/commits?author=homme)
- [kalkin](https://github.com/kalkin) — [view contributions](https://github.com/bevry/docpad/commits?author=kalkin)
- [Luke Hagan](https://github.com/lhagan) — [view contributions](https://github.com/bevry/docpad/commits?author=lhagan)
- [mikeumus](https://github.com/mikeumus) — [view contributions](https://github.com/bevry/docpad/commits?author=mikeumus)
- [Neil Taylor](https://github.com/neilbaylorrulez) <neil.t@myplanetdigital.com> — [view contributions](https://github.com/bevry/docpad/commits?author=neilbaylorrulez)
- [nfriedly](https://github.com/nfriedly) — [view contributions](https://github.com/bevry/docpad/commits?author=nfriedly)
- [Nick Crohn](https://github.com/ncrohn) <ncrohn@me.com> — [view contributions](https://github.com/bevry/docpad/commits?author=ncrohn)
- [Olivier Bazoud](https://github.com/obazoud) — [view contributions](https://github.com/bevry/docpad/commits?author=obazoud)
- [Paul Armstrong](https://github.com/paularmstrong) <paul@paularmstrongdesigns.com> — [view contributions](https://github.com/bevry/docpad/commits?author=paularmstrong)
- [pflannery](https://github.com/pflannery) — [view contributions](https://github.com/bevry/docpad/commits?author=pflannery)
- [radiodario](https://github.com/radiodario) — [view contributions](https://github.com/bevry/docpad/commits?author=radiodario)
- [Richard A](https://github.com/rantecki) <richard@antecki.id.au> — [view contributions](https://github.com/bevry/docpad/commits?author=rantecki)
- [ruemic](https://github.com/ruemic) — [view contributions](https://github.com/bevry/docpad/commits?author=ruemic)
- [Sorin Ionescu](https://github.com/sorin-ionescu) <sorin.ionescu@gmail.com> — [view contributions](https://github.com/bevry/docpad/commits?author=sorin-ionescu)
- [Stefan](https://github.com/stegrams) — [view contributions](https://github.com/bevry/docpad/commits?author=stegrams)
- [Sven Vetsch](https://github.com/disenchant) — [view contributions](https://github.com/bevry/docpad/commits?author=disenchant)
- [timaschew](https://github.com/timaschew) — [view contributions](https://github.com/bevry/docpad/commits?author=timaschew)
- [Todd Anglin](https://github.com/toddanglin) — [view contributions](https://github.com/bevry/docpad/commits?author=toddanglin)
- [ttamminen](https://github.com/ttamminen) — [view contributions](https://github.com/bevry/docpad/commits?author=ttamminen)
- [unframework](https://github.com/unframework) — [view contributions](https://github.com/bevry/docpad/commits?author=unframework)
- [Vladislav Botvin](https://github.com/darrrk) <darkvlados@me.com> — [view contributions](https://github.com/bevry/docpad/commits?author=darrrk)
- [Zearin](https://github.com/Zearin) — [view contributions](https://github.com/bevry/docpad/commits?author=Zearin)
- [Zhao Lei](https://github.com/firede) <aicoylei@gmail.com> — [view contributions](https://github.com/bevry/docpad/commits?author=firede)

[Become a contributor!](https://github.com/bevry/docpad/blob/master/CONTRIBUTING.md#files)

<!-- /BACKERS -->


### Participants
Also thanks to all the countless others who have continued to raise DocPad even higher by submitting plugins, issues reports, discussion topics, IRC chat messages, and praise on twitter. We love you.


<!-- LICENSE/ -->

## License

Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT license](http://docpad.org/license)

Copyright &copy; 2012+ Bevry Pty Ltd <us@bevry.me> (http://bevry.me)
<br/>Copyright &copy; 2011 Benjamin Lupton <b@lupton.cc> (http://balupton.com)

<!-- /LICENSE -->


