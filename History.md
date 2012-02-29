## History

- v3.3.0 February 29, 2012
	- Fixed ruby rendering with ruby v1.8
		- Thanks to [Sorin Ionescu](https://github.com/sorin-ionescu) - [patch here](https://github.com/bevry/docpad/commit/a3f711b1b015b2fa31490bbbaca2cf9c3ead3016)
	- The `enabledPlugins` config option will now correctly only overwrite the default values if you have set it to be a string
		- Before it would always incorrectly overwrite the default value if set, which would cause some experimental disabled-by-default plugins to enable
	- Added a [Pygments](http://pygments.org/) Syntax Highlighting plugin
		- It is disabled by default as not everyone would want syntax highlighting, to enable it, add the following to your website's `package.json` file:
			``` javascript
			"docpad": {
				"enabledPlugins": {
					"pygments": true
				}
			}
			```
		- Thanks to [Doug Neiner](https://github.com/dcneiner) for urging it along
	- Added a new `renderDocument` plugin event
		- It is fired after the extensions are rendered, but before the document is rendered inside its layout
		- Useful for things that modify the rendered result of a document, e.g. syntax highlighting, paging, etc
	- Closes
		- [#146](https://github.com/bevry/docpad/pull/146) - Require RubyGems on Ruby 1.8
		- [#137](https://github.com/bevry/docpad/pull/137) - An error occured: Cannot find module 'uglify-js'
		- [#34](https://github.com/bevry/docpad/issues/34) - As a User, I want server-side syntax highlighting, as pygments rocks

- v3.2.8 February 26, 2012
	- Stopped `docpad render` from outputting the welcome message
	- Removed `try..catch`s from plugins, you should do this too
		- The checking is now higher up in the callstack, which provides better error reporting and capturing
	- Fixed a problem with the error bubbling that was preventing template errors from being outputted
	- Fixed the "too many files open" issue thanks to [bal-util](http://github.com/balupton/bal-util.npm)'s `openFile` and `closeFile` utility functions
	- Closes
		- [#143](https://github.com/bevry/docpad/issues/143) - No errors on wrong layout

- v3.2.7 February 15, 2012
	- Stabilised the v3.2 branch

- v3.2 February 15, 2012
	- Cleaned architecture
	- Added unit tests (uses mocha)
	- Better source code documentation
	- Moved changelog from `README.md` to `History.md` as it was starting to get a bit long
	- Added `File.writeRendered`
	- Added `File.contentRenderedWithoutLayout`
	- Watching will no longer watch hidden files
	- Added support for
		- [Ruby](http://www.ruby-lang.org/)
		- [ERuby](http://en.wikipedia.org/wiki/ERuby)
		- [PHP](http://php.net/)
		- [Move](http://movelang.org/)
		- [Hogan/Mustache](http://twitter.github.com/hogan.js/)
	- Added the ability to render files programatically via the command line
		- See the readme for usage instructions and more information
	- Backwards compatibility breaks
		- File property names have been changed
		- New plugin structure
	- Added offline installation support
	- Added skeleton selection
	- Added npm scripts for testing, installing and updating
	- Closes
		- #130 - As a Maintainer, I want unit tests, so that I can automatically ensure everything works
		- #127 - As a User, I want support for Move, so I can write my javascript in my preferred language
		- #122 - As a User, I want to be able to get the rendered content without the layout, so that I can include it inside other documents
		- #98 - As a User, I want offline creation, so I can create new docpad projects offline
		- #97 - Watching is unusable when combined with hidden files from IDEs and SVN
		- #57 - Offline Setup: Skeletons needs to be cached for future offline installs
		- #55 - As a User, I want support for Moustache, so that I can use my preferred markup
		

- v3.1 Unreleased
	- Added an interactive cli
	- Closes
		- #125 - As a User, I want an Interactive CLI, so that I can do more with DocPad's CLI

		

- v3.0 Unreleased
	- Added a new event system
	- Closes
		- #60 - DocPad needs a better event system
		

- v2.6 January 2, 2012
	- Transferred DocPad's ownership from [Benjamin Lupton](http://balupton.com) to [Bevry](http://bevry.me) (Benjamin's company)
		- Things that have changed
			- It is now easier for us to manage DocPad, its extensions, collaborators and future repositories
				- Thanks to Github's excellent organisation functionality - https://github.com/blog/674-introducing-organizations
			- DocPad is now supported and backed by a commercial entity, meaning that it won't go away
		- Things that won't change
			- DocPad will remain free as in beer, and free as in freedom
			- DocPad will remain awesome
		- If you are working on a cloned version of docpad, be sure to update your docpad's git repo address
	- Fixed plugin priorities [#115](https://github.com/bevry/docpad/pull/115)
		- Thanks to [Changwoo Park](https://github.com/pismute)
	- Updated depdencies
		- Growl 1.2.x -> 1.4.x [- changelog](https://github.com/visionmedia/node-growl/blob/master/History.md)
		- CoffeeScript 1.1.3 -> 1.2.x [- changelog](http://coffeescript.org/#changelog)

- v2.5 December 15, 2011
	- Swapped out [Dominic Baggott's](https://github.com/evilstreak) [Markdown.js](http://github.com/evilstreak/markdown-js) for [Isaac Z. Schlueter's](https://github.com/isaacs) [Github-Flavored-Markdown](https://github.com/isaacs/github-flavored-markdown)
		- Now adds support for inline html in markdown files
			- Closes #107
	- Fixed plugin installation on windows
		- Had to disable the AutoUpdate and Html2Jade plugins
		- Had to use the global npm instance on windows
		- Closes [#111](https://github.com/bevry/docpad/pull/111), [#110](https://github.com/bevry/docpad/pull/110)
	- Fixed the error: `Object #<Object> has no method 'error'`
		- Fixes [#106](https://github.com/bevry/docpad/pull/106)
	- Can now pass over options to the coffeekup renderer inside the coffee plugin
		- E.g. set `docpad: plugins: coffee: coffeekup: format: true` to have it tidy the html output
		- Thanks to [Changwoo Park](https://github.com/pismute)
	- Disabled the following plugins by default
		- Admin
		- Authenticate
		- Rest
		- AutoUpdate
		- Buildr
		- Html2Jade
	- Updated depdencies
		- Commander 0.3.x -> 0.5.x [- changelog](https://github.com/visionmedia/commander.js/blob/master/History.md)
		- Growl 1.1.x -> 1.2.x [- changelog](https://github.com/visionmedia/node-growl/blob/master/History.md)
		- NPM 1.0.x -> 1.1.x
		- Jade 0.17.x -> 0.19.x [- changelog](https://github.com/visionmedia/jade/blob/master/History.md)
		- Stylus 0.19.x -> 0.20.x [- changelog](https://github.com/LearnBoost/stylus/blob/master/History.md)
		- Nib 0.2.x -> 0.3.x [- changelog](https://github.com/visionmedia/nib/blob/master/History.md)

- v2.4 November 26, 2011
	- AutoUpdate plugin
		- Automatically refreshes the user's current page when the website is regenerated
		- Very useful for development, though you probably want to disable it for production
		- Enabled by default

- v2.3 November 18, 2011
	- [Heroku](https://heroku.com/) server support
	- Added `extendServer` configuration option
		- Now, by default, even if the server is provided, we will extend it. If you do not want this, set this configuration option to `false`.
	- Made it easier to load docpad as a module
	- Instead of crashing when an uncaught error happens, it'll output it and keep running
	- The log messages and next handling in `docpad.action` has been cleaned up
		- Now those log messages are contained within the default next handler, so if you provide a custom default next handler you'll have to do your own success log messages
	- [NPM](https://github.com/isaacs/npm) is now installed locally
		- This is to ensure it's availability on cloud servers
	- DocPad will now try and figure out the node executable location to provide greater compatibility on cloud servers
	- If the plugin installations are taking a while, you'll get informed of this, rather than just staring at a blank blinking cursor
	- Roy plugin
		- Adds [Roy](http://roy.brianmckenna.org/) to JavaScript support `.js.roy`

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
		- See the search example in the [kitchensink skeleton](https://github.com/bevry/kitchensink.docpad)
	- Removed deprecated `@Document`, `@Documents`, and `@Site` from the `templateData` (the variables available to the templates). Use their lowercase equivalants instead. This can cause backwards compatibility problems with your templates, the console will notify you if there is a problem.
	- Fixed `docpad --version` returning `null` instead of the docpad version

- v2.0 November 8, 2011
	- [Upgrade guide for 1.x users](https://github.com/bevry/docpad/wiki/Upgrading)
	- Tested and working on Node 0.4, 0.5, and 0.6
		- Windows support is still to come - [track it's progress here](https://github.com/bevry/docpad/issues/26)
	- Configurable via `package.json`
		- DocPad is now configurable via its and your website's `package.json` file
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
			- See the client side editing example in the [kitchensink skeleton](https://github.com/bevry/kitchensink.docpad)
		- SASS plugin
			- Adds [SASS](http://sass-lang.com/) to CSS support
				- Uses TJ Holowaychuk's Sass.js - https://github.com/visionmedia/sass.js
		- Coffee Plugin
			- Removed CoffeeCSS support as it had problems

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
		- Version checking moved to the `bal-util` module
	- File properties have changed
		- `basename` is extensionless
		- `filename` now contains the file's extnesions
		- `id` is now the `relativeBase` instead of the `slug`
		- `extensionRendered` is the result extension
		- `filenameRendered` is the result filename: `"#{basename}.#{extensionRendered}"
		- `title` if now set to `filenameRendered` if not set
	- Added support for different meta parsers, starting with [CoffeeScript](http://jashkenas.github.com/coffee-script/) and [YAML](https://github.com/visionmedia/js-yaml) support. YAML is still the default meta parser
	- The YAML dependency is specifically set now to v0.2.1 as the newer version has a bug in it
	- Fixed multiple renderers for a single document. E.g. `file.html.md.eco`
	- Now also supports using `###` along with `---` for wrapping the meta data
	- Supports the `public` alias for the `files` directory

- v1.2 September 29, 2011
	- Plugins now conform to a `.plugin.coffee` naming standard
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
		- Thanks to [Olivier Bazoud](https://github.com/obazoud)

- v1.1 September 28, 2011
	- Added [Buildr](http://github.com/balupton/buildr.npm) Plugin so you can now bundle your scripts and styles together :-)
	- The `action` method now supports an optional callback
		- Thanks to [#41](https://github.com/bevry/docpad/pull/41) by [Aaron Powell](https://github.com/aaronpowell)
	- Added a try..catch around the version detection to ensure it never kills docpad if something goes wrong
	- Skeletons have been removed from the repository due to circular references. The chosen skeleton is now pulled during the skeleton action. We also now perform a recursive git submodule init and update, as well as a npm install if necessary.

- v1.0 September 20, 2011
	- [Upgrade guide for v0.x users](https://github.com/bevry/docpad/wiki/Upgrading)
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


