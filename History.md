## History

- v6.6.5 September 18, 2012
	- Further improved file encoding detection
		- Closes [#266: Images are broken](https://github.com/bevry/docpad/issues/266)

- v6.6.4 September 4, 2012
	- Better file encoding detection
		- Closes [#288: Output of certain binary files is corrupt](https://github.com/bevry/docpad/issues/288)

- v6.6.3 September 3, 2012
	- Fixed `date` and `name` always being their automatic values

- v6.6.0-6.6.2 August 28, 2012
	- Added `docpad-debug` executable for easier debugging
	- Will now ask if you would like to subscribe to our newsletter when running on the development environment
	- Beginnings of localisation

- v6.5.7 August 26, 2012
	- Fixed "cannot get length of undefined" intermittent error
		- Due to an incorret variable name inside `DocPad::ensureDocumentOrFile`

- v6.5.6 August 19, 2012
	- Added `regenerateEvery` configuration option

- v6.5.0-6.5.5 August 10, 2012
	- IMPORTANT: Renamed `extensionRendered` to `outExtension`, `filenameRendered` to `outFilename`, and `contentTypeRendered` to `outContentType` and moved them from the Document model to the File model
	- The `serverExtend` event will now also emit the `express` dependency if used
	- No longer attempts to install plugins dependencies every time, this is outside the scope of DocPad and in the standard use cases already handled via npm
	- No longer accepts `npmPath`, `gitPath`, and `nodePath` as configuration options, instead these should be environment variables at `NPM_PATH`, `GIT_PATH`, and `NODE_PATH` respectively (without the underscore is also acceptable)
	- Eliminated ambiguity with `renderSingleExtensions`
		- if `true` it will render `markdown`, `.md` and `example.md`
		- if `'auto'` it will render `markdown` but not `.md` and `example.md`
		- `auto` is now used on the `docpad render` command
	- Can now specify a custom configuration file vis the command line using `-c, --config <configPath>`
	- Can now specify a custom outPath via the command line using `-o, --out <outPath>`
	- Can now set template data via `req.templateData`
	- Can now customise the action that the `docpad-server` executable performs by setting the `DOCPAD_SERVER_ACTION` environment variable
	- Fixed `Document::writeSource`
	- Fixed `require('docpad').createInstance` (was accidentally dropped in v6.2.0)
	- Fixed `no readme` npm warning
		- Removed markdown files from `.npmignore` as they are now required for the new npm website listing
	- Fixed the regeneration not picking up changes when modifying a referenced stylesheet
		- Added a new `stylesheet` collection that contains any stylesheet file (including pre-processors) and sets their `referenceOthers` property to `true`
	- Fixed `contextualizeBefore` and `contextualizeAfter` events not firing
		- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [pull request #277](https://github.com/bevry/docpad/pull/277)
	- Fixed `contentType` being looked up twice
		- Thanks to [Nick Crohn](https://github.com/ncrohn) for [pull request #273](https://github.com/bevry/docpad/pull/273)

- v6.4.1 July 19, 2012
	- Added new `source` attribute to the file model, as the `content` attribute on the document model is actually the `body` not the original content like it is in the file model

- v6.4.0 July 19, 2012
	- We now support `404 Not Found` and `500 Internal Server Error` error pages thanks to [Nick Crohn](https://github.com/ncrohn) for [pull request #251](https://github.com/bevry/docpad/pull/251)
	- Fixed [#269](https://github.com/bevry/docpad/issues/269) where the `docpad render` command wouldn't work
	- Fixed [#268](https://github.com/bevry/docpad/issues/268) where files which names start with a `.` from having a `.` appended to their output filename

- v6.3.3 July 18, 2012
	- Fixed binary file output
		- Added binary files to the test suite so this won't happen again
		- Was due to the dereference on the new clear introduced in v6.3.0
			- As such, we now store the `data` attribute for files outside of the attributes, use `getData` and `setData(data)` now instead of `get('data')` and `set({data:data})`

- v6.3.2 July 18, 2012
	- Fixed install action

- v6.3.1 July 18, 2012
	- Fixed `extendCollections` being called before the plugins have loaded when using the CLI

- v6.3.0 July 18, 2012
	- Added support for multiple environments
	- Top-level configuration assumed to reflect the production environment, other environments will extend from it
		- This is because getting a production environment configuration inside your development environment is fine, however getting a development environment configuration inside your production environment is catastrophic - as such, having the top-level configuration reflect the production environment handles this assumption correctly
	- Added environment configuration support to plugins and their configuration
	- Removed `package.json > docpad > plugin` configuration mode for a plugin's `package.json`, they should use the `config` property in their class instead
	- Added `isEnabled()` to the plugin class, this reflects the `enabled` property in the plugin configuration, if it is false, then no events are executed for that plugin
	- Killed the `docpad cli` action, no one used it and introduced a lot of complexity to the codebase
	- Added `populateCollections` event, use this to insert things into our collections and blocks
	- Added `docpadLoaded` event which fires whenever our configuration is re-loaded
	- Added support for overriding the `extension` attribute via your document's meta data
	- Added support for the `renderSingleExtensions` attribute in documents
	- Fixed `clean` action from not behaving as expected
		- Had the wrong indexOf indice value in the check
	- Fixed default attributes not being kept inside document and file attributes when cleared
		- Turns out Backbone's `Mode::clear()` wipes everything, rather than reset to the default attributes and values

- v6.2.0 July 10, 2012
	- Dropped node v0.4 support
		- Minimum required version is now 0.6
	- Dropped `npm` dependency
	- Configuration merging now deep extends plain javascript objects
	- Added environment specific configuration support
		- By default we use `process.env.NODE_ENV` for the environment, falling back to `development`
		- Specify your environment specific configuration in `environments[env]`
		- By default, our production environment sets `maxAge` to one day, and `checkVersion` to false
		- Use `getEnvironment` to get the current environment
	- Added new `extendCollections` event
	- Added check during clean action to ensure we don't remove outPath if it is higher than our rootPath
	- Added `docpad-server` binary to shortcut heroku deployment
	- Scripts collection now supports adding plaintext javascript
	- `consoleSetup` options are now `consoleInterface` and `commander` instead of `interface` and `program`
	- DocPad's main file is now `out/main.coffee` and the exported `require` is now limited to files in the `out` directory (not higher)

- v6.1.3 July 8, 2012
	- Fixed `extendTemplateData` event firing before our plugins have finished loading

- v6.1.2 July 8, 2012
	- Fixed `DocPad::getBlock`

- v6.1.1 July 8, 2012
	- Added `html` collection
	- Dependency updates
		- [chai](http://chaijs.com/) from v1.0 to v1.1

- v6.1.0 July 8, 2012
	- End user changes
		- Added suport for using no skeleton on empty directory
		- Action completion callback will now correctly return all arugments instead of just the error argument
		- Filename argument on command line is now optional, if specified it now supports single extension values, e.g. `markdown` instead of `file.html.md`
		- When using CoffeeScript intead of YAML for meta data headers, the CoffeeScript will now be sandboxed
			- If you are wanting to get stuff outside the sandbox write a `docpad.coffee` configuration file
	- Document and File model changes
		- Now work fine without any path specified
		- `render` split into `renderExtensions`, `renderDocument` and `renderLayout`
		- `renderExtensions` now supports the option `renderSingleExtensions` when specified, will prepend the extension `null`, allowing supported plugins to render single extensions
		- `render` now supports the option `actions` which is an array of actions to perform
		- we now do not clear the `contentRendered`, `contentRenderedWithoutLayouts`, and `rendered` properties between render passes
	- DocPad prototype changes
		- New Events
			- `extendTemplateData`, opts: `templateData`, `extend(objs...)`
		- Attached Classes
			- `Base`, `Model`, `Collection`, `View`, `QueryCollection`
			- `FileModel`, `DocumentModel`
			- `FilesCollection`, `ElementsCollection`, `MetaCollection`, `ScriptsCollection`, `StylesCollection`
			- `PluginLoader`, `BasePlugin`
		- New Collection Helpers
			- `getFiles(query,storting,paging)`
			- `getFile(query,sorting,paging)`
			- `getFilesAtPath(path,sorting,paging)`
			- `getFileAtPath(path,sorting,paging)`
		- New Render Helpers
			- `loadAndRenderDocument(document,opts,next)`
			- `renderDocument(document,opts,next)`
			- `renderPath(path,opts,next)`
			- `renderData(data,opts,next)`
			- `renderText(text,opts,next)`
		- New Template Data Helpers
			- `referencesOthers(flag)`
			- `getDocument()`
			- `getPath(path,parentPath)`
			- `getFiles(query,sorting,paging)`
			- `getFile(query,sorting,paging)`
			- `getFilesAtPath(path,sorting,paging)`
			- `getFileAtPath(path,sorting,paging)`
	- Added the following to the export
		- `Backbone`, `queryEngine`
	- Dependency updates
		- [bal-util](https://github.com/balupton/bal-util) from v1.10 to v1.12
		- [cson](https://github.com/bevry/cson) from v1.1 to v1.2

- v6.0.14 June 27, 2012
	- Configuration variables `documentPaths`, `filesPaths`, and `layoutsPaths` are now relative to the `srcPath` instead of the `rootPath`
		- `pluginsPaths` is still relative to the `rootPath`

- v6.0.13 June 27, 2012
	- Added `getFileModel`, `getFileUrl`, `getFile` template helpers

- v6.0.12 June 26, 2012
	- More robust node and git path handling
	- Dependency updates
		- [bal-util](https://github.com/balupton/bal-util) from v1.9 to v1.10

- v6.0.11 June 24, 2012
	- We now output that we are actually installing the skeleton, rather than just doing nothing
	- We now also always output the skeleton clone and instlalation progress to the user
	- Skeletons are now a backbone collection

- v6.0.10 June 22, 2012
	- Fixed CLI on certain setups

- v6.0.9 June 22, 2012
	- Many minor fixes and improvements
	- Available DocPad events are now exposed through `docpadInstance.getEvents()`
	- DocPad configuration is now exposed through `docpadInstance.getConfig()`
	- Removed `DocPad::getActionArgs` in favor of `balUtil.extractOptsAndCallback`
	- Configuration events now have a context that persists and do not pile up if configuration is reloaded
	- DocPad constructor now returns `err` and `docpadInstance` to the completion callback if it exists
	- Fixed a problem with grouped actions not completing under some circumstances
	- Will now watch configuration files for changes, if a change is detected, regenerate everything
	- Cleaned up the server action a bit
	- Added a new `serverExtend` event so listeners can now extend the server before the docpad routes are applied
	- Dependency updates
		- [watchr](https://github.com/bevry/watchr) from v2.0 to v2.1

- v6.0.8 June 21, 2012
	- Configuration changes
		- DocPad now checks the following paths for a configuration file `docpad.js`, `docpad.coffee`, `docpad.json`, `docpad.cson`, and will go with whichever one it finds first
			- If you use `coffee` or `js` extensions, remember to prefix your file with `module.exports =`
		- Fixed instance configuration not always coming first
		- Removed `configPath` configuration option. Use the array based `configPaths` instead.
		- `rootPath` and `configPaths` will now be properly respected if specified in your `package.json` file under the `docpad` property
		- Configuration files can now bind event handlers using the `events` hash
	- Event changes
		- Completion callbacks are now optional for event listeners, if omitted event listener will be treated as synchronous
		- Added new `docpadReady` event that fires once docpad has finished initializing and loading its configuration, will provide the opts `{docpad}` where `docpad` is the docpad instance
	- Server changes
		- If a document has multiple urls, and it is accessed on the non primary url, we will 301 (permanent) redirect to the primary url
	- Dependency updates
		- [bal-util](https://github.com/balupton/bal-util) from v1.8 to v1.9
		- [cson](https://github.com/bevry/cson) from v1.0 to v1.1

- v6.0.7 June 20, 2012
	- When watching files, and you modify a layout, docpad will now re-render anything using that layout - closes #242

- v6.0.6 June 19, 2012
	- Greatly simplified the event architecture
		- We now inherit from the simpler `balUtil.EventEmitterEnhanced` instead of `balUtil.EventSystem`, and have moved queue code into `balUtil.Group` as `docpadInstance.getRunner()`
		- Actions when called directly do not queue, they only queue when called through `docpadInstance.action`
	- `docpadinstance.loadConfiguration` is now an action called `load`
	- Fixed the run action not completing due to a missing callback

- v6.0.5 June 19, 2012
	- Updated QueryEngine from version 1.1 to 1.2
	- Fixed watch error when deleting files, or changing a directory

- v6.0.4 June 19, 2012
	- Fixed skeleton action

- v6.0.3 June 19, 2012
	- Fixed `server` action when used in combination with a custom server

- v6.0.2 June 11, 2012
	- Now fetches the DocPad v6 exchange file

- v6.0.1 June 11, 2012
	- Fixed plugin generation tests

- v6.0.0 June 11, 2012
	- Breaking changes that may affect you
		- Removed `documentsPath`, `filesPath`, `layoutsPath` configuration options for their array based alternatives `documentsPaths`, `filesPaths`, `layoutsPaths`
		- Removed `require` from `templateData` as it needs to be specified in your project otherwise it has the wrong paths
		- Removed `database`, `collections`, `blocks` from `templateData` for their helper based alternatives `getDatabase()`, `getCollection('collectionName')`, `getBlock('blockName')`
		- Removed `String::startsWith`, `String::finsihesWith`, `Array::hasCount`, `Array::has` as we never used them
		- Removed `DocPad::documents` and `templateData.documents`, now use `getCollection('documents')`
	- New features
		- Differential rendering
		- Extendable CLI
		- Template helpers
	- Other changes
		- Better error handling
		- Moved to Joe for unit testing

- v5.2.5 May 18, 2012
	- Fixed layout selection when two layout's share similar names - Closes [#227](https://github.com/bevry/docpad/issues/227)

- v5.2.4 May 18, 2012
	- Upgraded chai dev dependency from 0.5.x to 1.0.x
	- Fixed a dereferencing issue
	- Plugin testers will now run the `install` and `clean` actions when creating the DocPad instance

- v5.2.3 May 18, 2012
	- DocPad will no longer try and use a skeleton inside a non-empty directory
	- DocPad will now only include the CoffeeScript runtime if needed (for loading CoffeeScript plugins)

- v5.2.2 May 17, 2012
	- Fixed [#208](https://github.com/bevry/docpad/issues/208) - Multiple file extensions being trimmed
	- Fixed [#205](https://github.com/bevry/docpad/issues/205) - Name collisions are causing not all files to be copied
	- Changed file `id` to default to the `relativePath` instead of the `relativeBase`
	- Finding layouts now uses `id: $startsWith: layoutId` instead of `id: layoutId`

- v5.2.1 May 8, 2012
	- Fixed a complication that prevents `src/public` from being written to `out`
		- Added automated regression tests to ensure this will never happen again
	- Added `documentsPaths`, `filesPaths`, and `layoutsPaths` configuration variables
	- Simplified model code
	- Cleaned up some async code

- v5.2.0 May 4, 2012
	- We now pre-compile our CoffeeScript
	- Added the ability to specify a `docpad.cson` configuration file inside your website
		- This file will also be watched for changes, and if a change is made, we'll reload it and regenerate :)
	- Database/Collections have been cleaned up
		- files, layouts and documents are all added to the database
		- documents and layouts are represented by the `Document` model which extends the `File` model
		- files are represented by the `File` model
		- documents are accessible via the `collections.documents` which is a live child collection of database
		- files are accessible via the `collections.files` which is a live child collection of database
		- layouts are accessible via the `collections.layouts` which is a live child collection of database
	- You can create your own live child collections by specifying them in your configuration file, e.g. add this to your `docpad.cson` file:
		``` coffee
		# Collections
		collections:
			pages: (database) ->
				database.findAll(pageOrder: $exists: true)
			posts: (database) ->
				database.findAll(tags: $has: 'post')
		```
	- Templates now have access to a new function called `include`. It will include the renderedContent (or if unavilable to content) of the file. In eco, you would use it like this: `<%- @include('filename.ext1.ext2.ext3') %>`
	- Blocks are now Collections too! You can call `.add` on them, and use `.toHTML()` to grab them as HTML (`.join` will do the same thing for b/c)
	- This should be a completely backwards compatible release, let us know if you any issues on the

- v5.1.2 April 26, 2012
	- Fixed some UTF8 encoded files from being detected as binary
	- Fixed documents with no extension being outputted with an undefined extension

- v5.1.0-5.1.1 April 25, 2012
	- Fixed EventEmitter warning
	- Binary files can now be placed within the `src/documents` directory
	- Removed eyes devDependency
	- Models now use CoffeeScript's class extend, instead of Backbone's extend

- v5.0.5 April 14, 2012
	- Added `.npmignore` file
	- Added `document.contentType` and `document.contentTypeRendered`
	- Fixed `document.contentRendered` on files that do not have layouts
	- Added tests for:
		- Checking that `ignored: true` documents are properly ignored
		- That ignored common pattern files/dirs are properly ignored
		- That attributes are being applied properly

- v5.0.1-v5.0.4 April 14, 2012
	- Updated balUtil from 1.4 to 1.5
		- Fixes some scandir bugs
	- Updated watchr from 1.0 to 2.0
		- This should make watching re-generation a lot faster
	- Added a warning if you have no plugins loaded and are trying to do a generate
	- Fixed ignored check on documents

- v5.0.0 April 14, 2012
	- Models are now [Backbone Models](http://documentcloud.github.com/backbone/#Model)
	- Upgraded [Query-Engine](https://github.com/bevry/query-engine) version from 0.6 to 1.1
	- Plugins are now managed by npm and are no longer bundled with DocPad
		- You will need to add them to your website's `package.json` and install them via `npm install docpad-plugin-#{pluginName}`
		- We now scan the `node_modules` and `plugins` directories of your website for docpad plugins
			- These paths can be customised via the `pluginsPaths` variable in the docpad configuration
		- DocPad detects if something is a plugin by checking for the `docpad-plugin` keyword in the `package.json` file, or if the file follows the `#{pluginName}.plugin.coffee` naming convention
	- CoffeeScript dependency is now bundled inside, instead of being an external dependency
	- A website's npm dependencies are now installed as part of the initialisation process
	- This is a big backwards compatibility break, previous skeletons and plugins need to upgraded
		- Refer to the [Upgrade Guide](https://github.com/bevry/docpad/wiki/Upgrading) for instructions

- v4.1.1 April 9, 2012
	- Fixed DocPad from outputting `undefined` instead the layout's name which it could not find
		- Thanks to [Changwoo Park](https://github.com/pismute) for the [fix](https://github.com/bevry/docpad/pull/173), and [https://github.com/msutherl](Mogran Sutherland) for the [report](https://github.com/bevry/docpad/issues/172)

- v4.1.0 April 6, 2012
	- [Feedr Plugin](https://github.com/bevry/docpad/tree/master/lib/exchange/plugins/feedr) now exposes `@feedr.feeds` to the `templateData` instead of `@feeds`
	- Exchange data now moved to the [docpad-extras](https://github.com/bevry/docpad-extras) repository
	- Fixed broken `balupton.docpad` skeleton repo url

- v4.0.0-4.0.3 April 6, 2012
	- Added support for partials, with the new [Partials Plugin](https://github.com/bevry/docpad/tree/master/lib/exchange/plugins/partials)
	- Added support for caching remote assets, with the new [Cachr Plugin](https://github.com/bevry/docpad/tree/master/lib/exchange/plugins/cachr)
	- Added support for caching and parsing remote feeds, with the new [Feedr Plugin](https://github.com/bevry/docpad/tree/master/lib/exchange/plugins/feedr)
	- Added support for independent plugin unit tests
	- Added support for specifying `templateData` for the docpad configuration
	- Skeletons are no longer cached
		- Caching skeletons was causing far too many problems
	- Will now always use the local npm installation
	- Added `gitPath` and `nodePath` to docpad configuration
	- Split a document's `title` into `title` and `name`
		- Use `title` for page titles (e.g. `<title>page title</title>`)
		- Use `name` for navigation listings
		- This was introduced as sometimes you want a different title for your page title, than for your navigation page names
	- Cleaned up the plugin event system
		- Got rid of `triggerPluginEvent` and now we use [balUtil's](https://github.com/balupton/bal-util.npm) [emitSync](https://github.com/balupton/bal-util.npm/blob/master/lib/events.coffee#L257) and [emitAsync](https://github.com/balupton/bal-util.npm/blob/master/lib/events.coffee#L241)
		- This for the time being, also remove the use of plugin priorities. We suggest keeping your priorities in there, in the case that we re-introduce the functionality in the future.
	- When an error occurs we will send an error report back to DocPad using [AirBrake](http://airbrake.io/)
		- To turn this off, set `reportErrors` in your docpad configuration to `false`
	- Files, Documents, Layouts and Partials are now proper "models" and are now found in the `lib/models` directory
	- Moved out some unstable or not as popular plugins to the [docpad-extras](https://github.com/bevry/docpad-extras) repository, plugins moved are:
		- Admin
		- Authenticate
		- AutoUpdate
		- Buildr
		- HTML2Jade
		- Move
		- PHP
		- REST
		- Roy
		- Ruby

- v3.3.2 March 18, 2012
	- Fixed missing interpolation on new version notification
	- Fixed the scandir error with the skeletons path when doing the first run on windows
	- Updated paths to use `path.join` instead of always using forward slashes

- v3.3.1 March 18, 2012
	- Fixed Pygments plugin highlighting the code multiple times for documents with layouts
	- Added `isLayout` and `isDocument` flags to `Document` and `Layout` prototypes

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

- v3.2.0-3.2.7 February 15, 2012
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


