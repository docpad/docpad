[![DocPad Logo](https://raw.githubusercontent.com/bevry/designs/1437c9993a77b24c3ad1856087908b508f3ceec6/docpad/flyers/docpad-youtube.gif)](http://docpad.org "Visit the DocPad Website")

<!-- TITLE/ -->

<h1>DocPad. Streamlined web development.</h1>

<!-- /TITLE -->


<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.org/docpad/docpad" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/docpad/docpad/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/docpad" title="View this project on NPM"><img src="https://img.shields.io/npm/v/docpad.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/docpad" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/docpad.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/docpad/docpad" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/docpad/docpad.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/docpad/docpad#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/docpad/docpad.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-slackin"><a href="https://slack.bevry.me" title="Join this project's slack community"><img src="https://slack.bevry.me/badge.svg" alt="Slack community badge" /></a></span>
<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="http://flattr.com/thing/344188/balupton-on-Flattr" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=QB8GQPZAH84N6" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<!-- /BADGES -->


Hi! I'm DocPad, I streamline the web development process and help close the gap between experts and beginners. I've been used in production by big and small companies for over a year and a half now to create [plenty of amazing and powerful web sites and applications](http://docpad.org/docs/showcase) quicker than ever before. What makes me different is instead of being a box to cram yourself into and hold you back, I'm a freeway to what you want to accomplish, just getting out of your way and allowing you to create stuff quicker than ever before without limits. Leave the redundant stuff up to me, so you can focus on the awesome stuff.

Discover my features below, or skip ahead to the installation instructions to get started with a [fully functional pre-made website](http://docpad.org/docs/skeletons) in a few minutes from reading this.

**[Watch the Screencast!](http://www.youtube.com/watch?v=hvQCXDWh7Wg&feature=share&list=PLYVl5EnzwqsQs0tBLO6ug6WbqAbrpVbNf)**


## Features

### Out of the box

- Competely file based, meaning there are no pesky databases that need to be installed, and for version control you get to use systems like Git and SVN, which you're already used to (You can still hook in remote data sources if you want, DocPad doesn't impose any limits on you, ever)
- Choose from plenty of community maintained [pre-made websites](http://docpad.org/docs/skeletons) to use for your next project instead of starting from scratch every time
- Write your documents in any language, markup, templating engine, or pre-processor you wish (we're truly agnostic thanks to your plugin system). You can even mix and match them when needed by combining their extensions in a rails-like fashion (e.g. `coffee-with-some-eco.js.coffee.eco`)
- Changes to your website are automatically recompiled through our built-in watch system
- Add metadata to the top of your files to be used by templating engines to display non-standard information such as titles and descriptions for your documents
- Display custom listings of content with our powerful [Query Engine](https://github.com/bevry/query-engine/) available to your templating engines
- Abstract out generic headers and footers into layouts using our nested layout system
- For simple static websites easily deploy your generated website to any web server like apache or github pages. For dynamic projects deploy them to servers like [heroku](http://www.heroku.com/) or [nodejitsu](http://nodejitsu.com/) to take advantage of custom routing with [express.js](http://expressjs.com/). [Deploy guide here](http://docpad.org/docs/deploy)
- Built-in server to save you from having to startup your own, for dynamic deployments this even supports things like clean urls, custom routes and server-side logic
- Robust architecture and powerful plugin system means that you are never boxed in. Unlike traditional CMS systems, you can always [extend DocPad](http://docpad.org/docs/extend) to do whatever you need it to do, and you can even write to bundle common custom functionality and distribute them through the amazing node package manager [npm](http://npmjs.org/)
- Built-in support for dynamic documents (e.g. search pages, signup forms, etc), so you can code pages that change on each request by just adding `dynamic: true` to your document's meta data (exposes the [express.js](http://expressjs.com/) `req` and `res` objects to your templating engine)
- You can use it standalone, or even easily include it within your existing systems with our [API](http://docpad.org/docs/api)


### With our amazing community maintained plugins

- Use the [Live Reload](http://docpad.org/plugin/livereload/) plugin to automatically refresh your web browser whenever a change is made, this is amazing
- Pull in remote RSS/Atom/JSON feeds into your templating engines allowing you to display your latest twitter updates or github projects easily and effortlessly using the [Feedr Plugin](http://docpad.org/plugin/feedr/)
- Support for every templating engine and pre-processor under the sun, including (but not limited to) CoffeeScript, CoffeeKup, ECO, HAML, Handlebars, Jade, Less, Markdown, PHP, Ruby, SASS and Stylus - [the full listing is here](http://docpad.org/docs/plugins)
- Use the [Partials Plugin](http://docpad.org/plugin/partials) to abstract common pieces of code into their own individual file that can be included as much as you want
- Syntax highlight code blocks automatically with either our [Highlight.js Plugin](http://docpad.org/plugin/highlightjs/) or [Pygments Plugin](http://docpad.org/plugin/pygments/)
- Get SEO friendly clean URLs with our [Clean URLs Plugin](http://docpad.org/plugin/cleanurls/) (dynamic deployments only)
- Lint your code automatically with our Ling Plugins: [jshint](https://github.com/jking90/docpad-plugin-jshint) and [coffeelint](https://github.com/jking90/docpad-plugin-coffeelint)
- Concatenate and minify your JavaScript and CSS assets making page loads faster for your users with our Minify Plugins: [htmlmin](https://github.com/robloach/docpad-plugin-htmlmin) and [grunt](https://gist.github.com/balupton/3898915)
- Install common javascript libraries like jQuery, Backbone and Underscore directly from the command line - (under construction, coming soon)
- Automatically translate your entire website into other languages with our Translation Plugin - under construction, coming soon
- Add a admin interface to your website allowing you to edit, save and preview your changes on live websites then push them back to your source repository with the [Admin Plugins](http://docpad.org/docs/plugins#admin-interfaces)
- Pretty much if DocPad doesn't already do something, it is trivial to [write a plugin](http://docpad.org/docs/extend) to do it. DocPad can accomplish anything; it never holds you back, and there are no limits.
- [Many other plugins](http://docpad.org/docs/plugins) not listed here that are still definitely worth checking out! :)


## People love DocPad

All sorts of people love DocPad, from first time web developers to even industry leaders and experts. In fact, people even migrate to DocPad from other systems as they love it so much. Here are some our [favourite tweets](https://twitter.com/#!/DocPad/favorites) of what people are saying about DocPad :)

[![Some favourite tweets about DocPad](https://github.com/bevry/designs/raw/1437c9993a77b24c3ad1856087908b508f3ceec6/docpad/favourites/docpad-favs.gif)](https://twitter.com/#!/DocPad/favorites)




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
- [Everything else](http://docpad.org/docs/)


<!-- HISTORY/ -->

<h2>History</h2>

<a href="https://github.com/docpad/docpad/blob/master/HISTORY.md#files">Discover the release history by heading on over to the <code>HISTORY.md</code> file.</a>

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

<h2>Contribute</h2>

<a href="https://github.com/docpad/docpad/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

<h2>Backers</h2>

<h3>Maintainers</h3>

These amazing people are maintaining this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/docpad/docpad/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository docpad/docpad">view contributions</a></li>
<li><a href="http://mikeum.us">Michael Duane Mooring</a> — <a href="https://github.com/docpad/docpad/commits?author=mikeumus" title="View the GitHub contributions of Michael Duane Mooring on repository docpad/docpad">view contributions</a></li>
<li><a href="http://robloach.net">Rob Loach</a> — <a href="https://github.com/docpad/docpad/commits?author=RobLoach" title="View the GitHub contributions of Rob Loach on repository docpad/docpad">view contributions</a></li></ul>

<h3>Sponsors</h3>

These amazing people have contributed finances to this project:

<ul><li><a href="http://www.myplanetdigital.com">Myplanet Digital</a></li>
<li><a href="http://www.meeho.net">Meeho!</a></li>
<li><a href="http://www.prismatik.com.au">Prismatik</a></li>
<li><a href="http://yaas.io/">hybris</a></li></ul>

Become a sponsor!

<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="http://flattr.com/thing/344188/balupton-on-Flattr" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=QB8GQPZAH84N6" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<h3>Contributors</h3>

These amazing people have contributed code to this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/docpad/docpad/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.aaron-powell.com">Aaron Powell</a> — <a href="https://github.com/docpad/docpad/commits?author=aaronpowell" title="View the GitHub contributions of Aaron Powell on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/adrianolaru">Adrian Olaru</a> — <a href="https://github.com/docpad/docpad/commits?author=adrianolaru" title="View the GitHub contributions of Adrian Olaru on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/amesarosh">Alex Mesarosh</a> — <a href="https://github.com/docpad/docpad/commits?author=amesarosh" title="View the GitHub contributions of Alex Mesarosh on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/alexwoehr">alexwoehr</a> — <a href="https://github.com/docpad/docpad/commits?author=alexwoehr" title="View the GitHub contributions of alexwoehr on repository docpad/docpad">view contributions</a></li>
<li><a href="http://klimchuk.com">Ivan Klimchuk</a> — <a href="https://github.com/docpad/docpad/commits?author=Alroniks" title="View the GitHub contributions of Ivan Klimchuk on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.acusti.ca">Andrew Patton</a> — <a href="https://github.com/docpad/docpad/commits?author=acusti" title="View the GitHub contributions of Andrew Patton on repository docpad/docpad">view contributions</a></li>
<li><a href="http://ashnur.com">GÁBOR Áron Zsolt</a> — <a href="https://github.com/docpad/docpad/commits?author=ashnur" title="View the GitHub contributions of GÁBOR Áron Zsolt on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/barberboy">Ben Barber</a> — <a href="https://github.com/docpad/docpad/commits?author=barberboy" title="View the GitHub contributions of Ben Barber on repository docpad/docpad">view contributions</a></li>
<li><a href="http://delapouite.com">Bruno Heridet</a> — <a href="https://github.com/docpad/docpad/commits?author=Delapouite" title="View the GitHub contributions of Bruno Heridet on repository docpad/docpad">view contributions</a></li>
<li><a href="http://pismute.github.io">Changwoo Park</a> — <a href="https://github.com/docpad/docpad/commits?author=pismute" title="View the GitHub contributions of Changwoo Park on repository docpad/docpad">view contributions</a></li>
<li><a href="http://aptiture.com">Morgan Larosa</a> — <a href="https://github.com/docpad/docpad/commits?author=chaos95" title="View the GitHub contributions of Morgan Larosa on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/chase">Chase Colman</a> — <a href="https://github.com/docpad/docpad/commits?author=chase" title="View the GitHub contributions of Chase Colman on repository docpad/docpad">view contributions</a></li>
<li><a href="http://derberg.github.io/">Lukasz Gornicki</a> — <a href="https://github.com/docpad/docpad/commits?author=derberg" title="View the GitHub contributions of Lukasz Gornicki on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/eldios">eldios</a> — <a href="https://github.com/docpad/docpad/commits?author=eldios" title="View the GitHub contributions of eldios on repository docpad/docpad">view contributions</a></li>
<li><a href="blog.sylee.tw">Shih-Yung Lee</a> — <a href="https://github.com/docpad/docpad/commits?author=Ferrari" title="View the GitHub contributions of Shih-Yung Lee on repository docpad/docpad">view contributions</a></li>
<li><a href="http://greduan.com">Eduardo Lavaque</a> — <a href="https://github.com/docpad/docpad/commits?author=greduan" title="View the GitHub contributions of Eduardo Lavaque on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/homme">Homme Zwaagstra</a> — <a href="https://github.com/docpad/docpad/commits?author=homme" title="View the GitHub contributions of Homme Zwaagstra on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.jtwebman.com">JT Turner</a> — <a href="https://github.com/docpad/docpad/commits?author=jtwebman" title="View the GitHub contributions of JT Turner on repository docpad/docpad">view contributions</a></li>
<li><a href="http://blog.blase16.de/">Bahtiar `kalkin-` Gadimov</a> — <a href="https://github.com/docpad/docpad/commits?author=kalkin" title="View the GitHub contributions of Bahtiar `kalkin-` Gadimov on repository docpad/docpad">view contributions</a></li>
<li><a href="lukehagan.com">Luke Hagan</a> — <a href="https://github.com/docpad/docpad/commits?author=lhagan" title="View the GitHub contributions of Luke Hagan on repository docpad/docpad">view contributions</a></li>
<li><a href="http://mikeum.us">Michael Duane Mooring</a> — <a href="https://github.com/docpad/docpad/commits?author=mikeumus" title="View the GitHub contributions of Michael Duane Mooring on repository docpad/docpad">view contributions</a></li>
<li><a href="www.myplanetdigital.com">Neil Taylor</a> — <a href="https://github.com/docpad/docpad/commits?author=neilbaylorrulez" title="View the GitHub contributions of Neil Taylor on repository docpad/docpad">view contributions</a></li>
<li><a href="nfriedly.com">Nathan Friedly</a> — <a href="https://github.com/docpad/docpad/commits?author=nfriedly" title="View the GitHub contributions of Nathan Friedly on repository docpad/docpad">view contributions</a></li>
<li><a href="http://nickcrohn.com/">Nick Crohn</a> — <a href="https://github.com/docpad/docpad/commits?author=ncrohn" title="View the GitHub contributions of Nick Crohn on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/obazoud">Olivier Bazoud</a> — <a href="https://github.com/docpad/docpad/commits?author=obazoud" title="View the GitHub contributions of Olivier Bazoud on repository docpad/docpad">view contributions</a></li>
<li><a href="http://paularmstrongdesigns.com/">Paul Armstrong</a> — <a href="https://github.com/docpad/docpad/commits?author=paularmstrong" title="View the GitHub contributions of Paul Armstrong on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/pavangupta">pavangupta</a> — <a href="https://github.com/docpad/docpad/commits?author=pavangupta" title="View the GitHub contributions of pavangupta on repository docpad/docpad">view contributions</a></li>
<li><a href="https://pavgup.io">Pavan Gupta</a> — <a href="https://github.com/docpad/docpad/commits?author=pavgup" title="View the GitHub contributions of Pavan Gupta on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/pflannery">Peter Flannery</a> — <a href="https://github.com/docpad/docpad/commits?author=pflannery" title="View the GitHub contributions of Peter Flannery on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.alolo.co">Dario</a> — <a href="https://github.com/docpad/docpad/commits?author=radiodario" title="View the GitHub contributions of Dario on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/rantecki">Richard A</a> — <a href="https://github.com/docpad/docpad/commits?author=rantecki" title="View the GitHub contributions of Richard A on repository docpad/docpad">view contributions</a></li>
<li><a href="http://robloach.net">Rob Loach</a> — <a href="https://github.com/docpad/docpad/commits?author=RobLoach" title="View the GitHub contributions of Rob Loach on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.ruemic.com">RueMic</a> — <a href="https://github.com/docpad/docpad/commits?author=ruemic" title="View the GitHub contributions of RueMic on repository docpad/docpad">view contributions</a></li>
<li><a href="http://shawnzhu.tumblr.com">Ke Zhu</a> — <a href="https://github.com/docpad/docpad/commits?author=shawnzhu" title="View the GitHub contributions of Ke Zhu on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/sorin-ionescu">Sorin Ionescu</a> — <a href="https://github.com/docpad/docpad/commits?author=sorin-ionescu" title="View the GitHub contributions of Sorin Ionescu on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/stegrams">Stefanos Grammenos</a> — <a href="https://github.com/docpad/docpad/commits?author=stegrams" title="View the GitHub contributions of Stefanos Grammenos on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/disenchant">Sven Vetsch</a> — <a href="https://github.com/docpad/docpad/commits?author=disenchant" title="View the GitHub contributions of Sven Vetsch on repository docpad/docpad">view contributions</a></li>
<li><a href="http://timaschew.github.io">Anton Wilhelm</a> — <a href="https://github.com/docpad/docpad/commits?author=timaschew" title="View the GitHub contributions of Anton Wilhelm on repository docpad/docpad">view contributions</a></li>
<li><a href="kendoui.com">Todd Anglin</a> — <a href="https://github.com/docpad/docpad/commits?author=toddanglin" title="View the GitHub contributions of Todd Anglin on repository docpad/docpad">view contributions</a></li>
<li><a href="http://www.triplet.fi">Tatu Tamminen</a> — <a href="https://github.com/docpad/docpad/commits?author=ttamminen" title="View the GitHub contributions of Tatu Tamminen on repository docpad/docpad">view contributions</a></li>
<li><a href="http://unframework.com">Nick Matantsev</a> — <a href="https://github.com/docpad/docpad/commits?author=unframework" title="View the GitHub contributions of Nick Matantsev on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/darrrk">Vladislav Botvin</a> — <a href="https://github.com/docpad/docpad/commits?author=darrrk" title="View the GitHub contributions of Vladislav Botvin on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/vsopvsop">vsopvsop</a> — <a href="https://github.com/docpad/docpad/commits?author=vsopvsop" title="View the GitHub contributions of vsopvsop on repository docpad/docpad">view contributions</a></li>
<li><a href="https://github.com/Zearin">Zearin</a> — <a href="https://github.com/docpad/docpad/commits?author=Zearin" title="View the GitHub contributions of Zearin on repository docpad/docpad">view contributions</a></li>
<li><a href="http://firede.us">Firede</a> — <a href="https://github.com/docpad/docpad/commits?author=firede" title="View the GitHub contributions of Firede on repository docpad/docpad">view contributions</a></li></ul>

<a href="https://github.com/docpad/docpad/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /BACKERS -->


### Participants
Also thanks to all the countless others who have continued to raise DocPad even higher by submitting plugins, issues reports, discussion topics, IRC chat messages, and praise on twitter. We love you.


<!-- LICENSE/ -->

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2012+ <a href="http://bevry.me">Bevry Pty Ltd</a></li>
<li>Copyright &copy; <a href="http://balupton.com">Benjamin Lupton</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->