# History

## v6.78.4 September 16, 2015
- Fixed `path option is deprecated` error when cloning a skeleton
	- Thanks to [Gabriel Ignisca](https://github.com/16nsk) for [issue #1016](https://github.com/docpad/docpad/issues/1016)
- Changed donation message, maybe this one will be more successful
- The next x.X.x release of DocPad will drop support for Node v0.10, Node v4.0.0 is out with many improvements. [Upgrade.](https://learn.bevry.me/node/install)
- Updated dev dependencies
- Updated base files

## v6.78.3 August 21, 2015
- Consolidated server address code
- DocPad will now output both the original server address and the simplified server address if they differ, background:
	- https://github.com/docpad/docpad/commit/2b9f567870f7b396e6b0f680a8aca92ea7bc45b6#commitcomment-12824451
	- https://github.com/docpad/docpad/issues/911

## v6.78.2 August 21, 2015
- Profilers must now be specified by `DOCPAD_PROFILER` variable
- Prevent waiting handles from being outputted in silent mode (prevents a common render test failure)
- Use [hostenv](https://github.com/bevry/hostenv) for `PORT` and `HOSTNAME` variables
- Listen to `0.0.0.0` hostname by default (will be outputted as `localhost`)
- Updated dependencies
- Updated base files

## v6.78.1 March 20, 2015
- Fixed `queryEngine` is undefined error (regression since v6.78.1)
	- Thanks to [wlbrough](https://github.com/wlbrough) for [issue #943](https://github.com/docpad/docpad/issues/943)

## v6.78.0 March 18, 2015
- You can now `module.exports = function(docpad){ return {/* your docpad configuration */} }`

## v6.77.1 March 18, 2015
- Better error reporting when a custom collection is invalid
	- Thanks to [Simon Smithies](https://github.com/simonsmithies) for [issue #875](https://github.com/docpad/docpad/issues/875)

## v6.77.0 March 18, 2015
- Replaced `lodash` with `underscore`
	- Backbone (our dependency) already includes `underscore`, so makes sense to reduce our footprint
- Removed these deprecated exports:
	- `require('docpad').DocPad`
	- `require('docpad').Backbone`
	- `require('docpad').queryEngine`
	- `docpadInstance.View`
- Added `progress` configuration option that you can use to disable progress bars

## v6.76.1 March 17, 2015
- Fixed testers wanting chai (regression since v6.76.0)

## v6.76.0 March 17, 2015
- Regenerate timer is now closed correctly (regression since v6.48.0)
- Close stdin after destroy when using the console interface
- Output anything we could be waiting for after destroy using the console interface
- Rather than including all of lodash, we now just include the modules we need
- Updated profiling for the latest tools
- Quicker execution of certain spawned commands
- Updated dependencies

## v6.75.2 March 16, 2015
- Better error handling when updating user config fails
- Better error messages when CSON handling fails

## v6.75.1 March 16, 2015
- Better input availability detection

## v6.75.0 March 16, 2015
- Better CSON config and meta parsing
- Updated dependencies

## v6.74.0 March 14, 2015
- Updated for latest exchange and docpad package info retrieval
- Fixed `--profile`
	- Thanks to [Zearin](https://github.com/Zearin), [fengtingzhang](https://github.com/fengtingzhang) for [issue #937](https://github.com/docpad/docpad/issues/937)
- Fixed `--skeleton` option not working
	- Fixes [issue #942](https://github.com/docpad/docpad/issues/942)
- Removed `skeleton` command, use the `init` or `run` commands instead
- Removed `engines` from `init`'s `package.json`
- Updated dependencies
- Updated most dependencies from `~` to `^`
- Released live: https://plus.google.com/events/cc41smt4r608vj8fdrjp7a1jqbg

## v6.73.5 February 23, 2015
- Fixed `TypeError: undefined is not a function` under some circumstances
	- Thanks to [Dimitar Kolev-Dick](https://github.com/dimitarkolev) and [Lisa Williams](https://github.com/Lisa-Williams) for [issue #935](https://github.com/docpad/docpad/issues/935)

## v6.73.4 February 23, 2015
- Only display prompts and check for updates when we are in an interactive terminal by default

## v6.73.3 February 23, 2015
- Improved debugging of TaskGroups
- Fixed crash when MAC was not available (regression since v6.72.0)
	- Fixes Travis CI problems, hopefully fixes Heroku Problems
- Fixed changed log level configuration not applying in subsequent configuration updates (regression since always?)
	- Fixes warnings appearing in CLI render commands (regression since always?)
- Better `create` and `createInstance` methods (inspired from TaskGroup's)
- Better expectation tests that now show differences
- Fixed CLI tests using old DocPad (they now use `--global` flag) (regression since always?)
- Updated dependencies

## v6.73.2 February 20, 2015
- If an error occurs during the initialisation actions, DocPad will only suicide if there was no completion callback to handle the error
- More robust way of writing errors in case `stderr` doesn't exist or isn't writeable

## v6.73.1 February 20, 2015
- Fixed DocPad creation via API returning `2` (regression since v6.71.0)
	- For some reason, having `DocPad::inspect` defined broke it, as such `DocPad::inspect` is now `DocPad::inspector`
- Fixed double binding of some prototype methods
- Simpler `DocPad.create` and `DocPad.createInstance` functions
- The `--no-color` option now works (introduced in v6.71.0)

## v6.73.0 February 20, 2015
- Got rid of the `main.coffee`/`main.js` file, our new main file is the DocPad class itself `lib/docpad`
- Updated dependencies

## v6.72.1 February 20, 2015
- Fixed possibility of DocPad not exiting on exiting on a error
- More robust error writing
- jshint compliance

## v6.72.0 February 20, 2015
- Fixed fetching of skeletons (regression since v6.70.0)
	- Thanks to [Kasper Souren](https://github.com/guaka) for [issue #930](https://github.com/docpad/docpad/issues/930)
- Added the ability to uncompiled warn warnings off for private plugins by setting `warnUncompiledPrivatePlugins` to `false`
	- Thanks to [Dimitar Kolev-Dick](https://github.com/dimitarkolev) for [issue #928](https://github.com/docpad/docpad/issues/928)
- Added better warnings when loading a plugin fails for whatever reason
- Better reporting of warnings
- coffeelint compliance
- Updated dependencies

## v6.71.1 February 19, 2015
- Output `127.0.0.1` as the hostname when IPv6 addresses `::` and `::1` are reported
- Output `127.0.0.1` as the hostname instead of `localhost` when `0.0.0.0` is reported

## v6.71.0 February 19, 2015
- Updated `docpad-debug` to work with latest debugging tools
- DocPad will now output most things with colours when it is able to
	- Thanks to [Zearin](https://github.com/Zearin) for [pull request #834](https://github.com/docpad/docpad/pull/834)
- Fixed `TypeError: Object #<CSON> has no method 'parseCSON'` error when parsing user configuration (regression from v6.70.0)
	- Thanks to [Kasper Souren](https://github.com/guaka) for [pull request #921](https://github.com/docpad/docpad/issues/921) and [issue #917](https://github.com/docpad/docpad/issues/917)
- Fixed secondary URL redirect
	- Thanks to [shawnzhu](https://github.com/shawnzhu) for [pull request #905](https://github.com/docpad/docpad/pull/905) and [issue #850](https://github.com/docpad/docpad/issues/850)
- Fixed incorrect writing of user configuration (regression from v6.70.0)
	- Thanks to [Pavan Gupta](https://github.com/pavangupta) for [pull request #922](https://github.com/docpad/docpad/pull/922)
- Re-added support for uncompiled plugins (regression from v6.70.0)
	- Thanks to [Zeno Rocha](https://github.com/zenorocha) for [issue #918](https://github.com/docpad/docpad/issues/918)
- When an error occurs with the `docpad.action` API and a completion callback is specified, the error will no longer be logged
- Fixed reporting of errors when something goes wrong when initialising a selected skeleton
- Fixed potential crash under random circumstances caused by 3rd party dependency
	- Also removed the [longjohn] package as a precaution for when caterpillar can't fix the issue
	- More information on [issue #926](https://github.com/docpad/docpad/issues/926)

## v6.70.1 February 12, 2015
- We now output `localhost` instead of `0.0.0.0`
	- Thanks to [paleite](https://github.com/paleite) and [Stephen Brown II](https://github.com/StephenBrown2) for [issue #911](https://github.com/docpad/docpad/issues/911)

## v6.70.0 February 12, 2015
- Node 0.12 and io.js support
- CSON has been updated to v2, this means that your `docpad.cson` files will no longer work with functions
	- If you have functions inside your `docpad.cson` file:
		- Rename `docpad.cson` to `docpad.coffee`
		- Export your configuration inside `docpad.coffee` by doing: `module.exports = {your configuration data}`
		- [Example `docpad.coffee` file.](https://docpad.org/docs/config)
- Updated dependencies

## v6.69.2 December 17, 2014
- Better id deletion when cloning a model
	- Thanks to [Nathan Friedly](https://github.com/nfriedly) for [pull request #893](https://github.com/docpad/docpad/pull/893)
- Fixed incorrect `layoutSelector` undefined error when DocPad can't find your layout
	- Thanks to [Nathan Friedly](https://github.com/nfriedly) for [pull request #897](https://github.com/docpad/docpad/pull/897)
- Updated dependencies

## v6.69.1 September 18, 2014
- Fixed a TOS issue
	- Thanks to [plfannery](https://github.com/pflannery) for [pull request #884](https://github.com/docpad/docpad/pull/884)
- Updated dependencies

## v6.69.0 June 16, 2014
- Updated dependencies

## v6.68.1 June 5, 2014
- [longjohn](https://github.com/mattinsler/longjohn) is now an optional dependency, as for some people it was not loading, also made it use ~ instead of ^ as maybe those users are using old npm versions

## v6.68.0 June 1, 2014
- File and document messages are now localised
- Better error messages when parsing the meta data fails
- Will now output an error when a document or file model was instantiated outside of `docpad.createModel` as instantiating directly will mean they will be missing necessary properties and events

## v6.67.0 June 1, 2014
- We now output the link to the bug report guide with error messages
- We now include [longjohn](https://github.com/mattinsler/longjohn) in debug mode for better stack traces

## v6.66.0 May 23, 2014
- Meta header separators can now contain additional characters, providing there is still a character that repeats at least 3 times

	This allows you to do things like:

	```
	/* ---
	works: "yes"
	--- */

	window.alert("<%- @document.works %>")
	```

	Or even more concisely:

	```
	/***
	works: "yes"
	***/

	window.alert("<%- @document.works %>")
	```

	Big thanks to [pflannery](https://github.com/pflannery) for pushing for this with [#814](https://github.com/bevry/docpad/pull/814)


## v6.65.0 May 17, 2014
- Independent rendering (including layout rendering) now occurs on a clone, allowing independent renderings on the same file to occur at the same time
	- This fixes an issue where a recursive render on a file will cause a stalemate
- More detailed errors when something goes wrong with rendering a file
- Deprecated `docpad.cloneModel(document)`, you can now use `document.clone()` safely
- Deprecated `apply` option for `document.render`, now use `document.clone().action('render')` instead
- Fixed broken `docpad.addModel` and `docpad.addModels` (broken since their introduction in v6.55.0)
- Updated dependencies


## v6.64.3 May 4, 2014
- Added donation plea for [bevry/meta#3](http://github.com/bevry/meta/issues/3)


## v6.64.2 April 21, 2014
- Updated dependencies


## v6.64.1 April 21, 2014
- Fixed cache file not being correctly (regression since v6.63.7)
	- Thanks to [Ivan Klimchuk](https://github.com/Alroniks) for [pull request #825](https://github.com/bevry/docpad/pull/825)


## v6.64.0 March 4, 2014
- Fixed a possible issue with `@include` template helper not working when the `renderPasses` config option changes
- DocPad will now auto-set the `site.url` template data to the calculated site URL (e.g. `http://localhost:9778`) if it is falsey
	- This allows you to do `environments: development: templateData: site: url: false` inside your DocPad configuration files, to always use the correct site url regardless of environment


## v6.63.8 February 26, 2014
- Fixed "Object #<DocPad> has no method err" (regression since v6.37.7)


## v6.63.7 February 21, 2014
- Fixed IE9 and below not understanding the charset we send
	- Thanks to [Eric Vantillard](https://github.com/evantill) for [issue #801](https://github.com/bevry/docpad/pull/801)
- Better debugging for invalid watch states
	- For more information see [issue #792](https://github.com/bevry/docpad/issues/792)
- Fixed DocPad failing to serve files after the initial generation once the docpad configuration file has been modified
	- Thanks to [Michael Williams](https://github.com/ahdinosaur) for [issue #811](https://github.com/bevry/docpad/issues/811)
- Updated dependencies


## v6.63.6 February 18, 2014
- Fixed npm v1.4.3 from using `^` instead of `~` when installing and updating docpad plugins


## v6.63.5 February 18, 2014
- Fixed invalid TaskGroup `~3.3.7n` dependency version (regression since v6.63.1)
	- Thanks to [Jens Wilke](https://github.com/cruftex) for [issue #806](https://github.com/bevry/docpad/issues/806)


## v6.63.4 February 18, 2014
- Don't use HTTPS URLs for fetching latest version and exchange data (as HTTPS URLs may not always be available)
- Updated dependencies


## v6.63.3 January 30, 2014
- Regenerate every options are now customisable via `regenerateEveryOptions`
- Regenerate every options now default to `partial:false, populate:true`
	- Before there were no defaults, meaning that they always did a non populating, partial, regeneration (regression exposed due to the fix in v6.61.0)


## v6.63.2 January 30, 2014
- Don't show generate success message if an error occurred


## v6.63.1 January 30, 2014
- Fixed gobbling of error messages during `contextualizeFiles`, `renderFiles` or `writeFiles` (regression since v6.59.2)
	- Thanks to [Rob Loach](https://github.com/RobLoach), [Nathan Rijksen](https://github.com/Naatan) for [issue #784](https://github.com/bevry/docpad/issues/784)
- All task groups and tasks we define are now named (makes for easier debugging)
- Updated dependencies


## v6.63.0 January 28, 2014
- Disabled database writing by default (set `databaseCache` to `false` instead of `'write"` by default)
	- We never used it, still many nuances with reading to figure out, so it doesn't make sense incurring the performance penalty of the write while there is no use for it
	- Enable writing manually by setting `databaseCache` to `"write"`
	- Enable writing and reading manually by setting `databaseCache` to `true`


## v6.62.0 January 28, 2014
- Stylesheets are more efficiently generated
	- Files with the `outExtension: 'css'` are now the only ones included in the `stylesheet` collection
	- Stylesheets no longer have `referencesOthers` to `true` on them by default, this is now left up to plugin authors to do
	- Thanks to [Dimitar Kolev-Dick](https://github.com/dimitarkolev) for [issue #789](https://github.com/bevry/docpad/issues/789)


## v6.61.0 January 27, 2014
- Fixed regeneration always regenerating everything (regression since v6.58.0)
	- Thanks to [Dimitar Kolev-Dick](https://github.com/dimitarkolev), [Marcus Stong](https://github.com/stongo) for [issue #785](https://github.com/bevry/docpad/issues/785)


## v6.60.4 January 27, 2014
- Implemented `304 Not Modified` header
- Fixed some `date` and `stat` errors (regression since v6.60.0)
	- Thanks to [Anton Wilhelm](https://github.com/timaschew) for [pull request #787](https://github.com/bevry/docpad/pull/787)
	- Thanks to [Ivan Klimchuk](https://github.com/Alroniks) for [pull request #781](https://github.com/bevry/docpad/pull/781)


## v6.60.3 January 16, 2014
- Fixed `toUTCString` errors (regression since v6.60.0)


## v6.60.2 January 16, 2014
- Don't include `--save-dev` when installing plugins (regression since v6.59.3)


## v6.60.1 January 16, 2014
- Updated dependencies


## v6.60.0 January 16, 2014
- Added `etag`, `cache-control`, `last-modified`, `date`, and `charset` headers
	- Thanks to [Marcus Stong](https://github.com/stongo) for [issue #740](https://github.com/bevry/docpad/issues/740)


## v6.59.6 December 20, 2013
- Non-CoffeeScript plugin testers can now rejoice, you can now easily extend the tester classes by using `TesterClass.extend({})`
	- Thanks to the [extendonclass](https://github.com/bevry/extendonclass) module


## v6.59.5 December 20, 2013
- Non-CoffeeScript plugin authors can now rejoice, you can now easily extend the `BasePlugin` class by using `var MyPlugin = BasePlugin.extend({})`
	- Thanks to the [extendonclass](https://github.com/bevry/extendonclass) module


## v6.59.4 December 20, 2013
- Added a warning when trying to set the `id` attribute manually
	- Thanks to [Piotr Zduniak](https://github.com/pzduniak) for [issue #742](https://github.com/bevry/docpad/issues/742)


## v6.59.3 December 20, 2013
- Fixed uninstalled dev dependency plugins (e.g. livereload), from being reinstalled on the next install
	- Thanks to [Alan Languirand](https://github.com/alanguir), [Eduán Lávaque](https://github.com/Greduan) for [issue #744](https://github.com/bevry/docpad/issues/744)


## v6.59.2 December 19, 2013
- More reliable delay of requests while the initial generation is still performing
- Removed the deprecated `writeSource` meta data header, `writeSource` is now only available via the API usage
- Added new `generated` event that will fire once the initial generation has completed


## v6.59.1 December 19, 2013
- Fixed listening on heroku (regression since v6.58.2)


## v6.59.0 December 19, 2013
- Removed the deprecated `ensureFile`, `ensureDocument`, `ensureModel`/`ensureFileOrDocument` methods, use `addFile`, `addDocument`, and `addModel` instead
- Improved watching, should hopefully fix [#738](https://github.com/bevry/docpad/issues/738), [#742](https://github.com/bevry/docpad/issues/742), [#739](https://github.com/bevry/docpad/issues/739)
- Updated dependencies


## v6.58.2 December 18, 2013
- Can now change the hostname that we listen to via the `hostname` configuration option
	- Thanks to [Dario](https://github.com/radiodario) for [pull request #737](https://github.com/bevry/docpad/pull/737)
- Updated dependencies


## v6.58.1 December 17, 2013
- Output of change detections is now an `info` log level, instead of `debug`, allowing you to see what is going on by default
- Fixed regenerations triggered by changed files not working (regression since v6.58.0)
	- Thanks to [Fryderyk Dziarmagowski](https://github.com/freddix), [Anton Poleshchuk](https://github.com/apoleshchuk), [Eduán Lávaque](https://github.com/Greduan) for [issue #738](https://github.com/bevry/docpad/issues/738)


## v6.58.0 December 16, 2013
- Deprecated and removed the `parseBefore` and `parseAfter` events
	- Files are now parsed as they are loaded in, rather than only when they reach the generation cycle
	- See [issue #736](https://github.com/bevry/docpad/issues/736) for discussion and upgrade options
- Dynamic documents now have access to templateData that plugins have extended (regression since always)
	- Dynamic documents now go through the standard generation process
	- Thanks to [Steve McArthur](https://github.com/SteveMcArthur), [Marcus Stong](https://github.com/stongo) for [docpad/docpad-plugin-feedr#5](https://github.com/docpad/docpad-plugin-feedr/issues/5)
- Documents that want to be rendered, but not written, are now rendered (possible regression since v6.55.0)
	- Thanks to [pflannery](https://github.com/pflannery) for [issue #734](https://github.com/bevry/docpad/issues/734)
- Moved the missing layout error check from contextualize step to render step, as the layout may not be there if we are still loading documents


## v6.57.3 December 16, 2013
- Contextualize will now also be called during a file's `load` action to help injected files being contextualized


## v6.57.2 December 12, 2013
- Updated dependencies


## v6.57.1 December 9, 2013
- Fixed delay of requests not working when documents are still performing their initial generation (regression since v6.57.0)


## v6.57.0 December 3, 2013
- Improved the caching of on-the-fly collections and fixed the name setting of collections
	- Possible b/c break: `DocPad::getCollections()` will now return an `[collection, ...]` array, rather than an `{name: collection}` object. To get the name of a collection, you should now do `collection.options.name`


## v6.56.0 November 29, 2013
- The database cache introduced in v6.55.0 is set to `write` (write-only) by default now until we fix out the kinks
	- To enable read mode, use the `--cache` command line option when running DocPad, or set the `databaseCache` configuration option to `true`


## v6.55.9 November 29, 2013
- Properly fixed v6.55.3 issue while maintaining node.js v0.8 compatibility
	- Thanks to [Michael Duane Mooring](https://github.com/mikeumus), [pflannery](https://github.com/pflannery) for [issue #717](https://github.com/bevry/docpad/issues/717)


## v6.55.8 November 28, 2013
- Fixed Node.js v0.8 compatibility (regression since v6.55.3)


## v6.55.7 November 28, 2013
- ??? was already published...


## v6.55.6 November 28, 2013
- Output a huge warning banner when running DocPad against an unstable version of Node.js


## v6.55.5 November 27, 2013
- Fixed `Configuration changes require a `docpad clean` to regenerate files ` (regression since v6.55.0)
	- Thanks to [Christo Buschek](https://github.com/crito) for [issue #718](https://github.com/bevry/docpad/issues/718)


## v6.55.4 November 27, 2013
- Fixed `Offline changes to layout do not re-render the layout's children` (regression since v6.55.0)
- Removed `layoutId` internal file attribute in favour of new `layoutRelativePath` internal file attribute
- Added `hasLayout` special collection
- `docpad update` will now also perform `docpad clean` for you to ensure the database cache is cleaned between versions


## v6.55.3 November 27, 2013
- Fixed possible "(node) warning: Recursive process.nextTick detected. This will break in the next version of node. Please use setImmediate for recursive deferral." error under certain circumstances (regression since always?)
	- Thanks to [Michael Duane Mooring](https://github.com/mikeumus) for [issue #717](https://github.com/bevry/docpad/issues/717)


## v6.55.2 November 27, 2013
- Fixed `Changes to layout do not re-render the layout's children` (regression since v6.55.0)
	- Thanks to [Urs Hunkler](https://github.com/uhunkler) for [issue #716](https://github.com/bevry/docpad/issues/716)


## v6.55.1 November 26, 2013
- Fixed `databaseCache` config property (introduced in v6.55.0)


## v6.55.0 November 26, 2013
- DocPad will now cache the database to `.docpad.db` after generation, and load it up upon initial generation
	- This removes the huge performance burden of the initial scan, load, parse, render
	- The `writeSource` attribute can now be considered under review for deprecation
	- This can be turned off by setting the configuration option `databaseCache` to `false`
	- You can customise the path of the database cache file via the `databaseCachePath` configuration option
	- The database cache will be cleared on `docpad clean`
	- NOTE: If you remove files when DocPad is shut down, DocPad will not pick it up the changes, to fix do one of the following:
		- Run `docpad clean` to reset the database cache
		- Disable the database cache by setting the `databaseCache` configuration option to `false`
		- Or just make sure when you are working on your DocPad site, you have `docpad run` running
		- This potential problem is planned on being fixed in a later version, for now an immediate release with these huge performance gains far outweigh a delayed release with the fix
- DocPad will now only re-render things that have explicitly changed or not been written yet
	- This removes a huge performance burden when pulling in virtual documents
	- To use this when importing documents, make sure you set the `mtime` attribute
- Added `--silent` option that sets `prompts: false` for disabling all prompts
	- Removed `-s` option that was an alias for `--skeleton` to avoid confusion
	- Thanks to [Christo Buschek](https://github.com/crito) for [issue #715](https://github.com/bevry/docpad/issues/715)
- The following changes have been made to the `DocPad` prototype
	- `addModel(model, opts)` was added
	- `addModels(models, opts)` was added
	- `createModels(models, opts)` was added
	- `ensureModel(model, opts)` is now the same as `createModel(model, opts)`
	- `generatePrepare`, `generateLoad`, `generateRender`, `generatePostpare`, `populateCollections` were consolidated into `generate(opts, next)`
- The following changes have been made to the events:
	- `generateBefore`, `populateCollectionsBefore`, `populateCollections`, `generateAfter` now receive the options: `initial`, `reset`, and `collection`
- The following changes have been made to the models:
	- `rtime` (render time), `wtime` (write time) attributes have been added
	- `date`, `mtime`, `ctime`, `rtime`, `wtime` attributes if set will always be Date instances
	- `action` method has been added
	- `load`, `parse`, `contextualize`, `render`, `write`, `writeSource` should now be called via `file.action('the action name', opts, next)` instead
- Updated dependencies


## v6.54.10 November 21, 2013
- Fixed `Cannot read property 'id' of undefined` error when adding nothing to a block
	- Thanks to [Māris Krivtežs](https://github.com/marisks), [Eduán Lávaque](https://github.com/Greduan), [Bruno Heridet](https://github.com/Delapouite), [pflannery](https://github.com/pflannery) for [issue #710](https://github.com/bevry/docpad/issues/710)
- Updated dependencies


## v6.54.9 November 19, 2013
- Fixed custom server configuration being ignored
	- Thanks to [andresberrios](https://github.com/andresberrios) for [issue #712](https://github.com/bevry/docpad/issues/712)


## v6.54.8 November 18, 2013
- Fixed `TypeError: Cannot read property 'encoding' of null`
	- Thanks to [Tony](https://github.com/Zearin), [Eduán Lávaque](https://github.com/Greduan) for [issue #711](https://github.com/bevry/docpad/issues/711)


## v6.54.7 November 17, 2013
- Fixed meta data not resetting correctly
	- Thanks to [Māris Krivtežs](https://github.com/marisks), [Eduán Lávaque](https://github.com/Greduan) for [issue #710](https://github.com/bevry/docpad/issues/710)
- Updated dependencies


## v6.54.6 November 13, 2013
- The `removeWhitespace` and `contentRemoveRegex` tester config options now make sense
	- They are now executed against the value we are comparing, rather than on all the values in serialised form
- `docpad install` will no longer update `git`, `http`, `https` and other remote dependencies
	- Thank to [pflannery](https://github.com/pflannery) for [pull request #701](https://github.com/bevry/docpad/issues/701)


## v6.54.5 November 7, 2013
- Fixed background task error reporting (regression since always???)
	- Fixes`RangeError: Maximum call stack size exceeded` errors
	- Fixes error reporting for failed partials
	- Error reports during renders will now always output the error message
	- Thanks to [Michael Duane Mooring](https://github.com/mikeumus), [pflannery](https://github.com/pflannery), [Nathan Friedly](https://github.com/nfriedly), [ofShard](https://github.com/ofShard) for [issue #692](https://github.com/bevry/docpad/issues/692)
- Fixed template helpers not being able to reference other template helpers
- Better debugging support due to name tasks and task groups
- Updated dependencies


## v6.54.4 November 1, 2013
- Much more detailed progress bars
- Updated dependencies


## v6.54.3 November 1, 2013
- Fix incorrect ` @latest` within `npm install docpad@6 @latest --save` when running `docpad update` and `docpad install`
	- You'll probably want to run `npm uninstall --save latest` to make sure that the incorrectly installed `latest` dependency is removed


## v6.54.2 October 30, 2013
- Fix plugin version check
	- Thanks to [unframework](https://github.com/unframework) for [pull request #690](https://github.com/bevry/docpad/pull/690)


## v6.54.1 October 28, 2013
- Fix `TypeError: Cannot read property 'stack' of undefined` error
	- Thanks to [pflannery](https://github.com/pflannery) and [Moritz Stefaner](https://github.com/MoritzStefaner) for [issue #686](https://github.com/bevry/docpad/issues/686)
- DocPad version information will now output the directory path of which DocPad instance is loaded
	- Thanks to [pflannery](https://github.com/pflannery) for [pull request #687](https://github.com/bevry/docpad/issues/687)


## v6.54.0 October 27, 2013
- Backwards compatibility change: Notifications are now handled by plugins instead of the core
	- So if you like notifications, you'll probably want to install the [growl plugin](https://github.com/Delapouite/docpad-plugin-growl)
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [pull request #605](https://github.com/bevry/docpad/pull/605)
- Backwards compatibility change: i18n support is now handled via the `encoding` and `iconvlite` dependencies instead of `iconv`
	- This enables windows support for i18n
	- Just like before, you turn on i18n abilities by setting the `detectEncoding` configuration option to `true` (still `false` by default)
	- Thanks to [Sim Jiason](https://github.com/Snger) and [Eduán Lávaque](https://github.com/Greduan) for [issue #627](https://github.com/bevry/docpad/issues/627)
- Added `renderCollectionBefore` and `renderCollectionAfter` events
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [pull request #608](https://github.com/bevry/docpad/pull/608)
- Fixed the `connect.multipart() will be removed in connect 3.0` warning
	- Replaced the `bodyParser` middleware with the `urlencoded` and `json` middlewares
- Added `404 Not Found` notices to the console
	- Thanks to [telekosmos](https://github.com/telekosmos), [Eduán Lávaque](https://github.com/Greduan) and [pflannery](https://github.com/pflannery) for [issue #677](https://github.com/bevry/docpad/issues/677)
- Updated dependencies


## v6.53.4 October 11, 2013
- Fixed DocPad version being undefined in some instances causing plugins to skip (regression since v6.53.3)


## v6.53.3 October 10, 2013
- No need to load in the DocPad `package.json` file each load
- We now output whether or not we are a global or local installation with `docpad --version`
	- Thanks to [Henrik Cederblad](https://github.com/hced) and [Eduán Lávaque](https://github.com/Greduan) for [issue #672](https://github.com/bevry/docpad/issues/672)


## v6.53.2 October 10, 2013
- Watching improvements
- Updated dependencies


## v6.53.1 October 1, 2013
- Fixed `ReferenceError: config is not defined` on subscribe (regression since v6.53.0)
	- Thanks to [Igor](https://github.com/Hohot) and [Alberto Leal](https://github.com/Dashed) for [issue #663](https://github.com/bevry/docpad/issues/663)
- Fixed autodetection of name and username (regression since v6.53.0)
- Updated dependencies


## v6.53.0 September 17, 2013
- Absolute paths should no longer end up joined when the configuration is reloaded
- Improved locale support
	- Can now merge locales together
- Fixes subscribe and tos metrics
	- We now load the user information within the `load` action, rather than inside the `ready` action
	- Closes [issue #623](https://github.com/bevry/docpad/issues/638)


## v6.52.2 September 16, 2013
- Possible fix for `Error: A task's completion callback has fired when the task was already in a completed state, this is unexpected` error
	- Thanks to [Ryan Fitzer](https://github.com/ryanfitzer) for [issue #643](https://github.com/bevry/docpad/issues/643) thanks to
	- Thanks to [drguildo](https://github.com/drguildo), [Evan Bovie](https://github.com/phaseOne), [Brandon Mason](https://github.com/bitmage), [ashyadav](https://github.com/ashyadav) for [issue #623](https://github.com/bevry/docpad/issues/623)
- Will now output the progress of `iconv` install if `detectEncoding` is true and `iconv` isn't installed
- Updated dependencies


## v6.52.1 September 8, 2013
- Fixed "structure already exists" errors after successful `docpad init` and `docpad skeleton` completion (regression since v6.51.0)
	- Thanks to [Eduán Lávaque](https://github.com/Greduan) for [issue #631](https://github.com/bevry/docpad/issues/631)
- Better errors when a skeleton fails via the global `docpad run`


## v6.52.0 September 8, 2013
- Pay more attention to getmac errors
- Ensure completion callback (when specified) is always fired for the `DocPad::error` and `DocPad::track` methods
- Fixed `DocPad::getBlocks` returning the DocPad instance instead of the blocks
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [pull request #612](https://github.com/bevry/docpad/pull/612)
- Added `DocPad::getIgnoreOpts` method to help clean up some code
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [pull request #611](https://github.com/bevry/docpad/pull/611)
- Removed all calls to `process.exit` by instead destroying DocPad properly causing an automatic shutdown if that is what is desired
- Fatal errors are now written to stderr instead of stdout
- Updated dependencies


## v6.51.6 August 30, 2013
- When using writeSource don't write the header if there is no meta data
- Added support for `writeSource: "once"`


## v6.51.5 August 30, 2013
- Fixed syntax errors in docpad configuration file not being reported correctly (regression since v6.49.0)
	- Thanks to [drguildo](https://github.com/drguildo) for [issue #623](https://github.com/bevry/docpad/issues/623)
- If a configuration file fails to load we will now tell you which one it was


## v6.51.4 August 29, 2013
- Fixed `TypeError: Cannot call method 'getLocale' of undefined` when destroying (regression since v6.49.0)


## v6.51.3 August 29, 2013
- Fixed `docpad uninstall <pluginName>` (feature introduced in v6.51.0)


## v6.51.2 August 29, 2013
- Fixed certain plugin tests that require skeleton initialisation (regression since v6.52.0)
- When using `--global` flag we won't kill the global instance when starting a skeleton


## v6.51.1 August 29, 2013
- Fixed `docpad upgrade`


## v6.51.0 August 29, 2013
- Better upgrade `docpad upgrade` and update `docpad update` experience
	- Thanks to [drguildo](https://github.com/drguildo) and [Eduan Lavaque](https://github.com/Greduan) for [issue #619](https://github.com/bevry/docpad/issues/619)
- DocPad will now run the local installation if it exists (avoid this by using the `--global` flag)
	- Thanks to [Eduan Lavaque](https://github.com/Greduan) and [flamingm0e](https://github.com/flamingm0e) for [issue #620](https://github.com/bevry/docpad/issues/620)
- Added the ability to uninstall plugins via `docpad uninstall <pluginName>`
- Updated dependencies


## v6.50.1 August 28, 2013
- Fixed validation of DocPad sites containing the powered by info
	- Thanks to [drguildo](https://github.com/drguildo) and [Eduan Lavaque](https://github.com/Greduan) for [issue #618](https://github.com/bevry/docpad/issues/618)


## v6.50.0 August 20, 2013
- Upgraded from commander v1.3 to v2 (removes commander prompts)
- We now use promptly for prompts
- Updated dependencies


## v6.49.2 August 20, 2013
- Fixed `File::deleteSource`
- Plugin tester will now try to init the plugin test directory if there are tests defined (useful for plugins which tests start from scratch)
- Updated dependencies


## v6.49.1 August 14, 2013
- `loadFiles` step is now properly reported in the progress bar
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [pull request #498](https://github.com/bevry/docpad/pull/598)


## v6.49.0 August 12, 2013
- DocPad will now shutdown and destroy itself more thoroughly
	- Thanks to [Ashton Williams](https://github.com/Ashton-W) for [issue #595](https://github.com/bevry/docpad/issues/595)
- Added the event `docpadDestroy` for plugins that are doing anything long-running so they can destroy themselves thoroughly too


## v6.48.1 August 9, 2013
- Fixed outputting filenames without an extension
	- Thanks to [Geert-Jan Brits](https://github.com/gebrits) for [issue #584](https://github.com/bevry/docpad/issues/584)


## v6.48.0 August 5, 2013
- Moved `regenerateEvery` timer into `generate` rather than `setConfig` to avoid action stacking
- DocPad will now warn you when your project's local DocPad version does not match the global version


## v6.47.0 July 31, 2013
- Added `FileModel::deleteSource`
- Added support for specifying inline content within the styles block
- Fixed `DocPad::parseFileDirectory`


## v6.46.5 July 28, 2013
- Fixed `ReferenceError: result is not defined` (bug since v6.46.4)
	- Thanks to [Anup Shinde](https://github.com/anupshinde) for [issue #573](https://github.com/bevry/docpad/issues/573)


## v6.46.4 July 27, 2013
- Fixes
	- Fixed virtual documents firing duplicated events
		- Plugins should now use `DocPad::cloneModel(model)` instead of `model.clone()` as the latter can't bind events correctly
	- Fixed `Object #<Model> has no method 'setDefaults'` error (bug since v6.46.3)
		- Moved `FileModel::setDefaults` back into `Base::setDefaults`
		- Thanks to [Jeff Barczewski](https://github.com/jeffbski) for [bevry/docpad-documentation#40](https://github.com/bevry/docpad-documentation/pull/40)
	- Fixed the 500 middleware not working
- Changes
	- The `documents` collection is now defined by `render:true, write:true` rather than being paths and `isDocument:true` based
	- The `files` collection is now defined by `render:false, write:true` rather than being paths and `isFile:true` based
	- The `html` collection now checks for `write:true` instead of `isDocument:true` or `isFile:true`
	- The `stylesheet` collection now checks for `write:true` instead of `isDocument:true` or `isFile:true`
- Additions
	- Added ability to do `getCollection('database')` to get the global database
	- Added naming to collections to easily identify which collection we are in when debugging
	- Added `render` alias for documents directory
	- Added `static` alias for files directory
	- Added logging for event emits
	- Re-added `DocPad::parseDocumentDirectory` and `parseFileDirectory` (removed from v6.46.0) which wraps around the new ways of doing things
	- Added `DocPad::createModel(attrs,opts)` and updated `DocPad::createDocument` and `DocPad::createFile` to use it
	- Added `DocPad::ensureModel(attrs,opts)` and updated `DocPad::ensureDocument`, `DocPad::ensurefile`, and `DocPad::ensureFileOrDocument` to use it
	- Added `DocPad::attachModelEvents(model)` to attach the required docpad events to a model


## v6.46.3 July 25, 2013
- Moved `Base::setDefaults` to `FileModel::setDefaults`
- Removed superfluous loading logging messages
	- Thanks to [Bruno Heridet](https://github.com/Delapouite) for [issue #316](https://github.com/bevry/docpad/issues/316)
- The attributes `parser`, `header`, `body`, and `content` are now set correctly to `null` instead of `undefined` if there is no data
- Correctly set meta attributes when also setting default attributes (bug since v6.42.2)
- Added support for `outPath`, `outDirPath` and `rootOutDirPath` to be null
- Added unit tests for virtual document loading
- Fixed `removeWhitespace` tester option default
- Added `contentRemoveRegex` tester option
- Fixed debug log lines always being `DocPad.log` (bug since always)


## v6.46.2 July 24, 2013
- Fixed regenerations not regenerating referencing documents (bug since v6.46.0)
	- Closes [issue #559](https://github.com/bevry/docpad/issues/559)
- Fixed documents not including the default attributes of files (bug since always)
- Corrected naming of `releativeOutBase` to `relativeOutBase` on file model defaults (introduced in v6.45.0)


## v6.46.1 July 23, 2013
- Added `populateCollectionsBefore` event


## v6.46.0 July 23, 2013
- Awesomeness for everyone
	- Added support for creating brand new virtual documents
	- File `data` will now just set the `buffer`
		- Removed `getData` and `setData` on models
	- Can now `docpad install` multiple plugins at once
	- Plugin loading will now validate the `peerDependencies` requirements along with the old `engines`
	- `docpad init` will now initialise to the complete docpad version and npm v1.3
	- You can now tell a file to update it's source file by setting `writeSource: true` in it's meta data
- Awesomeness for developers
	- We now _require_ all plugins to conform to the v2 for DocPad v6 standard, otherwise they will be skipped
		- This is to ensure compatibility with `docpad update` and `docpad install <plugin>` which are the new standards for installing plugins
	- `parseDirectory` will no longer:
		- load files, this is now handled by the generate process instead
		- add files to the database, this can be done via the completion callback or via passing over the collection the files should be added to: `parseDirectory({collection:docpad.getDatabase()})`
	- Removed `parseDocumentDirectory` use `parseDirectory({createFunction:docpad.createDocument})` instead
	- Removed `parseFileDirectory` use `parseDirectory({createFunction:docpad.createFile})` instead
	- `Document::writeRendered` removed as `File::write` will now write the output content
	- Added `File::writesource`
	- Added `PluginTester::getConfig()` and `PluginTester::getPlugin()`
- Updated dependencies


## v6.45.1 July 23, 2013
- Fix `safeps is not defined` error
	- Thanks to [Carlos Rodriguez](https://github.com/carlosrodriguez) for [issue #558](https://github.com/bevry/docpad/issues/558)


## v6.45.0 July 6, 2013
- New `docpad update` command to ensure that your local installations of DocPad and its plugins are up to date with their latest compatible version
- `docpad install [plugin]` command now installs the latest compatible version
- Added [NodeFly](http://nodefly.com/) support when using the `--profile` flag


## v6.44.0 July 2, 2013
- Model Improvements
	- Way better support for virtual documents (files that do not have a physical path)
	- Cleaned up and fortified the normalization and contextualize procedures
	- At least one of these file attributes must be specified: `filename`, `relativePath`, `fullPath`
		- `relativePath` if not set will default to `fullPath` or `filename`
		- `filename` if not set will default to the filename of `fullPath` or `relativePath`
		- `fullPath` will not default to anything, as it is now optional (providing better support for virtual documents)
	- The following file attributes are auto set but can be over-ridden by custom meta data: `date`, `name`, `slug`, `url`, `contentType`, `outContentType`, `outFilename`, `outExtension`, `outPath`
	- The following file attributes are forcefully auto set: `extensions`, `extension`, `basename`, `outBasename`, `relativeOutPath`, `relativeDirPath`, `relativeOutDirPath`, `relativeBase`, `relativeOutBase`, `outDirPath`
	- Added these new file attributes: `outBasename`, `relativeOutBase`, `fullDirPath`
	- Updated a lot of log messages to support virtual documents
	- `buffer` is now correctly set as a File option
	- `File::setMeta(attrs)` can now accept meta backbone models instead of just javascript objects
	- File and Document methods now use [extract-opts](https://github.com/bevry/extract-opts) for their arguments just like DocPad already does
	- Removed the incorrect dangling file attributes: `path` and `dirPath`
	- Added new `FileModel::clone` method for making a clone of the file, attributes, opts, events and all will be cloned
- Core Improvements
	- Added `getFileById(id, opts={})` template helper and docpad class method
	- Plugins can now alter the load, contextualize, render, and write collections
	- Added a new `lib/util` file for containing misc functions
	- Added `DocPad::destroy()` method for shutting down the server and whatnot
		- Currently only shutdowns the server, we still need to add the rest of the things
- Testing Improvements
	- RendererTester is now more helpful when comparing differences between outputs
	- DocPad tests now use the new docpad destroy method that allows graceful shutdown rather than the previous ungraceful `process.exit(0)`
		- Still needs to be applied to plugin tests


## v6.43.2 June 30, 2013
- Fixed `locale is not defined` error when running `docpad init` on an existing website


## v6.43.1 June 29, 2013
- Fixed `docpad init` config error


## v6.43.0 June 29, 2013
- Huge improvements to the skeleton install process
	- Install process is much more reliable
	- Skeleton dependencies will now install correctly if `node_modules` already exists
	- Missing module errors when doing an initial clone of a skeleton should now be fixed
	- Removed the unused and non-working `-s, --skeleton` option
- Activities that wait on remote activity will now output a please wait message
- You can now install plugins via the `docpad install [pluginName]` command
	- Thanks to [Jarvis Ao Ieong](https://github.com/kinua) for [issue #539](https://github.com/bevry/docpad/issues/539)
- Installing dependencies via the `docpad install` command now works again
- The `-f, --force` flag now works as expected (enabling the npm `--force` flag)
- Fixed an issue with arrays not being dereferenced correctly in configuration
	- This fixes initial run issues with skeletons that have custom file structures
- Added `--offline` flag that will help docpad run without an internet connection
- Added an interval timer to load, contextualize, render, and write actions to determine what files we are waiting on
- Dependency upgrades


## v6.42.3 June 26, 2013
- Swapped out synchronous file system calls for asynchronous ones
	- Closes [issue #538](https://github.com/bevry/docpad/issues/538)
- Fixed DocPad version number undefined in X-Powered-By response header
- Added the ability to turn off the X-Powered-By meta header by setting the `poweredByDocPad` to `false` in your configuration


## v6.42.2 June 25, 2013
- Fixed backslash and slash inconsistencies on windows in regards to searching
	- Thanks to [Hamish](https://github.com/HammyNZ) for [issue #533](https://github.com/bevry/docpad/issues/533)


## v6.42.1 June 25, 2013
- Fixed backslash and slash inconsistencies on windows in regards to urls
	- Thanks to [jhuntdog](https://github.com/jhuntdog) for [issue #518](https://github.com/bevry/docpad/issues/518)
- `docpad render` will no longer output warning levels


## v6.42.0 June 25, 2013
- Better lazy loading of modules
- Updated dependencies


## v6.41.0 June 25, 2013
- Made debugging, tracing, and profiling easier
	- Added `docpad-debug` for easy debugging
	- Added `docpad-trace` for easy tracing
	- Added `--profile` for easy profiling
	- See our [debug guide](http://docpad.org/docs/debug) for details


## v6.40.0 June 24, 2013
- Removed excessive dirname usage
- Updated dependencies


## v6.39.0 June 20, 2013
- Abstracted out the file fetching in `DocPad::serverMiddlewareRouter` into `DocPad::getFileByRoute(url, next)` for others to use in their custom routes
- Updated dependencies


## v6.38.1 June 7, 2013
- Fix compilation issue with CoffeeScript v1.6.3
- Updated dependencies


## v6.38.0 May 30, 2013
- Added `docpad init` action to initialize your directory with an empty docpad project


## v6.37.1 May 30, 2013
- Added scripts.start property to no-skeleton's package.json file


## v6.37.0 May 29, 2013
- Plugin tester file is now optional when specifying something like `testerClass: 'RendererTester'` inside your plugin test file
	- Closes [issue #487](https://github.com/bevry/docpad/issues/487)
- `enableUnlistedPlugins` is now set to `true` when running plugin tests (it was `false` before)
	- This allows us to remove the need for the plugin tester file for most situations


## v6.36.2 May 28, 2013
- You will now be warned if your custom collection is invalid
- Child collections will now be of the correct class type


## v6.36.1 May 28, 2013
- Fixed `TypeError: Object has no method 'unbindEvents'`


## v6.36.0 May 28, 2013
- Rewrote the error-reporting, analytics, newsletter, and identification handling
- Fixed a bug with the plugin version not being set on the plugin instance correctly


## v6.35.0 May 25, 2013
- We now respect plugin priorities again
	- Thanks to [Neil Taylor](https://github.com/neilbaylorrulez) for [pull request #511](https://github.com/bevry/docpad/pull/511)
	- Set plugin priorities by `priority: 500` or whatever in your plugin class
	- Set event specific priorities by `eventNamePriority: 500` or whatever in your plugin class
- Updated dependencies


## v6.34.2 May 13, 2013
- We now support `docpad run` on empty directories when offline
	- Before it would crash because it could not load the exchange data, now it will continue anyway
- Removed `cli-color` dependency
- Progress bar will now be destroyed when a notice or higher importance message is logged


## v6.34.1 May 9, 2013
- Fixed `ReferenceError: docpad is not defined`


## v6.34.0 May 8, 2013
- Now uses [envfile](https://github.com/bevry/envfile) for `.env` file parsing
- Fixed `TypeError: Cannot call method 'get' of undefined` error when using [minicms plugin](https://github.com/jeremyfa/docpad-plugin-minicms)
	- Closes [issue #501](https://github.com/bevry/docpad/issues/501) reported by [rleite](https://github.com/rleite)


## v6.33.0 May 6, 2013
- We now load the exchange file based on which DocPad version we are running
- Updated dependencies
	- [Caterpillar Human](https://github.com/bevry/caterpillar-human) v3.1 from v3.0


## v6.32.0 May 2, 2013
- Now uses [Caterpillar](https://github.com/bevry/caterpillar) v2
- We now write a `docpad-debug.log` file when running with the `-d` flag, submit this when you file a bug report :)
- Fixed colors not showing on custom Terminal color schemes
- Fixed a double progress bar issue when a log message occurs when the progress bar is being written
- Removed `setLogger()` instead you should do `getLogger()` and pipe the results to where you need
- Added `getLoggers()` to fetch all the different logger streams we are using, generally there are:
	- `logger` the stream we write log messages to
	- `console` the stream that is outputted to stdout
	- `debug` the stream that is outputted to the debug log file


## v6.31.6 April 26, 2013
- `X-Powered-By` now also includes the DocPad version number


## v6.31.5 April 26, 2013
- Progress bars now obey the `prompts` configuration option instead of v6.31.2 environment hack


## v6.31.4 April 25, 2013
- Fixed "ReferenceError: existingModel is not defined" when you have outPath conflicts


## v6.31.3 April 25, 2013
- Moved progress bar code into [bevry/progressbar](http://github.com/bevry/progressbar)
	- Fixes issues with progress bars on Ubuntu and Windows


## v6.31.2 April 25, 2013
- Do not show progress bars on production environments


## v6.31.1 April 25, 2013
- Fixed cannot get `length` of undefined error
- Added progress bar (instead of snores) for during generation when using the default log level (`6`)


## v6.31.0 April 24, 2013
- DocPad will now warn you when you have files of the same outPath
- File and Document IDs will now always be their `cid` (before they use to be their relativePath on occasion)
- Fuzzy searching no longer searches for the id
- Server is now able to serve cached pages while a non-initial generation is occurring
- We no longer replace tabs with 4 spaces for the content of files and documents (we still do it for YAML meta data headers on documents)
	- This means if you're a plugin developer, you may need to update your plugin's test's `out-expected` folder accordingly
		- If this is too difficult, we've added a `removeWhitespace` config option for your plugin tester, set it to `true`, [see here for usage](https://github.com/docpad/docpad-plugin-paged/blob/master/src/paged.tester.coffee)
- Change events will now fire when adding a url to a file
- URL cache index for serving files is now generated via change events, rather than after generation


## v6.30.5 April 23, 2013
- The no skeleton option will now create a `node_modules` directory, and `package.json` and `docpad.coffee` files


## v6.30.4 April 16, 2013
- Testing of plugins now works when the plugin directory is the full plugin name
	- Thanks to [Mark Groves](https://github.com/mgroves84) for [issue #485](https://github.com/bevry/docpad/issues/485)


## v6.30.3 April 10, 2013
- Updated dependencies


## v6.30.2 April 7, 2013
- Allow for empty `data` when injecting files into the database
	- Thanks to [Richard A](https://github.com/rantecki) for [pull request #454](https://github.com/bevry/docpad/pull/454)
- Fixed "No Skeleton" option not working (bug introduced in v6.30.0)
	- Thanks to [Adrian Olaru](https://github.com/adrianolaru) for [pull request #475](https://github.com/bevry/docpad/issues/475)


## v6.30.1 April 6, 2013
- Updated dependencies


## v6.30.0 April 5, 2013
- Progress on [issue #474](https://github.com/bevry/docpad/issues/474)
- `balUtil`, `chai`, `expect`, `assert`, `request` are no longer exposed to plugin testers, you'll need to include them yourself from now on
- Updated dependencies


## v6.29.0 April 1, 2013
- Progress on [issue #474](https://github.com/bevry/docpad/issues/474)
- DocPad will now set permissions based on the process's ability
	- Thanks to [Avi Deitcher](https://github.com/deitch), [Stephan Lough](https://github.com/stephanlough) for [issue #165](https://github.com/bevry/docpad/issues/165)
- Updated dependencies


## v6.28.0 March 25, 2013
- Removed native prototype extensions
	- Thanks to [David Baird](https://github.com/dhbaird) for [issue #441](https://github.com/bevry/docpad/issues/441)
	- If you were using `toShortDateString`, then we'd recommend [this gist](https://gist.github.com/4166882) instead
	- If you were using `toISODateString`, just replace it with `toISOString`


## v6.27.0 March 25, 2013
- Engine requirements are now:
	- node >=0.8
	- npm >=1.2
- Iconv is now a lazy loaded dependency
	- Thanks to [jhuntdog](https://github.com/jhuntdog) for [issue #468](https://github.com/bevry/docpad/issues/468)
- Added `regenerateDelay` configuration option
	- Thanks to [Homme Zwaagstra](https://github.com/homme) for [pull request #426](https://github.com/bevry/docpad/pull/426)


## v6.26.2 March 23, 2013
- Fixes `TypeError: Object #<Object> has no method 'removeListener'`
	- Thanks to [Steven Lindberg](https://github.com/slindberg) for [issue #462](https://github.com/bevry/docpad/issues/462)
- Can now customise the `watchOptions` that are used to construct the [watchr](https://github.com/bevry/watchr) instances we create
- Updated dependencies


## v6.26.1 March 12, 2013
- We now gather statistics on the node version and platform you are using to better understand where issues are coming from
- Updated dev dependencies
	- [coffee-script](http://jashkenas.github.com/coffee-script/) ~1.4.0 to ~1.6.1
	- [request](https://github.com/mikeal/request) ~2.14.0 to ~2.16.2


## v6.26.0 March 12, 2013
- Node v0.10.0 support - fixes the "Arguments to path.join must be strings" errors
	- Thanks to [Merrick Christensen](https://github.com/iammerrick) for [issue #455](https://github.com/bevry/docpad/issues/455)
- The requirement of "plugins must have their own `package.json` file with `version` and `main` defined within them" is now enforced
- Updated dependencies
	- [backbone](http://backbonejs.org/) 0.9.9 to 0.9.10
	- [iconv](https://github.com/bnoordhuis/node-iconv) ~2.0.2 to ~2.0.3
	- [request](https://github.com/mikeal/request) ~2.12.0 to ~2.14.0


## v6.25.0 March 10, 2013
- Database is now persistent
- We now destroy unused collections


## v6.24.2 March 8, 2013
- Fixed regression from v6.24.1 that caused new installs or very old upgrades to get stuck in the TOS section


## v6.24.1 March 8, 2013
- Typo fixes
	- Fixes `getMixpanelInstance()` always re-creating the mixpanel instance instead of just doing it once
	- Fixes `DocPad::getBlocks`
	- Thanks to [Richard A](https://github.com/rantecki) for [pull request #450](https://github.com/bevry/docpad/pull/450)
- Fixed mixpanel country and language always being au and en
- Updated dependencies
	- [bal-util](https://github.com/balupton/bal-util) ~1.16.3 to ~1.16.10


## v6.24.0 March 6, 2013
- Configuration changes and improvements
	- Can now load the configuration before the console interface is setup, allowing us to have plugins that extend the console interface
		- Currently explicit commands only
	- Configuration can now load multiple times safely
	- Plugins now have `initialConfig`, `instanceConfig`, and a `setConfig(instanceConfig=null)` helper and their configuration will be reloaded via `setConfig` each time the docpad configuration is reloaded
		- **NOTE: This means no modifying `config` directly in your constructor as the changes won't persist, instead modify them via the `setConfig` call after calling `super`**
			- See the partials plugin for an example of this
	- Thanks to [Olivier Bazoud](https://github.com/obazoud) for [issue #63](https://github.com/bevry/docpad/issues/63) and thanks to [Avi Deitcher](https://github.com/deitch), [Sergey Lukin](https://github.com/sergeylukin), [Zeno Rocha](https://github.com/zenorocha) for [issue #39](https://github.com/bevry/docpad/issues/39)
- Added `docpad action <actions>` command line action
- When passing arrays to blocks we now clone the array to avoid modifying the argument


## v6.23.0 March 6, 2013
- DocPad can now handle foreign encodings when you set `detectEncoding: true` in the [docpad configuration](http://docpad.org/docs/config)
	- Thanks to [Yellow Dragon](https://github.com/huanglong) for [issue #411](https://github.com/bevry/docpad/issues/411)


## v6.22.0 March 6, 2013
- Better port assignment to testers - [changeset](https://github.com/bevry/docpad/commit/244390c5d349598e35e2b99347c8b067006aa293)
- We now identify anonymous users (while respecting their anonymity) - [changeset](https://github.com/bevry/docpad/commit/fb8de48d7dcfc4e9211fd898cda91c54553c1f58)
	- Closes [#430](https://github.com/bevry/docpad/issues/430)


## v6.21.10 February 6, 2013
- Updated dependencies
	- [watchr](https://github.com/bevry/watchr) ~2.3.4 to ~2.3.7
		- Works better for projects that have a large amount of files


## v6.21.9 February 6, 2013
- We now completely ignore growl failures
- We now alert the user of watch failures but still ignore them overall (as to not bring down the entire app)
- Updated dependencies
	- [growl](https://github.com/visionmedia/node-growl) ~1.6.1 to ~1.7.0
	- [express](https://github.com/visionmedia/express) ~3.0.6 to ~3.1.0
	- [watchr](https://github.com/bevry/watchr) ~2.3.4 to ~2.3.5
		- Fixes a bug with uncaught watching exceptions


## v6.21.8 February 5, 2013
- Swapped out underscore dependency for lodash
- Underscore is no longer provided to testers
- `File::getMeta` now aliases to `File.getMeta().get` if arguments have been supplied
- No longer does deep clones on template data per file render (just shallow clone now)
- Fixed a bug that keeps `exists` attribute on `File` always `true`
	- Thanks to [Stefan](https://github.com/stegrams) for [pull request #409](https://github.com/bevry/docpad/pull/409)
- Updated dependencies
	- [bal-util](https://github.com/balupton/bal-util) ~1.16.3 to ~1.16.3
	- [watchr](https://github.com/bevry/watchr) ~2.3.3 to ~2.3.4
		- Way better performance and reliability


## v6.21.7 January 25, 2013
- Fixed port not defaulting correctly on the `docpad-server` executable since v6.21.5
	- Thanks to [man4u](https://github.com/man4u) for [issue #407](https://github.com/bevry/docpad/issues/407)
- Updated dependencies
	- [bal-util](https://github.com/balupton/bal-util) ~1.16.0 to ~1.16.1


## v6.21.6 January 25, 2013
- Better debugging around server starting


## v6.21.5 January 24, 2013
- Supports Node v0.9
- Added `renderSingleExtensions` option
	- Note: currently this will render `src/documents/script.coffee` from CoffeeScript to JavaScript as intended, HOWEVER the outfile will be `out/script.coffee` instead of the expected `out/script.js`. We will likely have to do an extension mapping for single extensions.
- Added experimental `docpad-compile` executable
- Updated dependencies
	- [bal-util](https://github.com/balupton/bal-util) ~1.15.4 to ~1.16.0


## v6.21.4 January 16, 2013
- Fixed incorrect meta data parsing for certain files
	- Thanks to [Jose Quesada](https://github.com/quesada) and [Stefan](https://github.com/stegrams) for [issue #394](https://github.com/bevry/docpad/issues/394)
- Scripts and styles blocks now support an `attrs` option string
	- Thanks to [Alex](https://github.com/amesarosh) for [pull request #397](https://github.com/bevry/docpad/pull/397)
	- Thanks to [edzillion](https://github.com/edzillion) for [issue #400](https://github.com/bevry/docpad/issues/400)


## v6.21.3 January 9, 2013
- Fixed ignored files sometimes triggering reloads
- Added `ignorePaths`, `ignoreHiddenFiles` options
- Added `DocPad::isIgnoredPath`, `DocPad::scandir`, `DocPad::watchdir` helpers


## v6.21.2 January 8, 2013
- Fixed `Base::setDefaults` and `File::setMetaDefaults` always forcing defaults
	- Thanks to [Stefan](https://github.com/stegrams) for [pull request #396](https://github.com/bevry/docpad/pull/396)


## v6.21.1 January 6, 2013
- Added support for running multiple plugin tests for the same plugin
	- Closes [issue #393](https://github.com/bevry/docpad/issues/393)


## v6.21.0 January 2, 2013
- Cleanup focused around loading, parsing, and writing of files and documents
- Added
	- `DocPad::flowDocument`
	- `DocPad::loadDocument`
	- `exists` attribute on `File` model
- Fixed `Document::writeSource`


## v6.20.1 December 24, 2012
- Fixed `File::writeSource`
	- Thanks to [ashnur](https://github.com/ashnur) for [pull request #381](https://github.com/bevry/docpad/pull/381)


## v6.20.0 December 17, 2012
- Better watch handling
- Updated dependencies
	- [watchr](https://github.com/bevry/watchr) ~2.2.1 to 2.3.x


## v6.19.0 December 15, 2012
- Renamed `ignorePatterns` configuration option to `ignoreCommonPatterns` and added new `ignoreCustomPatterns` configuration option
- Updated dependencies
	- [bal-util](https://github.com/balupton/bal-util) 1.14.x to ~1.15.2
	- [watchr](https://github.com/bevry/watchr) 2.1.x to ~2.2.1
- Updated optional dependencies
	- [mixpanel](https://github.com/carlsverre/mixpanel-node) 0.0.9 to 0.0.10
- Updated dev dependencies
	- [chai](https://github.com/chaijs/chai) 1.3.x to 1.4.x


## v6.18.0 December 14, 2012
- Added `regeneratePaths` configuration option
- Include now returns expected results if the content hasn't been rendered yet
	- Closes [issue #378](https://github.com/bevry/docpad/issues/378)
- Updated [QueryEngine](https://github.com/bevry/query-engine/) v1.4.x to v1.5.x
- [Backbone](http://backbonejs.org/) dependency now moved to our dependencies from QueryEngine's. Version set explicitly to v0.9.9.
	- If you have any plugins or whatever that used the `myCollection.getByCid` function, change that call to `myCollection.get`
- Improved help URLs


## v6.17.3 December 5, 2012
- Fixed an issue introduced in v6.17.0 that prevented files from reloading under certain circumstances
	- Thanks to [Vladislav Botvin](https://github.com/darrrk) for [issue #370](https://github.com/bevry/docpad/issues/370) and [pull request #371](https://github.com/bevry/docpad/pull/371)


## v6.17.2 December 5, 2012
- `watch` and `server` actions now perform an initial generation
	- Thanks to [Khalid Jebbari](https://github.com/DjebbZ), [Vladislav Botvin](https://github.com/darrrk) for [issue #369](https://github.com/bevry/docpad/issues/369), [issue #368](https://github.com/bevry/docpad/issues/368), [issue #366](https://github.com/bevry/docpad/issues/366)


## v6.17.1 December 4, 2012
- Updated misc internals to use the new `File::getOutContent` call


## v6.17.0 December 4, 2012
- Cleaned up the way we handle buffers, data, and meta data - more efficient and simpler api
- Updated
	- `File::getMeta` to create meta if it doesn't exist yet
- Removed
	-  `Document::initialize` didn't do anything
	-  `Document::getMeta` didn't do anything
	-  `File::readFile` merged into `File::parse`
	- `File::parseData` renamed to `File::parse` and cleaned significantly
- Added
	- `Base::setDefaults` to update attributes that haven't been set
	- `File::setMeta` to update the meta more easily than `File.getMeta().set`
	- `File::setMetaDefaults` to update the meta attributes that haven't been set
	- `File::getContent` to get the content or buffer
	- `File::getOutContent` to get the rendered content, or content, or buffer
	- `File::getStat` to get the stat
	- `File::setBuffer` to set the buffer
	- `File::getBuffer` to get the buffer


## v6.16.0 December 4, 2012
- The amount of render passes is now customisable via the `renderPasses` configuration option, defaults to `1`
	- Increment this value depending on how many levels of cross-document references you have (e.g. 2 passes for C includes B, B includes A)
- The render pass functionality has been changed to render all documents that don't reference anything else first, then for each additional render pass, render documents that do reference others
	- Previously it would render both types of documents in the one batch, which resulted in hit and miss results
	- Doing this, we now safely have the default `renderPasses` value set to `1` which has the same effect as the traditional `2` render pass
	- Refer to [issue #359](https://github.com/bevry/docpad/issues/359) for more information


## v6.15.0 December 3, 2012
- [Nodejitsu](http://nodejitsu.com/) Support


## v6.14.0 November 29, 2012
- Added  `DocPad::getFileByUrl(url)` and updated the middleware router to use it
	- Big performance gain on request response time


## v6.13.4 November 29, 2012
- `reportErrors` and `reportStatistics` are now `false` if `test` is included in the `process.argv`
	- Closes [issue #354](https://github.com/bevry/docpad/issues/354)


## v6.13.3 November 28, 2012
- Fixed the `include` template helper
- `DocPad::getFileAtPath` now does fuzzy finding
- `FilesCollection::fuzzyFindOne` now also fuzzy matches against the url and accepts `sorting` and `paging` arguments


## v6.13.2 November 27, 2012
- Reduced the extension not rendering error to a warning


## v6.13.1 November 26, 2012
- Fixed up growl notifications


## v6.13.0 November 26, 2012
- Added [Terms of Service](http://bevry.me/terms) and [Privacy Policy](http://bevry.me/privacy) confirmation
- Added statistic tracking so we can better understand usage allowing us to improve DocPad is much greater ways
- Added automatic locale detection for OSX
- Improved error reporting
- Will now error if you try to run an action that doesn't exist (instead of defaulting to the `run` action instead)
- Updated dependencies
	- [Commander](https://github.com/visionmedia/commander.js) 1.0.x to 1.1.x
	- [Growl](https://github.com/visionmedia/node-growl) 1.4.x to 1.6.x
	- [Semver](https://github.com/isaacs/node-semver) 1.0.x to 1.1.x
- Added dependencies
	- [Mixpanel](https://github.com/carlsverre/mixpanel-node) 0.0.9
- Moved dependencies to dev dependencies
	- [Request](https://github.com/mikeal/request)


## v6.12.1 November 23, 2012
- Fixed update check, been broken since v6.7.3
- Updated [bal-util](https://github.com/balupton/bal-util/) dependency from 1.13.13 to 1.14.x


## v6.12.0 November 23, 2012
- When creating new documents or files, if it is inside an unknown path we will now default to creating a document instead of a file
- We now send growl notifications when errors occur
	- Thanks to [Luke Hagan](https://github.com/lhagan) for [pull request #346](https://github.com/bevry/docpad/pull/346), [issue #343](https://github.com/bevry/docpad/issues/343)
- We now error and provide suggestions when an extension transform doesn't do anything
	- Thanks to [Farid Neshat](https://github.com/alFReD-NSH), [Elias Dawson](https://github.com/eliasdawson), [Steve Trevathan](https://github.com/kidfribble) for [issue #192](https://github.com/bevry/docpad/issues/192)
- Watching stability has been improved significantly
	- Thanks to [ashnur](https://github.com/ashnur) for [issue #283](https://github.com/bevry/docpad/issues/283)
- Parser headers that don't include spacing now work again (e.g. `---cson` instead of `--- cson`)
	- Thanks to [bobobo1618](https://github.com/bobobo1618) for [issue #341](https://github.com/bevry/docpad/issues/341)
- Removed default comparator on `FilesCollection` due to performance improvement it provides
	- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [issue #330](https://github.com/bevry/docpad/issues/330)
- Added
	- `Document::parseFileDirectory(opts,next)`
	- `Document::parseDocumentDirectory(opts,next)`
	- `FilesCollection::fuzzyFindOne(data)`


## v6.11.1 November 16, 2012
- Changes made to help get the docpad server up and running as soon as possible:
	- `server` action is now run before `generate` action
	- if a request is made while a generation is occurring, the request will be put on hold until the generation completes
- We now pass the option `reset` to the `generateBefore` event
	- Lets you know if the generation is a complete generation (`reset` is `true`) or a differential generation (`reset` is `false`)


## v6.11.0 October 29, 2012
- Updated [QueryEngine](https://github.com/bevry/query-engine/) dependency from 1.3.x to 1.4.x
	- Should see speed improvements
- Added `docs` directory to `.npmignore`


## v6.10.0 October 29, 2012
- Updated [QueryEngine](https://github.com/bevry/query-engine/) dependency from 1.2.3 to 1.3.x
	- Should see better memory usage and speed improvements
- Now tells you how many files we have when doing a complete render


## v6.9.2 October 26, 2012
- Swapped [yaml](https://github.com/visionmedia/js-yaml) dependency for [yamljs](https://github.com/jeremyfa/yaml.js)
	- Fixes [#333](https://github.com/bevry/docpad/issues/333)
- Better error output on custom error objects


## v6.9.1 October 25, 2012
- Added `reloadPaths` configuration option
	- When a change occurs in one of the reload paths then we will reload docpad
- Added `getBlocks` and `setBlocks`
- Added `getCollections` and `setCollections`
- Will now output how long the generation took


## v6.9.0 October 25, 2012
- Updated dependencies
	- [CoffeeScript](http://coffeescript.org/) 1.3.x to 1.4.x
	- [CSON](https://github.com/bevry/cson) 1.2.x to 1.4.x
	- [Joe](https://github.com/bevry/joe) 1.0.x to 1.1.x
	- [Underscore](http://underscorejs.org/) 1.3.x to 1.4.x
	- [Chai](http://chaijs.com/) 1.1.x to 1.3.x
- Removed ability to require uncompiled plugins
	- This is due to the CoffeeScript 1.4.x from 1.3.x upgrade
- `skeletonNonexistant` now tells us the path it checked


## v6.8.4 October 25, 2012
- Added `getEnvironment` and `getEnvironments` template helpers


## v6.8.3 October 22, 2012
- Fixed growl generating notification from saying `generated` instead of `generating`
- Added `ignorePatterns` option
	- Thanks to[Bruno Héridet](https://github.com/Delapouite) for [issue #193](https://github.com/bevry/docpad/issues/193), [pull request #326](https://github.com/bevry/docpad/pull/326)


## v6.8.2 October 19, 2012
- Updated the document meta data extraction regex
	- It will now treat data that is wrapped in anything that repeats 3 or more times, as meta data allowing you to use whatever is appropriate for the markup you are currently in (before we only supported `---` and `
###`)


## v6.8.1 October 19, 2012
- Fixed `--port` CLI option not working (and possibly others)
- Fixed `docpad skeleton` blocking instead of ending
	- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [issue #225](https://github.com/bevry/docpad/issues/225)
- Improved localisation
	- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [pull request #325](https://github.com/bevry/docpad/pull/325)


## v6.8.0 October 18, 2012
- Added support for `.env` files
	- If a `.env` file is present in your website path, we will add its key values to `process.env`
	- More information on `.env` files [here](https://devcenter.heroku.com/articles/config-vars#local-setup)
- Improved localisation
	- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [pull request #323](https://github.com/bevry/docpad/pull/323)
- Removed unused model requirement inside document model file
	- Thanks to [Bruno Héridet](https://github.com/Delapouite) for [pull request #318](https://github.com/bevry/docpad/pull/318)


## v6.7.4 October 10, 2012
- `PORT` environment variable now comes before infrastructure specific port variables
- Can now do `docpad-server --action generate,server,watch --port 8080`


## v6.7.3 October 8, 2012
- Fixed logging when a fatal error occurs during initialisation
- We now do warnings when plugins do invalid naming conventions
	- Closes [#313](https://github.com/bevry/docpad/issues/313)
	- Help by [Eugene Mirotin](https://github.com/emirotin)
- We now display the plugin versions in the plugin listing information when debugging
	- Help by [ashnur](https://github.com/ashnur)
- More localization progress


## v6.7.2 October 3, 2012
- Fixed custom middleware (via the `serverExtend` event) being loaded too late (after the express router middleware)


## v6.7.1 October 2, 2012
- Can now use the `url` property in meta data to specify a custom URL to use
- Collection creation functions in the DocPad Configuration Files now scope to the DocPad Instance
- Fixed the 400 and 500 middlewares


## v6.7.0 October 2, 2012
- Server changes:
	- Updated [Express.js](http://expressjs.com/) from v2.5 to v3.0
		- If you're doing custom routing, you'll want to check the [Express.js Upgrade Guide](https://github.com/visionmedia/express/wiki/Migrating-from-2.x-to-3.x)
		- There are now two server objects: `serverExpress` and `serverHttp` - get them using `docpadInstance.getServer(true)`, set them using `docpad.setServer({serverExpress,serverHttp})` - `server` in events, and `docpadInstance.getServer()` return the `serverExpress` object for backwards compatibility (however things like socket.io require the `serverHttp` object)
		- Closes [#311](https://github.com/bevry/docpad/pull/311), [#308](https://github.com/bevry/docpad/issues/308), [#272](https://github.com/bevry/docpad/issues/272), [#274](https://github.com/bevry/docpad/issues/274)
		- Help by [dave8401](https://github.com/dave8401) and [Ben Harris](https://github.com/bharrisau)
	- Abstracted out the different middlewares to `serverMiddlewareHeader`, `serverMiddlewareRouter`, `serverMiddleware404`, and `serverMiddleware500`
	- Added the following options to the `server` actions:
		- `serverExpress` for a custom express.js server
		- `serverHttp` for a custom http server
		- `middlewareStandard` set it to `false` for us to not use any of the standard middleware (body parse, method override, express router)
		- `middlewareBodyParser` set it to `false` for us to not add the `bodyParser` middleware
		- `middlewareMethodOverride` set it to `false` for us to not add the `methodOverride` middleware
		- `middlewareExpressRouter` set it to `false` for us to not add the Express.js `router` middleware
		- `middleware404` set it to `false` for us to not add our `404` middleware
		- `middleware500` set it to `false` for us to not add our `500` middleware
	- Example API usage can be found [here](https://github.com/bevry/docpad/wiki/API)
- Added `standalone` attribute to files (defaults to `false`)
	- If you set to `true`, changes to the file will only cause re-rendering of that file alone
- Added a progress indicator during generation
	- Closes [#247](https://github.com/bevry/docpad/issues/247)
	- Help by [Bruno Héridet](https://github.com/Delapouite)


## v6.6.8 September 29, 2012
- Fixed watching setup not completing under some conditions
	- Bumped watchr minimum version to v2.1.5


## v6.6.7 September 28, 2012
- Added built-in support for AppFog and CloudFoundry ports


## v6.6.6 September 24, 2012
- Further improved file text/binary detection


## v6.6.5 September 18, 2012
- Further improved file encoding detection
	- Closes [#266: Images are broken](https://github.com/bevry/docpad/issues/266)


## v6.6.4 September 4, 2012
- Better file encoding detection
	- Closes [#288: Output of certain binary files is corrupt](https://github.com/bevry/docpad/issues/288)


## v6.6.3 September 3, 2012
- Fixed `date` and `name` always being their automatic values


## v6.6.0-6.6.2 August 28, 2012
- Added `docpad-debug` executable for easier debugging
- Will now ask if you would like to subscribe to our newsletter when running on the development environment
- Beginnings of localisation


## v6.5.7 August 26, 2012
- Fixed "cannot get length of undefined" intermittent error
	- Due to an incorrect variable name inside `DocPad::ensureDocumentOrFile`


## v6.5.6 August 19, 2012
- Added `regenerateEvery` configuration option


## v6.5.0-6.5.5 August 10, 2012
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


## v6.4.1 July 19, 2012
- Added new `source` attribute to the file model, as the `content` attribute on the document model is actually the `body` not the original content like it is in the file model


## v6.4.0 July 19, 2012
- We now support `404 Not Found` and `500 Internal Server Error` error pages thanks to [Nick Crohn](https://github.com/ncrohn) for [pull request #251](https://github.com/bevry/docpad/pull/251)
- Fixed [#269](https://github.com/bevry/docpad/issues/269) where the `docpad render` command wouldn't work
- Fixed [#268](https://github.com/bevry/docpad/issues/268) where files which names start with a `.` from having a `.` appended to their output filename


## v6.3.3 July 18, 2012
- Fixed binary file output
	- Added binary files to the test suite so this won't happen again
	- Was due to the dereference on the new clear introduced in v6.3.0
		- As such, we now store the `data` attribute for files outside of the attributes, use `getData` and `setData(data)` now instead of `get('data')` and `set({data:data})`


## v6.3.2 July 18, 2012
- Fixed install action


## v6.3.1 July 18, 2012
- Fixed `extendCollections` being called before the plugins have loaded when using the CLI


## v6.3.0 July 18, 2012
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


## v6.2.0 July 10, 2012
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


## v6.1.3 July 8, 2012
- Fixed `extendTemplateData` event firing before our plugins have finished loading


## v6.1.2 July 8, 2012
- Fixed `DocPad::getBlock`


## v6.1.1 July 8, 2012
- Added `html` collection
- Dependency updates
	- [chai](http://chaijs.com/) from v1.0 to v1.1


## v6.1.0 July 8, 2012
- End user changes
	- Added support for using no skeleton on empty directory
	- Action completion callback will now correctly return all arguments instead of just the error argument
	- Filename argument on command line is now optional, if specified it now supports single extension values, e.g. `markdown` instead of `file.html.md`
	- When using CoffeeScript instead of YAML for meta data headers, the CoffeeScript will now be sandboxed
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
		- `getFiles(query,sorting,paging)`
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


## v6.0.14 June 27, 2012
- Configuration variables `documentPaths`, `filesPaths`, and `layoutsPaths` are now relative to the `srcPath` instead of the `rootPath`
	- `pluginsPaths` is still relative to the `rootPath`


## v6.0.13 June 27, 2012
- Added `getFileModel`, `getFileUrl`, `getFile` template helpers


## v6.0.12 June 26, 2012
- More robust node and git path handling
- Dependency updates
	- [bal-util](https://github.com/balupton/bal-util) from v1.9 to v1.10


## v6.0.11 June 24, 2012
- We now output that we are actually installing the skeleton, rather than just doing nothing
- We now also always output the skeleton clone and installation progress to the user
- Skeletons are now a backbone collection


## v6.0.10 June 22, 2012
- Fixed CLI on certain setups


## v6.0.9 June 22, 2012
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


## v6.0.8 June 21, 2012
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


## v6.0.7 June 20, 2012
- When watching files, and you modify a layout, docpad will now re-render anything using that layout - closes #242


## v6.0.6 June 19, 2012
- Greatly simplified the event architecture
	- We now inherit from the simpler `balUtil.EventEmitterEnhanced` instead of `balUtil.EventSystem`, and have moved queue code into `balUtil.Group` as `docpadInstance.getRunner()`
	- Actions when called directly do not queue, they only queue when called through `docpadInstance.action`
- `docpadinstance.loadConfiguration` is now an action called `load`
- Fixed the run action not completing due to a missing callback


## v6.0.5 June 19, 2012
- Updated QueryEngine from version 1.1 to 1.2
- Fixed watch error when deleting files, or changing a directory


## v6.0.4 June 19, 2012
- Fixed skeleton action


## v6.0.3 June 19, 2012
- Fixed `server` action when used in combination with a custom server


## v6.0.2 June 11, 2012
- Now fetches the DocPad v6 exchange file


## v6.0.1 June 11, 2012
- Fixed plugin generation tests


## v6.0.0 June 11, 2012
- Breaking changes that may affect you
	- Removed `documentsPath`, `filesPath`, `layoutsPath` configuration options for their array based alternatives `documentsPaths`, `filesPaths`, `layoutsPaths`
	- Removed `require` from `templateData` as it needs to be specified in your project otherwise it has the wrong paths
	- Removed `database`, `collections`, `blocks` from `templateData` for their helper based alternatives `getDatabase()`, `getCollection('collectionName')`, `getBlock('blockName')`
	- Removed `String::startsWith`, `String::finishesWith`, `Array::hasCount`, `Array::has` as we never used them
	- Removed `DocPad::documents` and `templateData.documents`, now use `getCollection('documents')`
- New features
	- Differential rendering
	- Extendable CLI
	- Template helpers
- Other changes
	- Better error handling
	- Moved to Joe for unit testing


## v5.2.5 May 18, 2012
- Fixed layout selection when two layout's share similar names - Closes [#227](https://github.com/bevry/docpad/issues/227)


## v5.2.4 May 18, 2012
- Upgraded chai dev dependency from 0.5.x to 1.0.x
- Fixed a dereferencing issue
- Plugin testers will now run the `install` and `clean` actions when creating the DocPad instance


## v5.2.3 May 18, 2012
- DocPad will no longer try and use a skeleton inside a non-empty directory
- DocPad will now only include the CoffeeScript runtime if needed (for loading CoffeeScript plugins)


## v5.2.2 May 17, 2012
- Fixed [#208](https://github.com/bevry/docpad/issues/208) - Multiple file extensions being trimmed
- Fixed [#205](https://github.com/bevry/docpad/issues/205) - Name collisions are causing not all files to be copied
- Changed file `id` to default to the `relativePath` instead of the `relativeBase`
- Finding layouts now uses `id: $startsWith: layoutId` instead of `id: layoutId`


## v5.2.1 May 8, 2012
- Fixed a complication that prevents `src/public` from being written to `out`
	- Added automated regression tests to ensure this will never happen again
- Added `documentsPaths`, `filesPaths`, and `layoutsPaths` configuration variables
- Simplified model code
- Cleaned up some async code


## v5.2.0 May 4, 2012
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
- Templates now have access to a new function called `include`. It will include the renderedContent (or if unavailable to content) of the file. In eco, you would use it like this: `<%- @include('filename.ext1.ext2.ext3') %>`
- Blocks are now Collections too! You can call `.add` on them, and use `.toHTML()` to grab them as HTML (`.join` will do the same thing for b/c)
- This should be a completely backwards compatible release, let us know if you any issues on the


## v5.1.2 April 26, 2012
- Fixed some UTF8 encoded files from being detected as binary
- Fixed documents with no extension being outputted with an undefined extension


## v5.1.0-5.1.1 April 25, 2012
- Fixed EventEmitter warning
- Binary files can now be placed within the `src/documents` directory
- Removed eyes devDependency
- Models now use CoffeeScript's class extend, instead of Backbone's extend


## v5.0.5 April 14, 2012
- Added `.npmignore` file
- Added `document.contentType` and `document.contentTypeRendered`
- Fixed `document.contentRendered` on files that do not have layouts
- Added tests for:
	- Checking that `ignored: true` documents are properly ignored
	- That ignored common pattern files/dirs are properly ignored
	- That attributes are being applied properly


## v5.0.1-v5.0.4 April 14, 2012
- Updated balUtil from 1.4 to 1.5
	- Fixes some scandir bugs
- Updated watchr from 1.0 to 2.0
	- This should make watching re-generation a lot faster
- Added a warning if you have no plugins loaded and are trying to do a generate
- Fixed ignored check on documents


## v5.0.0 April 14, 2012
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


## v4.1.1 April 9, 2012
- Fixed DocPad from outputting `undefined` instead the layout's name which it could not find
	- Thanks to [Changwoo Park](https://github.com/pismute) for [pull request #173](https://github.com/bevry/docpad/pull/173) and [Morgan Sutherland](https://github.com/msutherl) for [issue #172](https://github.com/bevry/docpad/issues/172)


## v4.1.0 April 6, 2012
- [Feedr Plugin](https://github.com/bevry/docpad/tree/master/lib/exchange/plugins/feedr) now exposes `@feedr.feeds` to the `templateData` instead of `@feeds`
- Exchange data now moved to the [docpad-extras](https://github.com/bevry/docpad-extras) repository
- Fixed broken `balupton.docpad` skeleton repo url


## v4.0.0-4.0.3 April 6, 2012
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


## v3.3.2 March 18, 2012
- Fixed missing interpolation on new version notification
- Fixed the scandir error with the skeletons path when doing the first run on windows
- Updated paths to use `path.join` instead of always using forward slashes


## v3.3.1 March 18, 2012
- Fixed Pygments plugin highlighting the code multiple times for documents with layouts
- Added `isLayout` and `isDocument` flags to `Document` and `Layout` prototypes


## v3.3.0 February 29, 2012
- Fixed ruby rendering with ruby v1.8
	- Thanks to [Sorin Ionescu](https://github.com/sorin-ionescu) for [the patch](https://github.com/bevry/docpad/commit/a3f711b1b015b2fa31490bbbaca2cf9c3ead3016)
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
	- [#137](https://github.com/bevry/docpad/pull/137) - An error occurred: Cannot find module 'uglify-js'
	- [#34](https://github.com/bevry/docpad/issues/34) - As a User, I want server-side syntax highlighting, as pygments rocks


## v3.2.8 February 26, 2012
- Stopped `docpad render` from outputting the welcome message
- Removed `try..catch`s from plugins, you should do this too
	- The checking is now higher up in the callstack, which provides better error reporting and capturing
- Fixed a problem with the error bubbling that was preventing template errors from being outputted
- Fixed the "too many files open" issue thanks to [bal-util](http://github.com/balupton/bal-util.npm)'s `openFile` and `closeFile` utility functions
- Closes
	- [#143](https://github.com/bevry/docpad/issues/143) - No errors on wrong layout


## v3.2.0-3.2.7 February 15, 2012
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
- Added the ability to render files programmatically via the command line
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


## v3.1 Unreleased
- Added an interactive cli
- Closes
	- #125 - As a User, I want an Interactive CLI, so that I can do more with DocPad's CLI


## v3.0 Unreleased
- Added a new event system
- Closes
	- #60 - DocPad needs a better event system


## v2.6 January 2, 2012
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
- Updated dependencies
	- Growl 1.2.x -> 1.4.x [- changelog](https://github.com/visionmedia/node-growl/blob/master/History.md)
	- CoffeeScript 1.1.3 -> 1.2.x [- changelog](http://coffeescript.org/#changelog)


## v2.5 December 15, 2011
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
- Updated dependencies
	- Commander 0.3.x -> 0.5.x [- changelog](https://github.com/visionmedia/commander.js/blob/master/History.md)
	- Growl 1.1.x -> 1.2.x [- changelog](https://github.com/visionmedia/node-growl/blob/master/History.md)
	- NPM 1.0.x -> 1.1.x
	- Jade 0.17.x -> 0.19.x [- changelog](https://github.com/visionmedia/jade/blob/master/History.md)
	- Stylus 0.19.x -> 0.20.x [- changelog](https://github.com/LearnBoost/stylus/blob/master/History.md)
	- Nib 0.2.x -> 0.3.x [- changelog](https://github.com/visionmedia/nib/blob/master/History.md)


## v2.4 November 26, 2011
- AutoUpdate plugin
	- Automatically refreshes the user's current page when the website is regenerated
	- Very useful for development, though you probably want to disable it for production
	- Enabled by default


## v2.3 November 18, 2011
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


## v2.2 November 14, 2011
- Windows support!
- Now uses [Benjamin Lupton's](https://github.com/balupton) [Watchr](https://github.com/balupton/watchr) as the watcher library
	- Provides windows support
- Now uses [Tim Caswell's](https://github.com/creationix) [Haml.js](https://github.com/creationix/haml-js) as the haml library
	- Provides windows support
- Bug fixes
	- Works with zero documents
	- Works with empty `package.json`
	- Fixed mime-type problems with documents


## v2.1 November 10, 2011
- Support for dynamic documents
	- These are re-rendered on each request, must use the docpad server
	- See the search example in the [kitchensink skeleton](https://github.com/bevry/kitchensink.docpad)
- Removed deprecated `@Document`, `@Documents`, and `@Site` from the `templateData` (the variables available to the templates). Use their lowercase equivalents instead. This can cause backwards compatibility problems with your templates, the console will notify you if there is a problem.
- Fixed `docpad --version` returning `null` instead of the docpad version


## v2.0 November 8, 2011
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


## v1.4 October 22, 2011
- Template engines now have access to node.js's `require`
- Less Plugin
	- Added [LessCSS](http://lesscss.org/) to CSS support
		- Uses [Alexis Sellier's](https://github.com/cloudhead) [Less.js](https://github.com/cloudhead/less.js)
- Fixed NPM warning about incorrect property name
- Logged errors will now also output their stacktraces for easier debugging
- If an error occurs during rendering of a document, docpad will let us know which document it happened on


## v1.3 October 3, 2011
- Parsing is now split into two parts `parsing` and `contextualizing`
	- Contextualizing is used to determine the result filename, and title if title was not set
- The code is now more concise
	- File class moved to `lib/file.coffee`
	- Prototypes moved to `lib/prototypes.coffee`
	- Version checking moved to the `bal-util` module
- File properties have changed
	- `basename` is extensionless
	- `filename` now contains the file's extensions
	- `id` is now the `relativeBase` instead of the `slug`
	- `extensionRendered` is the result extension
	- `filenameRendered` is the result filename: `"#{basename}.#{extensionRendered}"
	- `title` if now set to `filenameRendered` if not set
- Added support for different meta parsers, starting with [CoffeeScript](https://github.com/jashkenas/coffee-script) and [YAML](https://github.com/visionmedia/js-yaml) support. YAML is still the default meta parser
- The YAML dependency is specifically set now to v0.2.1 as the newer version has a bug in it
- Fixed multiple renderers for a single document. E.g. `file.html.md.eco`
- Now also supports using `
###` along with `---` for wrapping the meta data
- Supports the `public` alias for the `files` directory


## v1.2 September 29, 2011
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


## v1.1 September 28, 2011
- Added [Buildr](http://github.com/balupton/buildr.npm) Plugin so you can now bundle your scripts and styles together :-)
- The `action` method now supports an optional callback
	- Thanks to [Aaron Powell](https://github.com/aaronpowell) for [#41](https://github.com/bevry/docpad/pull/41)
- Added a try..catch around the version detection to ensure it never kills docpad if something goes wrong
- Skeletons have been removed from the repository due to circular references. The chosen skeleton is now pulled during the skeleton action. We also now perform a recursive git submodule init and update, as well as a npm install if necessary.


## v1.0 September 20, 2011
- [Upgrade guide for v0.x users](https://github.com/bevry/docpad/wiki/Upgrading)
- The concept of template engines and markup languages have been merged into the concept of renderers
- Coffee Plugin
	- Added [CoffeeKup](http://coffeekup.org/) to anything and HTML to CoffeeKup support
		- Uses [Maurice Machado's](https://github.com/mauricemach) [CoffeeKup](https://github.com/mauricemach/coffeekup) and [Brandon Bloom's](https://github.com/brandonbloom) [Html2CoffeeKup](https://github.com/brandonbloom/html2coffeekup)
	- Added [CoffeeScript](https://github.com/jashkenas/coffee-script) to JavaScript and JavaScript to CoffeeScript support
		- Uses [Jeremy Ashkenas's](https://github.com/jashkenas) [CoffeeScript](https://github.com/jashkenas/coffee-script/) and [Rico Sta. Cruz's](https://github.com/rstacruz) [Js2Coffee](https://github.com/rstacruz/js2coffee)
- Added a [Commander.js](https://github.com/visionmedia/commander.js) based CLI
	- Thanks to [~eldios](https://github.com/eldios)
- Added support for [Growl](http://growl.info/) notifications
- Added asynchronous version comparison


## v0.10 September 14, 2011
- Plugin infrastructure
- Better logging through [Caterpillar](https://github.com/balupton/caterpillar.npm)
- HAML Plugin
	- Added [HAML](http://haml-lang.com/) to anything support
		- Uses [TJ Holowaychuk's](https://github.com/visionmedia) [HAML](https://github.com/visionmedia/haml.js)
- Jade Plugin
	- Added [Jade](http://jade-lang.com/) to anything support
		- Uses [TJ Holowaychuk's](https://github.com/visionmedia) [Jade](https://github.com/visionmedia/jade)


## v0.9 July 6, 2011
- No longer uses MongoDB/Mongoose! We now use [Query-Engine](https://github.com/balupton/query-engine.npm) which doesn't need any database server :)
- Watching files now working even better
- Now supports clean urls :)


## v0.8 May 23, 2011
- Now supports multiple skeletons
- Structure changes


## v0.7 May 20, 2011
- Now supports multiple docpad instances


## v0.6 May 12, 2011
- Moved to CoffeeScript
- Removed highlight.js (should be a plugin or client-side feature)


## v0.5 May 9, 2011
- Pretty big clean


## v0.4 May 9, 2011
- The CLI is now working as documented


## v0.3 May 7, 2011
- Got the generation and server going


## v0.2 March 24, 2011
- Initial prototyping with [Sven Vetsch](https://github.com/disenchant)


## v0.1 March 16, 2011
- Initial discussions with [Henri Bergius](https://github.com/bergie)