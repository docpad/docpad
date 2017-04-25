##*
# The central module for DocPad
# @module DocPad
##

# =====================================
# This block *must* come first

# Important
pathUtil = require('path')
lazyRequire = require('lazy-require')
corePath = pathUtil.resolve(__dirname, '..', '..')

# Profile
if ('--profile' in process.argv)
	# Debug
	debugger

	# Nodetime
	if process.env.DOCPAD_PROFILER.indexOf('nodetime') isnt -1
		throw new Error('NODETIME_KEY environment variable is undefined')  unless process.env.NODETIME_KEY
		console.log 'Loading profiling tool: nodetime'
		require('lazy-require').sync 'nodetime', {cwd:corePath}, (err,nodetime) ->
			if err
				console.log 'Failed to load profiling tool: nodetime'
				console.log err.stack or err
			else
				nodetime.profile({
					accountKey: process.env.NODETIME_KEY
					appName: 'DocPad'
				})
				console.log 'Profiling with nodetime with account key:', process.env.NODETIME_KEY

	# Webkit Devtools
	if process.env.DOCPAD_PROFILER.indexOf('webkit-devtools-agent') isnt -1
		console.log 'Loading profiling tool: webkit-devtools-agent'
		require('lazy-require').sync 'webkit-devtools-agent', {cwd:corePath}, (err, agent) ->
			if err
				console.log 'Failed to load profiling tool: webkit-devtools-agent'
				console.log err.stack or err
			else
				agent.start()
				console.log "Profiling with webkit-devtools-agent on pid #{process.pid} at http://127.0.0.1:9999/"

	# V8 Profiler
	if process.env.DOCPAD_PROFILER.indexOf('v8-profiler') isnt -1
		console.log 'Loading profiling tool: v8-profiler'
		require('lazy-require').sync 'v8-profiler-helper', {cwd:corePath}, (err, profiler) ->
			if err
				console.log 'Failed to load profiling tool: v8-profiler'
				console.log err.stack or err
			else
				profiler.startProfile('docpad-profile')
				console.log "Profiling with v8-profiler"
			process.on 'exit', ->
				profiler.stopProfile('docpad-profile')


# =====================================
# Requires

# Standard Library
util     = require('util')

# External
queryEngine = require('query-engine')
{uniq, union, pick} = require('underscore')
CSON = require('cson')
balUtil = require('bal-util')
scandir = require('scandirectory')
extendr = require('extendr')
eachr = require('eachr')
typeChecker = require('typechecker')
ambi = require('ambi')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
safeps = require('safeps')
ignorefs = require('ignorefs')
rimraf = require('rimraf')
superAgent = require('superagent')
extractOptsAndCallback = require('extract-opts')
{EventEmitterGrouped} = require('event-emitter-grouped')

# Base
{Events,Model,Collection,QueryCollection} = require('./base')

# Utils
docpadUtil = require('./util')

# Models
FileModel = require('./models/file')
DocumentModel = require('./models/document')

# Collections
FilesCollection = require('./collections/files')
ElementsCollection = require('./collections/elements')
MetaCollection = require('./collections/meta')
ScriptsCollection = require('./collections/scripts')
StylesCollection = require('./collections/styles')

# Plugins
PluginLoader = require('./plugin-loader')
BasePlugin = require('./plugin')


# ---------------------------------
# Helpers

setImmediate = global?.setImmediate or process.nextTick  # node 0.8 b/c


# ---------------------------------
# Variables

isUser = docpadUtil.isUser()


###*
# Contains methods for managing the DocPad application.
# This includes managing a DocPad projects files and
# documents, watching directories, emitting events and
# managing the node.js/express.js web server.
# Extends https://github.com/bevry/event-emitter-grouped
#
# The class is instantiated in the docpad-server.js file
# which is the entry point for a DocPad application.
#
# 	new DocPad(docpadConfig, function(err, docpad) {
# 		if (err) {
# 			return docpadUtil.writeError(err);
# 		}
# 		return docpad.action(action, function(err) {
# 			if (err) {
# 				return docpadUtil.writeError(err);
# 			}
# 			return console.log('OK');
# 		});
# 	});
#
# @class Docpad
# @constructor
# @extends EventEmitterGrouped
###
class DocPad extends EventEmitterGrouped
	# Libraries
	# Here for legacy API reasons
	#@DocPad: DocPad
	#@Backbone: require('backbone')
	#@queryEngine: queryEngine

	# Allow for `DocPad.create()` as an alias for `new DocPad()`
	# Allow for `DocPad.createInstance()` as an alias for `new DocPad()` (legacy alias)
	@create: (args...) -> return new @(args...)
	@createInstance: (args...) -> return new @(args...)

	# Require a local DocPad file
	# Before v6.73.0 this allowed requiring of files inside src/lib, as well as files inside src
	# Now it only allows requiring of files inside src/lib as that makes more sense
	@require: (relativePath) ->
		# Absolute the path
		absolutePath = pathUtil.normalize(pathUtil.join(__dirname, relativePath))

		# Check if we are actually a local docpad file
		if absolutePath.replace(__dirname, '') is absolutePath
			throw new Error("docpad.require is limited to local docpad files only: #{relativePath}")

		# Require the path
		return require(absolutePath)


	# =================================
	# Variables

	# ---------------------------------
	# Modules

	# ---------------------------------
	# Base

	###*
	# Events class
	# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee
	# @property {Object} Events
	###
	Events: Events
	###*
	# Model class
	# Extension of the Backbone Model class
	# http://backbonejs.org/#Model
	# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee
	# @property {Object} Model
	###
	Model: Model

	###*
	# Collection class
	# Extension of the Backbone Collection class
	# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee
	# http://backbonejs.org/#Collection
	# @property {Object} Collection
	###
	Collection: Collection

	###*
	# QueryCollection class
	# Extension of the Query Engine QueryCollection class
	# https://github.com/docpad/docpad/blob/master/src/lib/base.coffee
	# https://github.com/bevry/query-engine/blob/master/src/documents/lib/query-engine.js.coffee
	# @property {Object} QueryCollection
	###
	QueryCollection: QueryCollection

	# ---------------------------------
	# Models

	###*
	# File Model class
	# Extension of the Model class
	# https://github.com/docpad/docpad/blob/master/src/lib/models/file.coffee
	# @property {Object} FileModel
	###
	FileModel: FileModel

	###*
	# Document Model class
	# Extension of the File Model class
	# https://github.com/docpad/docpad/blob/master/src/lib/models/document.coffee
	# @property {Object} DocumentModel
	###
	DocumentModel: DocumentModel

	# ---------------------------------
	# Collections

	###*
	# Collection of files in a DocPad project
	# Extension of the QueryCollection class
	# https://github.com/docpad/docpad/blob/master/src/lib/collections/files.coffee
	# @property {Object} FilesCollection
	###
	FilesCollection: FilesCollection

	###*
	# Collection of elements in a DocPad project
	# Extension of the Collection class
	# https://github.com/docpad/docpad/blob/master/src/lib/collections/elements.coffee
	# @property {Object} ElementsCollection
	###
	ElementsCollection: ElementsCollection

	###*
	# Collection of metadata in a DocPad project
	# Extension of the ElementsCollection class
	# https://github.com/docpad/docpad/blob/master/src/lib/collections/meta.coffee
	# @property {Object} MetaCollection
	###
	MetaCollection: MetaCollection

	###*
	# Collection of JS script files in a DocPad project
	# Extension of the ElementsCollection class
	# https://github.com/docpad/docpad/blob/master/src/lib/collections/scripts.coffee
	# @property {Object} ScriptsCollection
	###
	ScriptsCollection: ScriptsCollection

	###*
	# Collection of CSS style files in a DocPad project
	# Extension of the ElementsCollection class
	# https://github.com/docpad/docpad/blob/master/src/lib/collections/styles.coffee
	# @property {Object} StylesCollection
	###
	StylesCollection: StylesCollection

	###*
	# Plugin Loader class
	# https://github.com/docpad/docpad/blob/master/src/lib/plugin-loader.coffee
	# Loads the DocPad plugins from the file system into
	# a DocPad project
	# @property {Object} PluginLoader
	###
	PluginLoader: PluginLoader

	###*
	# Base class for all DocPad plugins
	# https://github.com/docpad/docpad/blob/master/src/lib/plugin.coffee
	# @property {Object} BasePlugin
	###
	BasePlugin: BasePlugin

	# ---------------------------------
	# DocPad

	###*
	# DocPad's version number
	# @private
	# @property {Number} version
	###
	version: null

	###*
	# Get the DocPad version number
	# @method getVersion
	# @return {Number}
	###
	getVersion: ->
		@version ?= require(@packagePath).version
		return @version

	###*
	# Get the DocPad version string
	# @method getVersionString
	# @return {String}
	###
	getVersionString: ->
		if docpadUtil.isLocalDocPadExecutable()
			return util.format(@getLocale().versionLocal, @getVersion(), @corePath)
		else
			return util.format(@getLocale().versionGlobal, @getVersion(), @corePath)

	###*
	# The plugin version requirements
	# @property {String} pluginVersion
	###
	pluginVersion: '2'

	# Process getters
	###*
	# Get the process platform
	# @method getProcessPlatform
	# @return {Object}
	###
	getProcessPlatform: -> process.platform

	###*
	# Get the process version string
	# @method getProcessVersion
	# @return {String}
	###
	getProcessVersion: -> process.version.replace(/^v/,'')

	###*
	# The express.js server instance bound to DocPad.
	# http://expressjs.com
	# @private
	# @property {Object} serverExpress
	###
	serverExpress: null

	###*
	# The Node.js http server instance bound to DocPad
	# https://nodejs.org/api/http.html
	# @private
	# @property {Object} serverHttp
	###
	serverHttp: null

	###*
	# Get the DocPad express.js server instance and, optionally,
	# the node.js https server instance
	# @method getServer
	# @param {Boolean} [both=false]
	# @return {Object}
	###
	getServer: (both=false) ->
		{serverExpress,serverHttp} = @
		if both
			return {serverExpress, serverHttp}
		else
			return serverExpress

	###*
	# Set the express.js server and node.js http server
	# to bind to DocPad
	# @method setServer
	# @param {Object} servers
	###
	setServer: (servers) ->
		# Apply
		if servers.serverExpress and servers.serverHttp
			@serverExpress = servers.serverExpress
			@serverHttp = servers.serverHttp

		# Cleanup
		delete @config.serverHttp
		delete @config.serverExpress
		delete @config.server

	###*
	# Destructor. Close and destroy the node.js http server
	# @private
	# @method destroyServer
	###
	destroyServer: ->
		@serverHttp?.close()
		@serverHttp = null
		# @TODO figure out how to destroy the express server

	#
	###*
	# Internal property. The caterpillar logger instances bound to DocPad
	# @private
	# @property {Object} loggerInstances
	###
	loggerInstances: null

	###*
	# Get the caterpillar logger instance bound to DocPad
	# @method getLogger
	# @return {Object} caterpillar logger
	###
	getLogger: -> @loggerInstances?.logger

	###*
	# Get all the caterpillar logger instances bound to DocPad
	# @method getLoggers
	# @return {Object} collection of caterpillar loggers
	###
	getLoggers: -> @loggerInstances

	###*
	# Sets the caterpillar logger instances bound to DocPad
	# @method setLoggers
	# @param {Object} loggers
	# @return {Object} logger instances bound to DocPad
	###
	setLoggers: (loggers) ->
		if @loggerInstances
			@warn @getLocale().loggersAlreadyDefined
		else
			@loggerInstances = loggers
			@loggerInstances.logger.setConfig(dry:true)
			@loggerInstances.console.setConfig(dry:false).pipe(process.stdout)
		return loggers

	###*
	# Destructor. Destroy the caterpillar logger instances bound to DocPad
	# @private
	# @method {Object} destroyLoggers
	###
	destroyLoggers: ->
		if @loggerInstances
			for own key,value of @loggerInstances
				value.end()
		@

	###*
	# The action runner instance bound to docpad
	# @private
	# @property {Object} actionRunnerInstance
	###
	actionRunnerInstance: null

	###*
	# Get the action runner instance bound to docpad
	# @method getActionRunner
	# @return {Object} the action runner instance
	###
	getActionRunner: -> @actionRunnerInstance

	###*
	# Apply the passed DocPad action arguments
	# @method {Object} action
	# @param {Object} args
	# @return {Object}
	###
	action: (args...) -> docpadUtil.action.apply(@, args)


	###*
	# The error runner instance bound to DocPad
	# @property {Object} errorRunnerInstance
	###
	errorRunnerInstance: null

	###*
	# Get the error runner instance
	# @method {Object} getErrorRunner
	# @return {Object} the error runner instance
	###
	getErrorRunner: -> @errorRunnerInstance

	###*
	# The track runner instance bound to DocPad
	# @private
	# @property {Object} trackRunnerInstance
	###
	trackRunnerInstance: null

	###*
	# Get the track runner instance
	# @method getTrackRunner
	# @return {Object} the track runner instance
	###
	getTrackRunner: -> @trackRunnerInstance


	###*
	# Event Listing. String array of event names.
	# Whenever an event is created, it must be applied here to be available to plugins and configuration files
	# Events must be sorted by the order of execution, not for a functional need, but for a documentation need
	# Whenever this array changes, also update: https://docpad.org/docs/events/
	# @private
	# @property {Array} string array of event names
	###
	events: [
		'extendCollections'            # fired each load
		'extendTemplateData'           # fired each load
		'docpadLoaded'                 # fired multiple times, first time command line configuration hasn't been applied yet
		'docpadReady'                  # fired only once
		'docpadDestroy'                # fired once on shutdown
		'consoleSetup'                 # fired once
		'generateBefore'
		'populateCollectionsBefore'
		'populateCollections'
		'contextualizeBefore'
		'contextualizeAfter'
		'renderBefore'
		'renderCollectionBefore'
		'render'                       # fired for each extension conversion
		'renderDocument'               # fired for each document render, including layouts and render passes
		'renderCollectionAfter'
		'renderAfter'
		'writeBefore'
		'writeAfter'
		'generateAfter'
		'generated'
		'serverBefore'
		'serverExtend'
		'serverAfter'
		'notify'
	]

	###*
	# Get the list of available events
	# @method getEvents
	# @return {Object} string array of event names
	###
	getEvents: ->
		@events


	# ---------------------------------
	# Collections

	# Database collection

	###*
	# QueryEngine collection
	# @private
	# @property {Object} database
	###
	database: null

	###*
	# A FilesCollection of models updated
	# from the DocPad database after each regeneration.
	# @private
	# @property {Object} databaseTempCache FileCollection of models
	###
	databaseTempCache: null

	###*
	# Description for getDatabase
	# @method {Object} getDatabase
	###
	getDatabase: -> @database

	###*
	# Safe method for retrieving the database by
	# either returning the database itself or the temporary
	# database cache
	# @method getDatabaseSafe
	# @return {Object}
	###
	getDatabaseSafe: -> @databaseTempCache or @database

	###*
	# Destructor. Destroy the DocPad database
	# @private
	# @method destroyDatabase
	###
	destroyDatabase: ->
		if @database?
			@database.destroy()
			@database = null
		if @databaseTempCache?
			@databaseTempCache.destroy()
			@databaseTempCache = null
		@

	###*
	# Files by url. Used to speed up fetching
	# @private
	# @property {Object} filesByUrl
	###
	filesByUrl: null

	###*
	# Files by Selector. Used to speed up fetching
	# @private
	# @property {Object} filesBySelector
	###
	filesBySelector: null

	###*
	# Files by Out Path. Used to speed up conflict detection. Do not use for anything else
	# @private
	# @property {Object} filesByOutPath
	###
	filesByOutPath: null

	###*
	# Blocks
	# @private
	# @property {Object} blocks
	###
	blocks: null
	### {
		# A collection of meta elements
		meta: null  # Elements Collection

		# A collection of script elements
		scripts: null  # Scripts Collection

		# Collection of style elements
		styles: null  # Styles Collection
	} ###

	###*
	# Get a block by block name. Optionally clone block.
	# @method getBlock
	# @param {String} name
	# @param {Object} [clone]
	# @return {Object} block
	###
	getBlock: (name,clone) ->
		block = @blocks[name]
		if clone
			classname = name[0].toUpperCase()+name[1..]+'Collection'
			block = new @[classname](block.models)
		return block

	###*
	# Set a block by name and value
	# @method setBlock
	# @param {String} name
	# @param {Object} value
	###
	setBlock: (name,value) ->
		if @blocks[name]?
			@blocks[name].destroy()
			if value
				@blocks[name] = value
			else
				delete @blocks[name]
		else
			@blocks[name] = value
		@

	###*
	# Get all blocks
	# @method getBlocks
	# @return {Object} collection of blocks
	###
	getBlocks: -> @blocks

	###*
	# Set all blocks
	# @method setBlocks
	# @param {Object} blocks
	###
	setBlocks: (blocks) ->
		for own name,value of blocks
			@setBlock(name,value)
		@

	###*
	# Apply the passed function to each block
	# @method eachBlock
	# @param {Function} fn
	###
	eachBlock: (fn) ->
		eachr(@blocks, fn)
		@

	###*
	# Destructor. Destroy all blocks
	# @private
	# @method destroyBlocks
	###
	destroyBlocks: ->
		if @blocks
			for own name,block of @blocks
				block.destroy()
				@blocks[name] = null
		@

	###*
	# The DocPad collections
	# @private
	# @property {Object} collections
	###
	collections: null

	###*
	# Get a collection by collection name or key.
	# This is often accessed within the docpad.coffee
	# file or a layout/page via @getCollection.
	# Because getCollection returns a docpad collection,
	# a call to this method is often chained with a
	# QueryEngine style query.
	#
	# 	@getCollection('documents').findAllLive({relativeOutDirPath: 'posts'},[{date:-1}])
	#
	# @method getCollection
	# @param {String} value
	# @return {Object} collection
	###
	getCollection: (value) ->
		if value
			if typeof value is 'string'
				if value is 'database'
					return @getDatabase()

				else
					for collection in @collections
						if value in [collection.options.name, collection.options.key]
							return collection

			else
				for collection in @collections
					if value is collection
						return collection

		return null

	###*
	# Destroy a collection by collection name or key
	# @method destroyCollection
	# @param {String} value
	# @return {Object} description
	###
	destroyCollection: (value) ->
		if value
			if typeof value is 'string' and value isnt 'database'
				@collections = @collections.filter (collection) ->
					if value in [collection.options.name, collection.options.key]
						collection?.destroy()
						return false
					else
						return true

			else if value isnt @getDatabase()
				@collections = @collections.filter (collection) ->
					if value is collection
						collection?.destroy()
						return false
					else
						return true

		return null

	###*
	# Add a collection
	# @method addCollection
	# @param {Object} collection
	###
	addCollection: (collection) ->
		if collection and collection not in [@getDatabase(), @getCollection(collection)]
			@collections.push(collection)
		@

	###*
	# Set a name for a collection.
	# A collection can have multiple names
	#
	# The partials plugin (https://github.com/docpad/docpad-plugin-partials)
	# creates a live collection and passes this to setCollection with
	# the name 'partials'.
	#
	# 	# Add our partials collection
	#	docpad.setCollection('partials', database.createLiveChildCollection()
	#		.setQuery('isPartial', {
	#				$or:
	#					isPartial: true
	#					fullPath: $startsWith: config.partialsPath
	#		})
	#		.on('add', (model) ->
	#			docpad.log('debug', util.format(locale.addingPartial, model.getFilePath()))
	#			model.setDefaults(
	#				isPartial: true
	#				render: false
	#				write: false
	#			)
	#		)
	#	)
	#
	#
	# @method setCollection
	# @param {String} name the name to give to the collection
	# @param {Object} collection a DocPad collection
	###
	setCollection: (name, collection) ->
		if collection
			if name
				collection.options.name = name
				if @getCollection(name) isnt collection
					@destroyCollection(name)
			@addCollection(collection)
		else
			@destroyCollection(name)

	###*
	# Get the DocPad project's collections
	# @method getCollections
	# @return {Object} the collections
	###
	getCollections: ->
		return @collections

	###*
	# Set the DocPad project's collections
	# @method setCollections
	###
	setCollections: (collections) ->
		if Array.isArray(collections)
			for value in collections
				@addCollection(value)
		else
			for own name,value of collections
				@setCollection(name, value)
		@

	###*
	# Apply the passed function to each collection
	# @method eachCollection
	# @param {Function} fn
	###
	eachCollection: (fn) ->
		fn(@getDatabase(), 'database')
		for collection,index in @collections
			fn(collection, collection.options.name or collection.options.key or index)
		@

	###*
	# Destructor. Destroy the DocPad project's collections.
	# @private
	# @method destroyCollections
	###
	destroyCollections: ->
		if @collections
			for collection in @collections
				collection.destroy()
			@collections = []
		@


	# ---------------------------------
	# Collection Helpers

	###*
	# Get all the files in the DocPad database (will use live collections)
	# @method getFiles
	# @param {Object} query
	# @param {Object} sorting
	# @param {Object} paging
	# @return {Object} collection
	###
	getFiles: (query,sorting,paging) ->
		key = JSON.stringify({query, sorting, paging})
		collection = @getCollection(key)
		unless collection
			collection = @getDatabase().findAllLive(query, sorting, paging)
			collection.options.key = key
			@addCollection(collection)
		return collection


	###*
	# Get a single file based on a query
	# @method getFile
	# @param {Object} query
	# @param {Object} sorting
	# @param {Object} paging
	# @return {Object} a file
	###
	getFile: (query,sorting,paging) ->
		file = @getDatabase().findOne(query, sorting, paging)
		return file

	###*
	# Get files at a path
	# @method getFilesAtPath
	# @param {String} path
	# @param {Object} sorting
	# @param {Object} paging
	# @return {Object} files
	###
	getFilesAtPath: (path,sorting,paging) ->
		query = $or: [{relativePath: $startsWith: path}, {fullPath: $startsWith: path}]
		files = @getFiles(query, sorting, paging)
		return files

	###*
	# Get a file at a relative or absolute path or url
	# @method getFileAtPath
	# @param {String} path
	# @param {Object} sorting
	# @param {Object} paging
	# @return {Object} a file
	###
	getFileAtPath: (path,sorting,paging) ->
		file = @getDatabase().fuzzyFindOne(path, sorting, paging)
		return file


	# TODO: Does this still work???
	###*
	# Get a file by its url
	# @method getFileByUrl
	# @param {String} url
	# @param {Object} [opts={}]
	# @return {Object} a file
	###
	getFileByUrl: (url,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(@filesByUrl[url])
		return file


	###*
	# Get a file by its id
	# @method getFileById
	# @param {String} id
	# @param {Object} [opts={}]
	# @return {Object} a file
	###
	getFileById: (id,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(id)
		return file


	###*
	# Remove the query string from a url
	# Pathname convention taken from document.location.pathname
	# @method getUrlPathname
	# @param {String} url
	# @return {String}
	###
	getUrlPathname: (url) ->
		return url.replace(/\?.*/,'')

	###*
	# Get a file by its route and return
	# it to the supplied callback.
	# @method getFileByRoute
	# @param {String} url
	# @param {Object} next
	# @param {Error} next.err
	# @param {String} next.file
	###
	getFileByRoute: (url,next) ->
		# Prepare
		docpad = @

		# If we have not performed a generation yet then wait until the initial generation has completed
		if docpad.generated is false
			# Wait until generation has completed and recall ourselves
			docpad.once 'generated', ->
				return docpad.getFileByRoute(url, next)

			# hain
			return @

		# @TODO the above causes a signifcant delay when importing external documents (like tumblr data) into the database
		# we need to figure out a better way of doing this
		# perhaps it is via `writeSource: once` for imported documents
		# or providing an option to disable this so it forward onto the static handler instead

		# Prepare
		database = docpad.getDatabaseSafe()

		# Fetch
		cleanUrl = docpad.getUrlPathname(url)
		file = docpad.getFileByUrl(url, {collection:database}) or docpad.getFileByUrl(cleanUrl, {collection:database})

		# Forward
		next(null, file)

		# Chain
		@


	# TODO: What on earth is a selector?
	###*
	# Get a file by its selector
	# @method getFileBySelector
	# @param {Object} selector
	# @param {Object} [opts={}]
	# @return {Object} a file
	###
	getFileBySelector: (selector,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.get(@filesBySelector[selector])
		unless file
			file = opts.collection.fuzzyFindOne(selector)
			if file
				@filesBySelector[selector] = file.id
		return file


	# ---------------------------------
	# Skeletons


	###*
	# Skeletons Collection
	# @private
	# @property {Object} skeletonsCollection
	###
	skeletonsCollection: null

	###*
	# Get Skeletons
	# Get all the available skeletons with their details and
	# return this collection to the supplied callback.
	# @method getSkeletons
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.skeletonsCollection DocPad collection of skeletons
	# @return {Object} DocPad skeleton collection
	###
	getSkeletons: (next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Check if we have cached locally
		if @skeletonsCollection?
			return next(null, @skeletonsCollection)

		# Fetch the skeletons from the exchange
		@skeletonsCollection = new Collection()
		@skeletonsCollection.comparator = queryEngine.generateComparator(position:1, name:1)
		@getExchange (err,exchange) ->
			# Check
			return next(err)  if err

			# Prepare
			index = 0

			# If we have the exchange data, then add the skeletons from it
			if exchange
				eachr exchange.skeletons, (skeleton, skeletonKey) ->
					skeleton.id ?= skeletonKey
					skeleton.name ?= skeletonKey
					skeleton.position ?= index
					docpad.skeletonsCollection.add(new Model(skeleton))
					++index

			# Add No Skeleton Option
			docpad.skeletonsCollection.add(new Model(
				id: 'none'
				name: locale.skeletonNoneName
				description: locale.skeletonNoneDescription
				position: index
			))

			# Return Collection
			return next(null, docpad.skeletonsCollection)
		@


	# ---------------------------------
	# Plugins


	###*
	# Plugins that are loading really slow
	# @property {Object} slowPlugins
	###
	slowPlugins: null  # {}

	###*
	# Loaded plugins indexed by name
	# @property {Object} loadedPlugins
	###
	loadedPlugins: null  # {}

	###*
	# A listing of all the available extensions for DocPad
	# @property {Object} exchange
	###
	exchange: null  # {}

	# -----------------------------
	# Paths

	###*
	# The DocPad directory
	# @property {String} corePath
	###
	corePath: corePath

	###*
	# The DocPad library directory
	# @private
	# @property {String} libPath
	###
	libPath: __dirname

	###*
	# The main DocPad file
	# @property {String} mainPath
	###
	mainPath: pathUtil.resolve(__dirname, 'docpad')

	###*
	# The DocPad package.json path
	# @property {String} packagePath
	###
	packagePath: pathUtil.resolve(__dirname, '..', '..', 'package.json')

	###*
	# The DocPad locale path
	# @property {String} localePath
	###
	localePath: pathUtil.resolve(__dirname, '..', '..', 'locale')

	###*
	# The DocPad debug log path (docpad-debug.log)
	# @property {String} debugLogPath
	###
	debugLogPath: pathUtil.join(process.cwd(), 'docpad-debug.log')

	###*
	# The User's configuration path (.docpad.cson)
	# @property {String} userConfigPath
	###
	userConfigPath: '.docpad.cson'

	# -----------------------------
	# Template Data


	###*
	# Description for initialTemplateData
	# @private
	# @property {Object} initialTemplateData
	###
	initialTemplateData: null  # {}

	###*
	# Plugin's Extended Template Data
	# @private
	# @property {Object} pluginsTemplateData
	###
	pluginsTemplateData: null  # {}

	###*
	# Get Complete Template Data
	# @method getTemplateData
	# @param {Object} userTemplateData
	# @return {Object} templateData
	###
	getTemplateData: (userTemplateData) ->
		# Prepare
		userTemplateData or= {}
		docpad = @
		locale = @getLocale()

		# Set the initial docpad template data
		@initialTemplateData ?=
			# Site Properties
			site: {}

			# Environment
			getEnvironment: ->
				return docpad.getEnvironment()

			# Environments
			getEnvironments: ->
				return docpad.getEnvironments()

			# Set that we reference other files
			referencesOthers: (flag) ->
				document = @getDocument()
				document.referencesOthers()
				return null

			# Get the Document
			getDocument: ->
				return @documentModel

			# Get a Path in respect to the current document
			getPath: (path,parentPath) ->
				document = @getDocument()
				path = document.getPath(path, parentPath)
				return path

			# Get Files
			getFiles: (query,sorting,paging) ->
				@referencesOthers()
				result = docpad.getFiles(query, sorting, paging)
				return result

			# Get another file's URL based on a relative path
			getFile: (query,sorting,paging) ->
				@referencesOthers()
				result = docpad.getFile(query,sorting,paging)
				return result

			# Get Files At Path
			getFilesAtPath: (path,sorting,paging) ->
				@referencesOthers()
				path = @getPath(path)
				result = docpad.getFilesAtPath(path, sorting, paging)
				return result

			# Get another file's model based on a relative path
			getFileAtPath: (relativePath) ->
				@referencesOthers()
				path = @getPath(relativePath)
				result = docpad.getFileAtPath(path)
				return result

			# Get a specific file by its id
			getFileById: (id) ->
				@referencesOthers()
				result = docpad.getFileById(id)
				return result

			# Get the entire database
			getDatabase: ->
				@referencesOthers()
				return docpad.getDatabase()

			# Get a pre-defined collection
			getCollection: (name) ->
				@referencesOthers()
				return docpad.getCollection(name)

			# Get a block
			getBlock: (name) ->
				return docpad.getBlock(name,true)

			# Include another file taking in a relative path
			include: (subRelativePath,strict=true) ->
				file = @getFileAtPath(subRelativePath)
				if file
					if strict and file.get('rendered') is false
						if docpad.getConfig().renderPasses is 1
							docpad.warn util.format(locale.renderedEarlyViaInclude, subRelativePath)
						return null
					return file.getOutContent()
				else
					err = new Error(util.format(locale.includeFailed, subRelativePath))
					throw err

		# Fetch our result template data
		templateData = extendr.extend({}, @initialTemplateData, @pluginsTemplateData, @getConfig().templateData, userTemplateData)

		# Add site data
		templateData.site.url or= @getSimpleServerUrl()
		templateData.site.date or= new Date()
		templateData.site.keywords or= []
		if typeChecker.isString(templateData.site.keywords)
			templateData.site.keywords = templateData.site.keywords.split(/,\s*/g)

		# Return
		templateData


	# -----------------------------
	# Locales

	###*
	# Determined locale
	# @private
	# @property {Object} locale
	###
	locale: null


	###*
	# Get the locale (language code and locale code)
	# @method getLocale
	# @return {Object} locale
	###
	getLocale: ->
		if @locale? is false
			config = @getConfig()
			codes = uniq [
				'en'
				safeps.getLanguageCode config.localeCode
				safeps.getLanguageCode safeps.getLocaleCode()
				safeps.getLocaleCode   config.localeCode
				safeps.getLocaleCode   safeps.getLocaleCode()
			]
			locales = (@loadLocale(code)  for code in codes)
			@locale = extendr.extend(locales...)

		return @locale

	###*
	# Load the locale
	# @method loadLocale
	# @param {String} code
	# @return {Object} locale
	###
	loadLocale: (code) ->
		# Prepare
		docpad = @

		# Check if it exists
		localeFilename = "#{code}.cson"
		localePath = pathUtil.join(@localePath, localeFilename)
		return null  unless safefs.existsSync(localePath)

		# Load it
		locale = CSON.parseCSONFile(localePath)

		# Log the error in the background and continue
		if locale instanceof Error
			locale.context = "Failed to parse the CSON locale file: #{localePath}"
			docpad.error(locale)  # @TODO: should this be a fatal error instead?
			return null

		# Success
		return locale


	# -----------------------------
	# Environments


	###*
	# Get the DocPad environment, eg: development,
	# production or static
	# @method getEnvironment
	# @return {String} the environment
	###
	getEnvironment: ->
		env = @getConfig().env or 'development'
		return env

	###*
	# Get the environments
	# @method getEnvironments
	# @return {Array} array of environment strings
	###
	getEnvironments: ->
		env = @getEnvironment()
		envs = env.split(/[, ]+/)
		return envs


	# -----------------------------
	# Configuration

	###*
	# Hash Key
	# The key that we use to hash some data before sending it to our statistic server
	# @private
	# @property {String} string constant
	###
	hashKey: '7>9}$3hP86o,4=@T'  # const

	###*
	# Website Package Configuration
	# @private
	# @property {Object} websitePackageConfig
	###
	websitePackageConfig: null  # {}

	###*
	# Merged Configuration
	# Merged in the order of:
	# - initialConfig
	# - userConfig
	# - websiteConfig
	# - instanceConfig
	# - environmentConfig
	# Use getConfig to retrieve this value
	# @private
	# @property {Object} config
	###
	config: null  # {}


	###*
	# Instance Configuration

	# @private
	# @property {Object} instanceConfig
	###
	instanceConfig: null  # {}

	###*
	# Website Configuration
	# Merged into the config property
	# @private
	# @property {Object} websiteConfig
	###
	websiteConfig: null  # {}

	###*
	# User Configuraiton
	# Merged into the config property
	# @private
	# @property {Object} userConfig
	###
	userConfig:
		# Name
		name: null

		# Email
		email: null

		# Username
		username: null

		# Subscribed
		subscribed: null

		# Subcribe Try Again
		# If our subscription has failed, when should we try again?
		subscribeTryAgain: null

		# Terms of Service
		tos: null

		# Identified
		identified: null

	###*
	# Initial Configuration. The default docpadConfig
	# settings that can be overridden in a project's docpad.coffee file.
	# Merged into the config property
	# @private
	# @property {Object} initialConfig
	###
	initialConfig:

		# -----------------------------
		# Plugins

		# Force re-install of all plugin dependencies
		force: false

		# Whether or not we should use the global docpad instance
		global: false

		# Whether or not we should enable plugins that have not been listed or not
		enableUnlistedPlugins: true

		# Plugins which should be enabled or not pluginName: pluginEnabled
		enabledPlugins: {}

		# Whether or not we should skip unsupported plugins
		skipUnsupportedPlugins: true

		# Whether or not to warn about uncompiled private plugins
		warnUncompiledPrivatePlugins: true

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: {}


		# -----------------------------
		# Project Paths

		# The project directory
		rootPath: process.cwd()

		# The project's database cache path
		databaseCachePath: '.docpad.db'

		# The project's package.json path
		packagePath: 'package.json'

		# The project's configuration paths
		# Reads only the first one that exists
		# If you want to read multiple configuration paths, then point it to a coffee|js file that requires
		# the other paths you want and exports the merged config
		configPaths: [
			'docpad.js'
			'docpad.coffee'
			'docpad.json'
			'docpad.cson'
		]

		# Plugin directories to load
		pluginPaths: []

		# The project's plugins directory
		pluginsPaths: [
			'node_modules'
			'plugins'
		]

		# Paths that we should watch for reload changes in
		reloadPaths: []

		# Paths that we should watch for regeneration changes in
		regeneratePaths: []

		# The time to wait after a source file has changed before using it to regenerate
		regenerateDelay: 100

		# The time to wait before outputting the files we are waiting on
		slowFilesDelay: 20*1000

		# The project's out directory
		outPath: 'out'

		# The project's src directory
		srcPath: 'src'

		# The project's documents directories
		# relative to the srcPath
		documentsPaths: [
			'documents'
			'render'
		]

		# The project's files directories
		# relative to the srcPath
		filesPaths: [
			'files'
			'static'
			'public'
		]

		# The project's layouts directory
		# relative to the srcPath
		layoutsPaths: [
			'layouts'
		]

		# Ignored file patterns during directory parsing
		ignorePaths: false
		ignoreHiddenFiles: false
		ignoreCommonPatterns: true
		ignoreCustomPatterns: false

		# Watch options
		watchOptions: null


		# -----------------------------
		# Server

		# Port
		# The port that the server should use
		# Defaults to these environment variables:
		# - PORT — Heroku, Nodejitsu, Custom
		# - VCAP_APP_PORT — AppFog
		# - VMC_APP_PORT — CloudFoundry
		port: null

		# Hostname
		# The hostname we wish to listen to
		# Defaults to these environment variables:
		# HOSTNAME — Generic
		# Do not set to "localhost" it does not work on heroku
		hostname: null

		# Max Age
		# The caching time limit that is sent to the client
		maxAge: 86400000

		# Server
		# The Express.js server that we want docpad to use
		serverExpress: null
		# The HTTP server that we want docpad to use
		serverHttp: null

		# Extend Server
		# Whether or not we should extend the server with extra middleware and routing
		extendServer: true

		# Which middlewares would you like us to activate
		# The standard middlewares (bodyParser, methodOverride, express router)
		middlewareStandard: true
		# The standard bodyParser middleware
		middlewareBodyParser: true
		# The standard methodOverride middleware
		middlewareMethodOverride: true
		# The standard express router middleware
		middlewareExpressRouter: true
		# Our own 404 middleware
		middleware404: true
		# Our own 500 middleware
		middleware500: true


		# -----------------------------
		# Logging

		# Log Level
		# Which level of logging should we actually output
		logLevel: (if ('-d' in process.argv) then 7 else 6)

		# Catch uncaught exceptions
		catchExceptions: true

		# Report Errors
		# Whether or not we should report our errors back to DocPad
		# By default it is only enabled if we are not running inside a test
		reportErrors: process.argv.join('').indexOf('test') is -1

		# Report Statistics
		# Whether or not we should report statistics back to DocPad
		# By default it is only enabled if we are not running inside a test
		reportStatistics: process.argv.join('').indexOf('test') is -1

		# Color
		# Whether or not our terminal output should have color
		# `null` will default to what the terminal supports
		color: null


		# -----------------------------
		# Other

		# Utilise the database cache
		databaseCache: false  # [false, true, 'write']

		# Detect Encoding
		# Should we attempt to auto detect the encoding of our files?
		# Useful when you are using foreign encoding (e.g. GBK) for your files
		detectEncoding: false

		# Render Single Extensions
		# Whether or not we should render single extensions by default
		renderSingleExtensions: false

		# Render Passes
		# How many times should we render documents that reference other documents?
		renderPasses: 1

		# Offline
		# Whether or not we should run in offline mode
		# Offline will disable the following:
		# - checkVersion
		# - reportErrors
		# - reportStatistics
		offline: false

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: false

		# Welcome
		# Whether or not we should display any custom welcome callbacks
		welcome: false

		# Prompts
		# Whether or not we should display any prompts
		prompts: false

		# Progress
		# Whether or not we should display any progress bars
		# Requires prompts being true, and log level 6 or above
		progress: true

		# Powered By DocPad
		# Whether or not we should include DocPad in the Powered-By meta header
		# Please leave this enabled as it is a standard practice and promotes DocPad in the web eco-system
		poweredByDocPad: true

		# Helper Url
		# Used for subscribing to newsletter, account information, and statistics etc
		# Helper's source-code can be found at: https://github.com/docpad/helper
		helperUrl: if true then 'http://helper.docpad.org/' else 'http://localhost:8000/'

		# Safe Mode
		# If enabled, we will try our best to sandbox our template rendering so that they cannot modify things outside of them
		# Not yet implemented
		safeMode: false

		# Template Data
		# What data would you like to expose to your templates
		templateData: {}

		# Collections
		# A hash of functions that create collections
		collections: {}

		# Events
		# A hash of event handlers
		events: {}

		# Regenerate Every
		# Performs a regenerate every x milliseconds, useful for always having the latest data
		regenerateEvery: false

		# Regerenate Every Options
		# The generate options to use on the regenerate every call
		regenerateEveryOptions:
			populate: true
			partial:  false


		# -----------------------------
		# Environment Configuration

		# Locale Code
		# The code we shall use for our locale (e.g. en, fr, etc)
		localeCode: null

		# Environment
		# Whether or not we are in production or development
		# Separate environments using a comma or a space
		env: null

		# Environments
		# Environment specific configuration to over-ride the global configuration
		environments:
			development:
				# Always refresh from server
				maxAge: false

				# Only do these if we are running standalone (aka not included in a module)
				checkVersion: isUser
				welcome: isUser
				prompts: isUser

	###*
	# Regenerate Timer
	# When config.regenerateEvery is set to a value, we create a timer here
	# @private
	# @property {Object} regenerateTimer
	###
	regenerateTimer: null

	###*
	# Get the DocPad configuration. Commonly
	# called within the docpad.coffee file or within
	# plugins to access application specific configurations.
	# 	serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				...
	# @method getConfig
	# @return {Object} the DocPad configuration object
	###
	getConfig: ->
		return @config or {}

	###*
	# Get the port that DocPad is listening on (eg 9778)
	# @method getPort
	# @return {Number} the port number
	###
	getPort: ->
		return @getConfig().port ? require('hostenv').PORT ? 9778

	###*
	# Get the Hostname
	# @method getHostname
	# @return {String}
	###
	getHostname: ->
		return @getConfig().hostname ? require('hostenv').HOSTNAME ? '0.0.0.0'

	###*
	# Get address
	# @method getServerUrl
	# @param {Object} [opts={}]
	# @return {String}
	###
	getServerUrl: (opts={}) ->
		opts.hostname ?= @getHostname()
		opts.port ?= @getPort()
		opts.simple ?= false
		if opts.simple is true and opts.hostname in ['0.0.0.0', '::', '::1']
			return "http://127.0.0.1:#{opts.port}"
		else
			return "http://#{opts.hostname}:#{opts.port}"

	###*
	# Get simple server URL (changes 0.0.0.0, ::, and ::1 to 127.0.0.1)
	# @method getSimpleServerUrl
	# @param {Object} [opts={}]
	# @param {Boolean} [opts.simple=true]
	# @return {String}
	###
	getSimpleServerUrl: (opts={}) ->
		opts.simple = true
		return @getServerUrl(opts)


	# =================================
	# Initialization Functions

	###*
	# Constructor method. Sets up the DocPad instance.
	# next(err)
	# @method constructor
	# @param {Object} instanceConfig
	# @param {Function} next callback
	# @param {Error} next.err
	###
	constructor: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig, next)
		docpad = @

		# Create our own custom TaskGroup class for DocPad
		# That will listen to tasks as they execute and provide debugging information
		@TaskGroup = class extends TaskGroup
			constructor: ->
				# Prepare
				super
				tasks = @

				# Listen to executing tasks and output their progress
				tasks.on 'started', ->
					config = tasks.getConfig()
					name = tasks.getNames()
					progress = config.progress
					if progress
						totals = tasks.getItemTotals()
						progress.step(name).total(totals.total).setTick(totals.completed)
					else
						docpad.log('debug', name+' > started')

				# Listen to executing tasks and output their progress
				tasks.on 'item.add', (item) ->
					config = tasks.getConfig()
					name = item.getNames()
					progress = config.progress
					if progress
						totals = tasks.getItemTotals()
						progress.step(name).total(totals.total).setTick(totals.completed)
					else
						docpad.log('debug', name+' > added')

				# Listen to executing tasks and output their progress
				tasks.on 'item.started', (item) ->
					config = tasks.getConfig()
					name = item.getNames()
					progress = config.progress
					if progress
						totals = tasks.getItemTotals()
						progress.step(name).total(totals.total).setTick(totals.completed)
					else
						docpad.log('debug', name+' > started')

				# Listen to executing tasks and output their progress
				tasks.on 'item.done', (item, err) ->
					config = tasks.getConfig()
					name = item.getNames()
					progress = config.progress
					if progress
						totals = tasks.getItemTotals()
						progress.step(name).total(totals.total).setTick(totals.completed)
					else
						docpad.log('debug', name+' > done')

				# Chain
				@

		# Binders
		# Using this over coffescript's => on class methods, ensures that the method length is kept
		for methodName in """
			action
			log warn error fatal inspector notify track identify subscribe checkRequest
			serverMiddlewareRouter serverMiddlewareHeader serverMiddleware404 serverMiddleware500
			destroyWatchers
			""".split(/\s+/)
			@[methodName] = @[methodName].bind(@)

		# Allow DocPad to have unlimited event listeners
		@setMaxListeners(0)

		# Setup configuration event wrappers
		configEventContext = {docpad}  # here to allow the config event context to persist between event calls
		@getEvents().forEach (eventName) ->
			# Bind to the event
			docpad.on eventName, (opts,next) ->
				eventHandler = docpad.getConfig().events?[eventName]
				# Fire the config event handler for this event, if it exists
				if typeChecker.isFunction(eventHandler)
					args = [opts,next]
					ambi(eventHandler.bind(configEventContext), args...)
				# It doesn't exist, so lets continue
				else
					next()

		# Create our action runner
		@actionRunnerInstance = @TaskGroup.create('action runner').whenDone (err) ->
			docpad.error(err)  if err

		# Create our track runner
		@trackRunnerInstance = @TaskGroup.create('track runner').whenDone (err) ->
			if err and docpad.getDebugging()
				locale = docpad.getLocale()
				docpad.warn(locale.trackError, err)

		# Initialize the loggers
		if (loggers = instanceConfig.loggers)
			delete instanceConfig.loggers
		else
			# Create
			logger = new (require('caterpillar').Logger)(lineOffset: 2)

			# console
			loggerConsole = logger
				.pipe(
					new (require('caterpillar-filter').Filter)
				)
				.pipe(
					new (require('caterpillar-human').Human)
				)

			# Apply
			loggers = {logger, console:loggerConsole}

		# Apply the loggers
		safefs.unlink(@debugLogPath, -> )  # Remove the old debug log file
		@setLoggers(loggers)  # Apply the logger streams
		@setLogLevel(instanceConfig.logLevel ? @initialConfig.logLevel)  # Set the default log level

		# Log to bubbled events
		@on 'log', (args...) ->
			docpad.log.apply(@,args)

		# Dereference and initialise advanced variables
		# we deliberately ommit initialTemplateData here, as it is setup in getTemplateData
		@slowPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@pluginsTemplateData = {}
		@instanceConfig = {}
		@collections = []
		@blocks = {}
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}
		@database = new FilesCollection(null, {name:'database'})
			.on('remove', (model,options) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the urls
				for url in model.get('urls') or []
					delete docpad.filesByUrl[url]

				# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
				outPath = model.get('outPath')
				if outPath
					updatedModels = docpad.database.findAll({outPath})
					updatedModels.remove(model)
					updatedModels.each (model) ->
						model.set('mtime': new Date())

					# Log
					docpad.log('debug', 'Updated mtime for these models due to remove of a similar one', updatedModels.pluck('relativePath'))

				# Return safely
				return true
			)
			.on('add change:urls', (model) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Delete the old urls
				for url in model.previous('urls') or []
					delete docpad.filesByUrl[url]

				# Add the new urls
				for url in model.get('urls')
					docpad.filesByUrl[url] = model.cid

				# Return safely
				return true
			)
			.on('add change:outPath', (model) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Check if we have changed our outPath
				previousOutPath = model.previous('outPath')
				if previousOutPath
					# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
					previousModels = docpad.database.findAll(outPath:previousOutPath)
					previousModels.remove(model)
					previousModels.each (model) ->
						model.set('mtime': new Date())

					# Log
					docpad.log('debug', 'Updated mtime for these models due to addition of a similar one', previousModels.pluck('relativePath'))

					# Update the cache entry with another file that has the same outPath or delete it if there aren't any others
					previousModelId = docpad.filesByOutPath[previousOutPath]
					if previousModelId is model.id
						if previousModels.length
							docpad.filesByOutPath[previousOutPath] = previousModelId
						else
							delete docpad.filesByOutPath[previousOutPath]

				# Update the cache entry and fetch the latest if it was already set
				if (outPath = model.get('outPath'))
					existingModelId = docpad.filesByOutPath[outPath] ?= model.id
					if existingModelId isnt model.id
						existingModel = docpad.database.get(existingModelId)
						if existingModel
							# We have a conflict, let the user know
							modelPath = model.get('fullPath') or (model.get('relativePath')+':'+model.id)
							existingModelPath = existingModel.get('fullPath') or (existingModel.get('relativePath')+':'+existingModel.id)
							docpad.warn util.format(docpad.getLocale().outPathConflict, outPath, modelPath, existingModelPath)
						else
							# There reference was old, update it with our new one
							docpad.filesByOutPath[outPath] = model.id

				# Return safely
				return true
			)
		@userConfig = extendr.dereference(@userConfig)
		@initialConfig = extendr.dereference(@initialConfig)

		# Extract action
		if instanceConfig.action?
			action = instanceConfig.action
		else
			action = 'load ready'

		# Check if we want to perform an action
		if action
			@action action, instanceConfig, (err) ->
				if next?
					next(err, docpad)
				else if err
					docpad.fatal(err)
		else
			next?(null, docpad)

		# Chain
		@

	###*
	# Destructor. Destroy the DocPad instance
	# This is an action, and should be called as such
	# E.g. docpad.action('destroy', next)
	# @method destroy
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	destroy: (opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @

		# Destroy Regenerate Timer
		docpad.destroyRegenerateTimer()

		# Wait one second to wait for any logging to complete
		docpadUtil.wait 1000, ->

			# Destroy Plugins
			docpad.emitSerial 'docpadDestroy', (err) ->
				# Check
				return next?(err)  if err

				# Destroy Plugins
				docpad.destroyPlugins()

				# Destroy Server
				docpad.destroyServer()

				# Destroy Watchers
				docpad.destroyWatchers()

				# Destroy Blocks
				docpad.destroyBlocks()

				# Destroy Collections
				docpad.destroyCollections()

				# Destroy Database
				docpad.destroyDatabase()

				# Destroy Logging
				docpad.destroyLoggers()

				# Destroy Process Listners
				process.removeListener('uncaughtException', docpad.error)

				# Destroy DocPad Listeners
				docpad.removeAllListeners()

				# Forward
				return next?()

		# Chain
		@

	###*
	# Emit event, serial
	# @private
	# @method emitSerial
	# @param {String} eventName
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	emitSerial: (eventName, opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = docpad.getLocale()

		# Log
		docpad.log 'debug', util.format(locale.emittingEvent, eventName)

		# Emit
		super eventName, opts, (err) ->
			# Check
			return next(err)  if err

			# Log
			docpad.log 'debug', util.format(locale.emittedEvent, eventName)

			# Forward
			return next(err)

		# Chain
		@

	###*
	# Emit event, parallel
	# @private
	# @method emitParallel
	# @param {String} eventName
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	emitParallel: (eventName, opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = docpad.getLocale()

		# Log
		docpad.log 'debug', util.format(locale.emittingEvent, eventName)

		# Emit
		super eventName, opts, (err) ->
			# Check
			return next(err)  if err

			# Log
			docpad.log 'debug', util.format(locale.emittedEvent, eventName)

			# Forward
			return next(err)

		# Chain
		@


	# =================================
	# Helpers

	###*
	# Get the ignore options for the DocPad project
	# @method getIgnoreOpts
	# @return {Array} string array of ignore options
	###
	getIgnoreOpts: ->
		return pick(@config, ['ignorePaths', 'ignoreHiddenFiles', 'ignoreCommonPatterns', 'ignoreCustomPatterns'])

	###*
	# Is the supplied path ignored?
	# @method isIgnoredPath
	# @param {String} path
	# @param {Object} [opts={}]
	# @return {Boolean}
	###
	isIgnoredPath: (path,opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts)
		return ignorefs.isIgnoredPath(path, opts)

	###*
	# Scan directory
	# @method scandir
	# @param {Object} [opts={}]
	###
	#NB: How does this work? What is returned?
	#Does it require a callback (next) passed as
	#one of the options
	scandir: (opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts)
		return scandir(opts)

	###*
	# Watch Directory. Wrapper around the Bevry watchr
	# module (https://github.com/bevry/watchr). Used
	# internally by DocPad to watch project documents
	# and files and then activate the regeneration process
	# when any of those items are updated.
	#
	# Although it is possible to pass a range of options to watchdir
	# in practice these options are provided as part of
	# the DocPad config object with a number of default options
	# specified in the DocPad config.
	# @method watchdir
	# @param {Object} [opts={}]
	# @param {String} [opts.path] a single path to watch.
	# @param {Array} [opts.paths] an array of paths to watch.
	# @param {Function} [opts.listener] a single change listener to fire when a change occurs.
	# @param {Array} [opts.listeners] an array of listeners.
	# @param {Function} [opts.next] callback.
	# @param {Object} [opts.stat] a file stat object to use for the path, instead of fetching a new one.
	# @param {Number} [opts.interval=5007] for systems that poll to detect file changes, how often should it poll in millseconds.
	# @param {Number} [opts.catupDelay=200] handles system swap file deletions and renaming
	# @param {Array} [opts.preferredMethods=['watch','watchFile'] which order should we prefer our watching methods to be tried?.
	# @param {Boolean} [opts.followLinks=true] follow symlinks, i.e. use stat rather than lstat.
	# @param {Boolean|Array} [opts.ignorePaths=false] an array of full paths to ignore.
	# @param {Boolean|Array} [opts.ignoreHiddenFiles=false] whether or not to ignored files which filename starts with a ".".
	# @param {Boolean} [opts.ignoreCommonPatterns=true] whether or not to ignore common undesirable file patterns (e.g. .svn, .git, .DS_Store, thumbs.db, etc).
	# @param {Boolean|Array} [opts.ignoreCustomPatterns=null] any custom ignore patterns that you would also like to ignore along with the common patterns.
	# @return {Object} the watcher
	###
	watchdir: (opts={}) ->
		opts = extendr.extend(@getIgnoreOpts(), opts, @config.watchOptions)
		return require('watchr').watch(opts)


	# =================================
	# Setup and Loading

	###*
	# DocPad is ready. Peforms the tasks needed after DocPad construction
	# and DocPad has loaded. Triggers the docpadReady event.
	# next(err,docpadInstance)
	# @private
	# @method ready
	# @param {Object} [opts]
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.docpadInstance
	###
	ready: (opts,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Render Single Extensions
		@DocumentModel::defaults.renderSingleExtensions = config.renderSingleExtensions

		# Version Check
		@compareVersion()

		# Welcome Prepare
		if @getDebugging()
			pluginsList = ("#{pluginName} v#{@loadedPlugins[pluginName].version}"  for pluginName in Object.keys(@loadedPlugins).sort()).join(', ')
		else
			pluginsList = Object.keys(@loadedPlugins).sort().join(', ')

		# Welcome Output
		docpad.log 'info', util.format(locale.welcome, @getVersionString())
		docpad.log 'notice', locale.welcomeDonate
		docpad.log 'info', locale.welcomeContribute
		docpad.log 'info', util.format(locale.welcomePlugins, pluginsList)
		docpad.log 'info', util.format(locale.welcomeEnvironment, @getEnvironment())

		# Prepare
		tasks = new @TaskGroup 'ready tasks', next:(err) ->
			# Error?
			return docpad.error(err)  if err

			# All done, forward our DocPad instance onto our creator
			return next?(null,docpad)

		tasks.addTask 'welcome event', (complete) ->
			# No welcome
			return complete()  unless config.welcome

			# Welcome
			docpad.emitSerial('welcome', {docpad}, complete)

		tasks.addTask 'track', (complete) ->
			# Identify
			return docpad.identify(complete)

		tasks.addTask 'emit docpadReady', (complete) ->
			docpad.emitSerial('docpadReady', {docpad}, complete)

		# Run tasks
		tasks.run()

		# Chain
		@

	###*
	# Performs the merging of the passed configuration objects
	# @private
	# @method mergeConfigurations
	# @param {Object} configPackages
	# @param {Object} configsToMerge
	###
	mergeConfigurations: (configPackages,configsToMerge) ->
		# Prepare
		envs = @getEnvironments()

		# Figure out merging
		for configPackage in configPackages
			continue  unless configPackage
			configsToMerge.push(configPackage)
			for env in envs
				envConfig = configPackage.environments?[env]
				configsToMerge.push(envConfig)  if envConfig

		# Merge
		extendr.safeDeepExtendPlainObjects(configsToMerge...)

		# Chain
		@

	###*
	# Set the instance configuration
	# by merging the properties of the passed object
	# with the existing DocPad instanceConfig object
	# @private
	# @method setInstanceConfig
	# @param {Object} instanceConfig
	###
	setInstanceConfig: (instanceConfig) ->
		# Merge in the instance configurations
		if instanceConfig
			logLevel = @getLogLevel()
			extendr.safeDeepExtendPlainObjects(@instanceConfig, instanceConfig)
			extendr.safeDeepExtendPlainObjects(@config, instanceConfig)  if @config  # @TODO document why there is the if
			@setLogLevel(instanceConfig.logLevel)  if instanceConfig.logLevel and instanceConfig.logLevel isnt logLevel
		@

	###*
	# Set the DocPad configuration object.
	# Performs a number of tasks, including
	# merging the pass instanceConfig with DocPad's
	# other config objects.
	# next(err,config)
	# @private
	# @method setConfig
	# @param {Object} instanceConfig
	# @param {Object} next
	# @param {Error} next.err
	# @param {Object} next.config
	###
	setConfig: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()

		# Apply the instance configuration, generally we won't have it at this level
		# as it would have been applied earlier the load step
		@setInstanceConfig(instanceConfig)  if instanceConfig

		# Apply the environment
		# websitePackageConfig.env is left out of the detection here as it is usually an object
		# that is already merged with our process.env by the environment runner
		# rather than a string which is the docpad convention
		@config.env = @instanceConfig.env or @websiteConfig.env or @initialConfig.env or process.env.NODE_ENV

		# Merge configurations
		configPackages = [@initialConfig, @userConfig, @websiteConfig, @instanceConfig]
		configsToMerge = [@config]
		docpad.mergeConfigurations(configPackages, configsToMerge)

		# Extract and apply the server
		@setServer extendr.safeShallowExtendPlainObjects({
			serverHttp: @config.serverHttp
			serverExpress: @config.serverExpress
		},  @config.server)

		# Extract and apply the logger
		@setLogLevel(@config.logLevel)

		# Resolve any paths
		@config.rootPath = pathUtil.resolve(@config.rootPath)
		@config.outPath = pathUtil.resolve(@config.rootPath, @config.outPath)
		@config.srcPath = pathUtil.resolve(@config.rootPath, @config.srcPath)
		@config.databaseCachePath = pathUtil.resolve(@config.rootPath, @config.databaseCachePath)
		@config.packagePath = pathUtil.resolve(@config.rootPath, @config.packagePath)

		# Resolve Documents, Files, Layouts paths
		for type in ['documents','files','layouts']
			typePaths = @config[type+'Paths']
			for typePath,key in typePaths
				typePaths[key] = pathUtil.resolve(@config.srcPath, typePath)

		# Resolve Plugins paths
		for type in ['plugins']
			typePaths = @config[type+'Paths']
			for typePath,key in typePaths
				typePaths[key] = pathUtil.resolve(@config.rootPath, typePath)

		# Bind the error handler, so we don't crash on errors
		process.removeListener('uncaughtException', @error)
		@removeListener('error', @error)
		if @config.catchExceptions
			process.setMaxListeners(0)
			process.on('uncaughtException', @error)
			@on('error', @error)

		# Prepare the Post Tasks
		postTasks = new @TaskGroup 'setConfig post tasks', next:(err) ->
			return next(err, docpad.config)

		###
		postTasks.addTask 'lazy depedencnies: encoding', (complete) =>
			return complete()  unless @config.detectEncoding
			return lazyRequire 'encoding', {cwd:corePath, stdio:'inherit'}, (err) ->
				docpad.warn(locale.encodingLoadFailed)  if err
				return complete()
		###

		postTasks.addTask 'load plugins', (complete) ->
			docpad.loadPlugins(complete)

		postTasks.addTask 'extend collections', (complete) ->
			docpad.extendCollections(complete)

		postTasks.addTask 'fetch plugins templateData', (complete) ->
			docpad.emitSerial('extendTemplateData', {templateData:docpad.pluginsTemplateData}, complete)

		postTasks.addTask 'fire the docpadLoaded event', (complete) ->
			docpad.emitSerial('docpadLoaded', complete)

		# Fire post tasks
		postTasks.run()

		# Chain
		@


	###*
	# Load the various configuration files from the
	# file system. Set the instanceConfig.
	# next(err,config)
	# @private
	# @method load
	# @param {Object} instanceConfig
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.config
	###
	load: (instanceConfig,next) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()
		instanceConfig or= {}

		# Reset non persistant configurations
		@websitePackageConfig = {}
		@websiteConfig = {}
		@config = {}

		# Merge in the instance configurations
		@setInstanceConfig(instanceConfig)

		# Prepare the Load Tasks
		preTasks = new @TaskGroup 'load tasks', next:(err) =>
			return next(err)  if err
			return @setConfig(next)

		preTasks.addTask 'normalize the userConfigPath', (complete) =>
			safeps.getHomePath (err,homePath) =>
				return complete(err)  if err
				dropboxPath = pathUtil.resolve(homePath, 'Dropbox')
				safefs.exists dropboxPath, (dropboxPathExists) =>
					# @TODO: Implement checks here for
					# https://github.com/bevry/docpad/issues/799
					userConfigDirPath = if dropboxPathExists then dropboxPath else homePath
					@userConfigPath = pathUtil.resolve(userConfigDirPath, @userConfigPath)
					return complete()

		preTasks.addTask "load the user's configuration", (complete) =>
			configPath = @userConfigPath
			docpad.log 'debug', util.format(locale.loadingUserConfig, configPath)
			@loadConfigPath {configPath}, (err,data) =>
				return complete(err)  if err

				# Apply loaded data
				extendr.extend(@userConfig, data or {})

				# Done
				docpad.log 'debug', util.format(locale.loadingUserConfig, configPath)
				return complete()

		preTasks.addTask "load the anonymous user's configuration", (complete) =>
			# Ignore if username is already identified
			return complete()  if @userConfig.username

			# User is anonymous, set their username to the hashed and salted mac address
			require('getmac').getMac (err,macAddress) =>
				if err or !macAddress
					docpad.warn(locale.macError, err)
					return complete()

				# Hash with salt
				try
					macAddressHash = require('crypto').createHmac('sha1', docpad.hashKey).update(macAddress).digest('hex')
				catch err
					return complete()  if err

				# Apply
				if macAddressHash
					@userConfig.name ?= "MAC #{macAddressHash}"
					@userConfig.username ?= macAddressHash

				# Next
				return complete()

		preTasks.addTask "load the website's package data", (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			configPath = pathUtil.resolve(rootPath, @instanceConfig.packagePath or @initialConfig.packagePath)
			docpad.log 'debug', util.format(locale.loadingWebsitePackageConfig, configPath)
			@loadConfigPath {configPath}, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				@websitePackageConfig = data

				# Done
				docpad.log 'debug', util.format(locale.loadedWebsitePackageConfig, configPath)
				return complete()

		preTasks.addTask "read the .env file if it exists", (complete) =>
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @websitePackageConfig.rootPath or @initialConfig.rootPath)
			configPath = pathUtil.resolve(rootPath, '.env')
			docpad.log 'debug', util.format(locale.loadingEnvConfig, configPath)
			safefs.exists configPath, (exists) ->
				return complete()  unless exists
				require('envfile').parseFile configPath, (err,data) ->
					return complete(err)  if err
					for own key,value of data
						process.env[key] = value
					docpad.log 'debug', util.format(locale.loadingEnvConfig, configPath)
					return complete()

		preTasks.addTask "load the website's configuration", (complete) =>
			docpad.log 'debug', util.format(locale.loadingWebsiteConfig)
			rootPath = pathUtil.resolve(@instanceConfig.rootPath or @initialConfig.rootPath)
			configPaths = @instanceConfig.configPaths or @initialConfig.configPaths
			for configPath, index in configPaths
				configPaths[index] = pathUtil.resolve(rootPath, configPath)
			@loadConfigPath {configPaths}, (err,data) =>
				return complete(err)  if err
				data or= {}

				# Apply loaded data
				extendr.extend(@websiteConfig, data)

				# Done
				docpad.log 'debug', util.format(locale.loadedWebsiteConfig)
				return complete()

		# Run the load tasks synchronously
		preTasks.run()

		# Chain
		@


	# =================================
	# Configuration

	###*
	# Update user configuration with the passed data
	# @method updateUserConfig
	# @param {Object} [data={}]
	# @param {Function} next
	# @param {Error} next.err
	###
	updateUserConfig: (data={},next) ->
		# Prepare
		[data,next] = extractOptsAndCallback(data,next)
		docpad = @
		userConfigPath = @userConfigPath

		# Apply back to our loaded configuration
		# does not apply to @config as we would have to reparse everything
		# and that appears to be an imaginary problem
		extendr.extend(@userConfig, data)  if data

		# Convert to CSON
		CSON.createCSONString @userConfig, (err, userConfigString) ->
			if err
				err.context = "Failed to create the CSON string for the user configuration"
				return next(err)

			# Write it
			safefs.writeFile userConfigPath, userConfigString, 'utf8', (err) ->
				# Forward
				return next(err)

		# Chain
		@

	###*
	# Load a configuration url.
	# @method loadConfigUrl
	# @param {String} configUrl
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.parsedData
	###
	loadConfigUrl: (configUrl,next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Log
		docpad.log 'debug', util.format(locale.loadingConfigUrl, configUrl)

		# Read the URL
		superAgent
			.get(configUrl)
			.timeout(30*1000)
			.end (err,res) ->
				# Check
				return next(err)  if err

				# Read the string using CSON
				CSON.parseCSONString(res.text, next)

		# Chain
		@


	###*
	# Load the configuration from a file path
	# passed as one of the options (opts.configPath) or
	# from DocPad's configPaths
	# @private
	# @method loadConfigPath
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.parsedData
	###
	loadConfigPath: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()

		# Prepare
		load = (configPath) ->
			# Check
			return next()  unless configPath

			# Log
			docpad.log 'debug', util.format(locale.loadingConfigPath, configPath)

			# Check that it exists
			safefs.exists configPath, (exists) ->
				return next()  unless exists

				# Prepare CSON Options
				csonOptions =
					cson: true
					json: true
					coffeescript: true
					javascript: true

				# Read the path using CSON
				CSON.requireFile configPath, csonOptions, (err, data) ->
					if err
						err.context = util.format(locale.loadingConfigPathFailed, configPath)
						return next(err)

					# Check if the data is a function, if so, then execute it as one
					while typeChecker.isFunction(data)
						try
							data = data(docpad)
						catch err
							return next(err)
					unless typeChecker.isObject(data)
						err = new Error("Loading the configuration #{docpad.inspector configPath} returned an invalid result #{docpad.inspector data}")
						return next(err)  if err

					# Return the data
					return next(null, data)

		# Check
		if opts.configPath
			load(opts.configPath)
		else
			@getConfigPath opts, (err,configPath) ->
				load(configPath)

		# Chain
		@

	###*
	# Get config paths and check that those
	# paths exist
	# @private
	# @method getConfigPath
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @param {String} next.path
	###
	getConfigPath: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()
		result = null

		# Ensure array
		opts.configPaths ?= config.configPaths
		opts.configPaths = [opts.configPaths]  unless typeChecker.isArray(opts.configPaths)

		tasks = new @TaskGroup 'getConfigPath tasks', next:(err) ->
			return next(err, result)

		# Determine our configuration path
		opts.configPaths.forEach (configPath) ->
			tasks.addTask "Checking if [#{configPath}] exists", (complete) ->
				return complete()  if result
				safefs.exists configPath, (exists) ->
					if exists
						result = configPath
						tasks.clear()
						complete()
					else
						complete()

		# Run them synchronously
		tasks.run()

		# Chain
		@


	###*
	# Extend collecitons. Create DocPad's
	# standard (documents, files
	# layouts) and special (generate, referencesOthers,
	# hasLayout, html, stylesheet) collections. Set blocks
	# @private
	# @method extendCollections
	# @param {Function} next
	# @param {Error} next.err
	###
	extendCollections: (next) ->
		# Prepare
		docpad = @
		docpadConfig = @getConfig()
		locale = @getLocale()
		database = @getDatabase()

		# Standard Collections
		@setCollections({
			# Standard Collections
			documents: database.createLiveChildCollection()
				.setQuery('isDocument', {
					render: true
					write: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingDocument, model.getFilePath()))
				)
			files: database.createLiveChildCollection()
				.setQuery('isFile', {
					render: false
					write: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingFile, model.getFilePath()))
				)
			layouts: database.createLiveChildCollection()
				.setQuery('isLayout', {
					$or:
						isLayout: true
						fullPath: $startsWith: docpadConfig.layoutsPaths
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingLayout, model.getFilePath()))
					model.setDefaults({
						isLayout: true
						render: false
						write: false
					})
				)

			# Special Collections
			generate: database.createLiveChildCollection()
				.setQuery('generate', {
					dynamic: false
					ignored: false
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingGenerate, model.getFilePath()))
				)
			referencesOthers: database.createLiveChildCollection()
				.setQuery('referencesOthers', {
					dynamic: false
					ignored: false
					referencesOthers: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingReferencesOthers, model.getFilePath()))
				)
			hasLayout: database.createLiveChildCollection()
				.setQuery('hasLayout', {
					dynamic: false
					ignored: false
					layout: $exists: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingHasLayout, model.getFilePath()))
				)
			html: database.createLiveChildCollection()
				.setQuery('isHTML', {
					write: true
					outExtension: 'html'
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingHtml, model.getFilePath()))
				)
			stylesheet: database.createLiveChildCollection()
				.setQuery('isStylesheet', {
					write: true
					outExtension: 'css'
				})
		})

		# Blocks
		@setBlocks({
			meta: new MetaCollection()
			scripts: new ScriptsCollection()
			styles: new StylesCollection()
		})

		# Custom Collections Group
		tasks = new @TaskGroup "extendCollections tasks", concurrency:0, next:(err) ->
			docpad.error(err)  if err
			docpad.emitSerial('extendCollections', next)

		# Cycle through Custom Collections
		eachr docpadConfig.collections or {}, (fn,name) ->
			if !name or !typeChecker.isString(name)
				err = new Error("Inside your DocPad configuration you have a custom collection with an invalid name of: #{docpad.inspector name}")
				docpad.error(err)
				return

			if !fn or !typeChecker.isFunction(fn)
				err = new Error("Inside your DocPad configuration you have a custom collection called #{docpad.inspector name} with an invalid method of: #{docpad.inspector fn}")
				docpad.error(err)
				return

			tasks.addTask "creating the custom collection: #{name}", (complete) ->
				# Init
				ambi [fn.bind(docpad), fn], database, (err, collection) ->
					# Check for error
					if err
						docpad.error(err)
						return complete()

					# Check the type of the collection
					else unless collection instanceof QueryCollection
						docpad.warn util.format(locale.errorInvalidCollection, name)
						return complete()

					# Make it a live collection
					collection.live(true)  if collection

					# Apply the collection
					docpad.setCollection(name, collection)
					return complete()

		# Run Custom collections
		tasks.run()

		# Chain
		@


	###*
	# Reset collections. Perform a complete clean of our collections
	# @private
	# @method resetCollections
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	resetCollections: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		database = docpad.getDatabase()

		# Make it as if we have never generated before
		docpad.generated = false

		# Perform a complete clean of our collections
		database.reset([])
		meta = @getBlock('meta').reset([])
		scripts = @getBlock('scripts').reset([])
		styles = @getBlock('styles').reset([])
		# ^ Backbone.js v1.1 changes the return values of these, however we change that in our Element class
		# because if we didn't, all our skeletons would fail

		# Add default block entries
		meta.add("""<meta name="generator" content="DocPad v#{docpad.getVersion()}" />""")  if docpad.getConfig().poweredByDocPad isnt false

		# Reset caches
		@filesByUrl = {}
		@filesBySelector = {}
		@filesByOutPath = {}

		# Chain
		next()
		@


	###*
	# Initialise git repo
	# @private
	# @method initGitRepo
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.results
	###
	initGitRepo: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= @getDebugging()

		# Forward
		safeps.initGitRepo(opts, next)

		# Chain
		@

	###*
	# Init node modules
	# @private
	# @method initNodeModules
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.results
	###
	initNodeModules: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= docpad.getDebugging()
		opts.force ?= if config.offline then false else true
		# ^ @todo this line causes --force to be added, when it shouldn't be
		opts.args ?= []
		opts.args.push('--force')  if config.force
		opts.args.push('--no-registry')  if config.offline

		# Log
		docpad.log('info', 'npm install')  if opts.output

		# Forward
		safeps.initNodeModules(opts, next)

		# Chain
		@

	###*
	# Fix node package versions
	# Combat to https://github.com/npm/npm/issues/4587#issuecomment-35370453
	# @private
	# @method fixNodePackageVersions
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	fixNodePackageVersions: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.packagePath ?= config.packagePath

		# Read and replace
		safefs.readFile opts.packagePath, (err,buffer) ->
			data = buffer.toString()
			data = data.replace(/("docpad(?:.*?)": ")\^/g, '$1~')
			safefs.writeFile opts.packagePath, data, (err) ->
				return next(err)

		# Chain
		@


	###*
	# Install node module. Same as running
	# 'npm install' through the command line
	# @private
	# @method installNodeModule
	# @param {Array} names
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.result
	###
	installNodeModule: (names,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.args ?= []
		if docpad.getDebugging()
			opts.stdio ?= 'inherit'

		opts.global ?= false
		opts.global = ['--global']             if opts.global is true
		opts.global = [opts.global]            if opts.global and Array.isArray(opts.global) is false

		opts.save ?= !opts.global
		opts.save = ['--save']                 if opts.save is true
		opts.save = [opts.save]                if opts.save and Array.isArray(opts.save) is false

		# Command
		command = ['npm', 'install']

		# Names
		names = names.split(/[,\s]+/)  unless typeChecker.isArray(names)
		names.forEach (name) ->
			# Check
			return  unless name

			# Ensure latest if version isn't specfied
			name += '@latest'  if name.indexOf('@') is -1

			# Push the name to the commands
			command.push(name)

		# Arguments
		command.push(opts.args...)
		command.push('--force')           if config.force
		command.push('--no-registry')     if config.offline
		command.push(opts.save...)        if opts.save
		command.push(opts.global...)      if opts.global

		# Log
		docpad.log('info', command.join(' '))  if opts.output

		# Forward
		safeps.spawn(command, opts, next)

		# Chain
		@


	###*
	# Uninstall node module. Same as running
	# 'npm uninstall' through the command line
	# @private
	# @method uninstallNodeModule
	# @param {Array} names
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.result
	###
	uninstallNodeModule: (names,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()

		# Extract
		opts.cwd ?= config.rootPath
		opts.output ?= docpad.getDebugging()
		opts.args ?= []

		opts.global ?= false
		opts.global = ['--global']             if opts.global is true
		opts.global = [opts.global]            if opts.global and Array.isArray(opts.global) is false

		opts.save ?= !opts.global
		opts.save = ['--save', '--save-dev']   if opts.save is true
		opts.save = [opts.save]                if opts.save and Array.isArray(opts.save) is false

		# Command
		command = ['npm', 'uninstall']

		# Names
		names = names.split(/[,\s]+/)  unless typeChecker.isArray(names)
		command.push(names...)

		# Arguments
		command.push(opts.args...)
		command.push(opts.save...)        if opts.save
		command.push(opts.global...)      if opts.global

		# Log
		docpad.log('info', command.join(' '))  if opts.output

		# Forward
		safeps.spawn(command, opts, next)

		# Chain
		@



	# =================================
	# Logging

	###*
	# Set the log level
	# @private
	# @method setLogLevel
	# @param {Number} level
	###
	setLogLevel: (level) ->
		@getLogger().setConfig({level})
		if level is 7
			loggers = @getLoggers()
			if loggers.debug? is false
				loggers.debug = loggers.logger
					.pipe(
						new (require('caterpillar-human').Human)(color:false)
					)
					.pipe(
						require('fs').createWriteStream(@debugLogPath)
					)
		@

	###*
	# Get the log level
	# @method getLogLevel
	# @return {Number} the log level
	###
	getLogLevel: ->
		return @getConfig().logLevel

	###*
	# Are we debugging?
	# @method getDebugging
	# @return {Boolean}
	###
	getDebugging: ->
		return @getLogLevel() is 7


	###*
	# Handle a fatal error
	# @private
	# @method fatal
	# @param {Object} err
	###
	fatal: (err) ->
		docpad = @
		config = @getConfig()

		# Check
		return @  unless err

		# Handle
		@error(err)

		# Even though the error would have already been logged by the above
		# Ensure it is definitely outputted in the case the above fails
		docpadUtil.writeError(err)

		# Destroy DocPad
		@destroy()

		# Chain
		@


	###*
	# Inspect. Converts object to JSON string. Wrapper around nodes util.inspect method.
	# Can't use the inspect namespace as for some silly reason it destroys everything
	# @method inspector
	# @param {Object} obj
	# @param {Object} opts
	# @return {String} JSON string of passed object
	###
	inspector: (obj, opts) ->
		opts ?= {}
		opts.colors ?= @getConfig().color
		return docpadUtil.inspect(obj, opts)

	###*
	# Log arguments
	# @property {Object} log
	# @param {Mixed} args...
	###
	log: (args...) ->
		# Log
		logger = @getLogger() or console
		logger.log.apply(logger, args)

		# Chain
		@


	###*
	# Create an error object
	# @method createError
	# @param {Object} err
	# @param {Object} opts
	# @return {Object} the error
	###
	# @TODO: Decide whether or not we should track warnings
	# Previously we didn't, but perhaps it would be useful
	# If the statistics gets polluted after a while, we will remove it
	# Ask @balupton to check the stats after March 30th 2015
	createError: (err, opts) ->
		# Prepare
		opts ?= {}
		opts.level ?= err.level ? 'error'
		opts.track ?= err.track ? true
		opts.tracked ?= err.tracked ? false
		opts.log ?= err.log ? true
		opts.logged ?= err.logged ? false
		opts.notify ?= err.notify ? true
		opts.notified ?= err.notified ? false
		opts.context ?= err.context  if err.context?

		# Ensure we have an error object
		err = new Error(err)  unless err.stack

		# Add our options to the error object
		for own key,value of opts
			err[key] ?= value

		# Return the error
		return err


	###*
	# Create an error (tracks it) and log it
	# @method error
	# @param {Object} err
	# @param {Object} [level='err']
	###
	error: (err, level='err') ->
		# Prepare
		docpad = @

		# Create the error and track it
		err = @createError(err, {level})

		# Track the error
		@trackError(err)

		# Log the error
		@logError(err)

		# Notify the error
		@notifyError(err)

		# Chain
		@

	###*
	# Log an error
	# @method logError
	# @param {Object} err
	###
	logError: (err) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Track
		if err and err.log isnt false and err.logged isnt true
			err = @createError(err, {logged:true})
			occured =
				if err.level in ['warn', 'warning']
					locale.warnOccured
				else
					locale.errorOccured
			message =
				if err.context
					err.context+locale.errorFollows
				else
					occured
			message += '\n\n'+err.stack.toString().trim()
			message += '\n\n'+locale.errorSubmission
			docpad.log(err.level, message)

		# Chain
		@


	###*
	# Track an error in the background
	# @private
	# @method trackError
	# @param {Object} err
	###
	trackError: (err) ->
		# Prepare
		docpad = @
		config = @getConfig()

		# Track
		if err and err.track isnt false and err.tracked isnt true and config.offline is false and config.reportErrors is true
			err = @createError(err, {tracked:true})
			data = {}
			data.message = err.message
			data.stack = err.stack.toString().trim()  if err.stack
			data.config = config
			data.env = process.env
			docpad.track('error', data)

		# Chain
		@

	###*
	# Notify error
	# @private
	# @method notifyError
	# @param {Object} err
	###
	notifyError: (err) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Check
		if err.notify isnt false and err.notified isnt true
			err.notified = true
			occured =
				if err.level in ['warn', 'warning']
					locale.warnOccured
				else
					locale.errorOccured
			docpad.notify(err.message, {title:occured})

		# Chain
		@

	###*
	# Log an error of level 'warn'
	# @method warn
	# @param {String} message
	# @param {Object} err
	# @return {Object} description
	###
	warn: (message, err) ->
		# Handle
		if err
			err.context = message
			err.level = 'warn'
			@error(err)
		else
			err =
				if message instanceof Error
					message
				else
					new Error(message)
			err.level = 'warn'
			@error(err)

		# Chain
		@


	###*
	# Send a notify event to plugins (like growl)
	# @method notify
	# @param {String} message
	# @param {Object} [opts={}]
	###
	notify: (message,opts={}) ->
		# Prepare
		docpad = @

		# Emit
		docpad.emitSerial 'notify', {message,opts}, (err) ->
			docpad.error(err)  if err

		# Chain
		@


	###*
	# Check Request
	# @private
	# @method checkRequest
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.res
	###
	checkRequest: (next) ->
		next ?= @error.bind(@)
		return (err,res) ->
			# Check
			return next(err, res)  if err

			# Check
			if res.body?.success is false or res.body?.error
				err = new Error(res.body.error or 'unknown request error')  # @TODO localise this
				return next(err, res)

			# Success
			return next(null, res)


	###*
	# Subscribe to the DocPad email list.
	# @private
	# @method subscribe
	# @param {Function} next
	# @param {Error} next.err
	###
	subscribe: (next) ->
		# Prepare
		config = @getConfig()

		# Check
		if config.offline is false
			if @userConfig?.email
				# Data
				data = {}
				data.email = @userConfig.email  # required
				data.name = @userConfig.name or null
				data.username = @userConfig.username or null

				# Apply
				superAgent
					.post(config.helperUrl)
					.type('json').set('Accept', 'application/json')
					.query(
						method: 'add-subscriber'
					)
					.send(data)
					.timeout(30*1000)
					.end @checkRequest next
			else
				err = new Error('Email not provided')  # @TODO localise this
				next?(err)
		else
			next?()

		# Chain
		@

	###*
	# Track
	# @private
	# @method track
	# @param {String} name
	# @param {Object} [things={}]
	# @param {Function} next
	# @param {Error} next.err
	###
	track: (name,things={},next) ->
		# Prepare
		docpad = @
		config = @getConfig()

		# Check
		if config.offline is false and config.reportStatistics
			# Data
			data = {}
			data.userId = @userConfig.username or null
			data.event = name
			data.properties = things

			# Things
			things.websiteName = @websitePackageConfig.name  if @websitePackageConfig?.name
			things.platform = @getProcessPlatform()
			things.environment = @getEnvironment()
			things.version = @getVersion()
			things.nodeVersion = @getProcessVersion()

			# Plugins
			eachr docpad.loadedPlugins, (value,key) ->
				things['plugin-'+key] = value.version or true

			# Apply
			trackRunner = docpad.getTrackRunner()
			trackRunner.addTask 'track task', (complete) ->
				superAgent
					.post(config.helperUrl)
					.type('json').set('Accept', 'application/json')
					.query(
						method: 'analytics'
						action: 'track'
					)
					.send(data)
					.timeout(30*1000)
					.end docpad.checkRequest (err) ->
						next?(err)
						complete(err)  # we pass the error here, as if we error, we want to stop all tracking

			# Execute the tracker tasks
			trackRunner.run()
		else
			next?()

		# Chain
		@

	###*
	# Identify DocPad user
	# @private
	# @method identify
	# @param {Function} next
	# @param {Error} next.err
	###
	identify: (next) ->
		# Prepare
		docpad = @
		config = @getConfig()

		# Check
		if config.offline is false and config.reportStatistics and @userConfig?.username
			# Data
			data = {}
			data.userId = @userConfig.username  # required
			data.traits = things = {}

			# Things
			now = new Date()
			things.username = @userConfig.username  # required
			things.email = @userConfig.email or null
			things.name = @userConfig.name or null
			things.lastLogin = now.toISOString()
			things.lastSeen = now.toISOString()
			things.countryCode = safeps.getCountryCode()
			things.languageCode = safeps.getLanguageCode()
			things.platform = @getProcessPlatform()
			things.version = @getVersion()
			things.nodeVersion = @getProcessVersion()

			# Is this a new user?
			if docpad.userConfig.identified isnt true
				# Update
				things.created = now.toISOString()

				# Create the new user
				docpad.getTrackRunner().addTask 'create new user', (complete) ->
					superAgent
						.post(config.helperUrl)
						.type('json').set('Accept', 'application/json')
						.query(
							method: 'analytics'
							action: 'identify'
						)
						.send(data)
						.timeout(30*1000)
						.end docpad.checkRequest (err) ->
							# Save the changes with these
							docpad.updateUserConfig({identified:true}, complete)

			# Or an existing user?
			else
				# Update the existing user's information witht he latest
				docpad.getTrackRunner().addTask 'update user', (complete) ->
					superAgent
						.post(config.helperUrl)
						.type('json').set('Accept', 'application/json')
						.query(
							method: 'analytics'
							action: 'identify'
						)
						.send(data)
						.timeout(30*1000)
						.end docpad.checkRequest complete

		# Chain
		next?()
		@


	# =================================
	# Models and Collections

	# ---------------------------------
	# b/c compat functions

	###*
	# Create file model. Calls
	# {{#crossLink "DocPad/createModel:method"}}{{/crossLink}}
	# with the 'file' modelType.
	# @method createFile
	# @param {Object} [attrs={}]
	# @param {Object} [opts={}]
	# @return {Object} FileModel
	###
	createFile: (attrs={},opts={}) ->
		opts.modelType = 'file'
		return @createModel(attrs, opts)

	###*
	# Create document model. Calls
	# {{#crossLink "DocPad/createModel:method"}}{{/crossLink}}
	# with the 'document' modelType.
	# @method createDocument
	# @param {Object} [attrs={}]
	# @param {Object} [opts={}]
	# @return {Object} DocumentModel
	###
	createDocument: (attrs={},opts={}) ->
		opts.modelType = 'document'
		return @createModel(attrs, opts)


	###*
	# Parse the files directory and
	# return a files collection to
	# the passed callback
	# @method parseFileDirectory
	# @param {Object} [opts={}]
	# @param {Function} next callback
	# @param {Error} next.err
	# @param {Object} next.files files collection
	###
	parseFileDirectory: (opts={},next) ->
		opts.modelType ?= 'file'
		opts.collection ?= @getDatabase()
		return @parseDirectory(opts, next)

	###*
	# Parse the documents directory and
	# return a documents collection to
	# the passed callback.
	#
	# The partials plugin (https://github.com/docpad/docpad-plugin-partials)
	# uses this method to load a collection of
	# files from the partials directory.
	#
	# 	docpad.parseDocumentDirectory({path: config.partialsPath}, next)
	#
	# @method parseDocumentDirectory
	# @param {Object} [opts={}]
	# @param {String} [opts.modelType='document']
	# @param {Object} [opts.collection=docpad.database]
	# @param {Object} [opts.path]
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.files files collection of documents
	###
	parseDocumentDirectory: (opts={},next) ->
		opts.modelType ?= 'document'
		opts.collection ?= @getDatabase()
		return @parseDirectory(opts, next)


	# ---------------------------------
	# Standard functions


	###*
	# Attach events to a document model.
	# @private
	# @method attachModelEvents
	# @param {Object} model
	###
	attachModelEvents: (model) ->
		# Prepare
		docpad = @

		# Only attach events if we haven't already done so
		if model.attachedDocumentEvents isnt true
			model.attachedDocumentEvents = true

			# Attach document events
			if model.type is 'document'
				# Clone
				model.on 'clone', (clonedModel) ->
					docpad.attachModelEvents(clonedModel)

				# Render
				model.on 'render', (args...) ->
					docpad.emitSerial('render', args...)

				# Render document
				model.on 'renderDocument', (args...) ->
					docpad.emitSerial('renderDocument', args...)

				# Fetch a layout
				model.on 'getLayout', (opts={},next) ->
					opts.collection = docpad.getCollection('layouts')
					layout = docpad.getFileBySelector(opts.selector, opts)
					next(null, {layout})

			# Remove
			#model.on 'remove', (file) ->
			#	docpad.getDatabase().remove(file)
			# ^ Commented out as for some reason this stops layouts from working

			# Error
			model.on 'error', (args...) ->
				docpad.error(args...)

			# Log
			model.on 'log', (args...) ->
				if args.length is 2
					if args[0] in ['err', 'error']
						docpad.error(args[1])
						return

					if args[0] in ['warn', 'warning']
						docpad.warn(args[1])
						return

				docpad.log(args...)

		# Chain
		@

	###*
	# Add supplied model to the DocPad database. If the passed
	# model definition is a plain object of properties, a new
	# model will be created prior to adding to the database.
	# Calls {{#crossLink "DocPad/createModel:method"}}{{/crossLink}}
	# before adding the model to the database.
	#
	#	# Override the stat's mtime to now
	#	# This is because renames will not update the mtime
	#	fileCurrentStat?.mtime = new Date()
	#
	#	# Create the file object
	#	file = docpad.addModel({fullPath:filePath, stat:fileCurrentStat})
	#
	# @method addModel
	# @param {Object} model either a plain object defining the required properties, in particular
	# the file path or an actual model object
	# @param {Object} opts
	# @return {Object} the model
	###
	addModel: (model, opts) ->
		model = @createModel(model, opts)
		@getDatabase().add(model)
		return model

	###*
	# Add the supplied collection of models to the DocPad database.
	# Calls {{#crossLink "DocPad/createModels:method"}}{{/crossLink}}
	# before adding the models to the database.
	#
	# 	databaseData = JSON.parse data.toString()
	#	models = docpad.addModels(databaseData.models)
	#
	# @method addModels
	# @param {Object} models DocPad collection of models
	# @param {Object} opts
	# @return {Object} the models
	###
	addModels: (models, opts) ->
		models = @createModels(models, opts)
		@getDatabase().add(models)
		return models

	###*
	# Create a collection of models from the supplied collection
	# ensuring that the collection is suitable for adding to the
	# DocPad database. The method calls {{#crossLink "DocPad/createModel"}}{{/crossLink}}
	# for each model in the models array.
	# @private
	# @method createModels
	# @param {Object} models DocPad collection of models
	# @param {Object} opts
	# @return {Object} the models
	###
	createModels: (models, opts) ->
		for model in models
			@createModel(model, opts)
		# return the for loop results

	###*
	# Creates either a file or document model.
	# The model type to be created can be passed
	# as an opts property, if not, the method will
	# attempt to determing the model type by checking
	# if the file is in one of the documents or
	# layout paths.
	#
	# Ensures a duplicate model is not created
	# and all required attributes are present and
	# events attached.
	#
	# Generally it is not necessary for an application
	# to manually create a model via creatModel as DocPad
	# will handle this process when watching a project's
	# file and document directories. However, it is possible
	# that a plugin might have a requirement to do so.
	#
	# 	model = @docpad.createModel({fullPath:fullPath})
    #   model.load()
    #   @docpad.getDatabase().add(model)
	#
	# @method createModel
	# @param {Object} [attrs={}]
	# @param {String} attrs.fullPath the full path to the file
	# @param {Object} [opts={}]
	# @param {String} opts.modelType either 'file' or 'document'
	# @return {Object} the file or document model
	###
	createModel: (attrs={},opts={}) ->
		# Check
		if attrs instanceof FileModel
			return attrs

		# Prepare
		docpad = @
		config = @getConfig()
		database = @getDatabase()
		fileFullPath = attrs.fullPath or null


		# Find or create
		# This functionality use to be inside ensureModel
		# But that caused duplicates in some instances
		# So now we will always check
		if attrs.fullPath
			result = database.findOne(fullPath: attrs.fullPath)
			if result
				return result


		# -----------------------------
		# Try and determine the model type

		# If the type hasn't been specified try and detemrine it based on the full path
		if fileFullPath
			# Check if we have a document or layout
			unless opts.modelType
				for dirPath in config.documentsPaths.concat(config.layoutsPaths)
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'document'
						break

			# Check if we have a file
			unless opts.modelType
				for dirPath in config.filesPaths
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'file'
						break

		# -----------------------------
		# Create the appropriate emodel

		# Extend the opts with things we need
		opts = extendr.extend({
			detectEncoding: config.detectEncoding
			rootOutDirPath: config.outPath
			locale: @getLocale()
			TaskGroup: @TaskGroup
		}, opts)

		if opts.modelType is 'file'
			# Create a file model
			model = new FileModel(attrs, opts)
		else
			# Create document model
			model = new DocumentModel(attrs, opts)

		# -----------------------------
		# Finish up

		# Attach Events
		@attachModelEvents(model)

		# Return
		return model

	###*
	# Parse a directory and return a
	# files collection
	# @method parseDirectory
	# @param {Object} [opts={}]
	# @param {Object} next
	# @param {Error} next.err
	# @param {Object} next.files files collection
	###
	parseDirectory: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()

		# Extract
		{path,createFunction} = opts
		createFunction ?= @createModel
		files = opts.collection or new FilesCollection()

		# Check if the directory exists
		safefs.exists path, (exists) ->
			# Check
			unless exists
				# Log
				docpad.log 'debug', util.format(locale.renderDirectoryNonexistant, path)

				# Forward
				return next()

			# Log
			docpad.log 'debug', util.format(locale.renderDirectoryParsing, path)

			# Files
			docpad.scandir(
				# Path
				path: path

				# File Action
				fileAction: (fileFullPath,fileRelativePath,nextFile,fileStat) ->
					# Prepare
					data =
						fullPath: fileFullPath
						relativePath: fileRelativePath
						stat: fileStat

					# Create file
					file = createFunction.call(docpad, data, opts)

					# Update the file's stat
					# To ensure changes files are handled correctly in generation
					file.action 'load', (err) ->
						# Error?
						return nextFile(err)  if err

						# Add the file to the collection
						files.add(file)

						# Next
						nextFile()

				# Next
				next: (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.renderDirectoryParsed, path)

					# Forward
					return next(null, files)
			)

		# Chain
		@


	# =================================
	# Plugins

	###*
	# Get a plugin by it's name
	# @method getPlugin
	# @param {Object} pluginName
	# @return {Object} a DocPad plugin
	###
	getPlugin: (pluginName) ->
		@loadedPlugins[pluginName]


	###*
	# Check if we have any plugins
	# @method hasPlugins
	# @return {Boolean}
	###
	hasPlugins: ->
		return typeChecker.isEmptyObject(@loadedPlugins) is false

	###*
	# Destructor. Destroy plugins
	# @private
	# @method destroyPlugins
	###
	destroyPlugins: ->
		for own name,plugin of @loadedPlugins
			plugin.destroy()
			@loadedPlugins[name] = null
		@

	###*
	# Load plugins from the file system
	# next(err)
	# @private
	# @method loadPlugins
	# @param {Function} next
	# @param {Error} next.err
	###
	loadPlugins: (next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Snore
		@slowPlugins = {}
		snore = balUtil.createSnore ->
			docpad.log 'notice', util.format(locale.pluginsSlow, Object.keys(docpad.slowPlugins).join(', '))

		# Async
		tasks = new @TaskGroup "loadPlugins tasks", concurrency:0, next:(err) ->
			docpad.slowPlugins = {}
			snore.clear()
			return next(err)

		# Load website plugins
		(@config.pluginsPaths or []).forEach (pluginsPath) ->
			tasks.addTask "load the website's plugins at: #{pluginsPath}", (complete) ->
				safefs.exists pluginsPath, (exists) ->
					return complete()  unless exists
					docpad.loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		(@config.pluginPaths or []).forEach (pluginPath) ->
			tasks.addTask "load custom plugins at: #{pluginPath}", (complete) ->
				safefs.exists pluginPath, (exists) ->
					return complete()  unless exists
					docpad.loadPlugin(pluginPath, complete)

		# Execute the loading asynchronously
		tasks.run()

		# Chain
		@

	###*
	# Checks if a plugin was loaded succesfully.
	# @method loadedPlugin
	# @param {String} pluginName
	# @param {Function} next
	# @param {Error} next.err
	# @param {Boolean} next.loaded
	###
	loadedPlugin: (pluginName,next) ->
		# Prepare
		docpad = @

		# Check
		loaded = docpad.loadedPlugins[pluginName]?
		next(null,loaded)

		# Chain
		@

	###*
	# Load a plugin from its full file path
	# _next(err)
	# @private
	# @method loadPlugin
	# @param {String} fileFullPath
	# @param {Function} _next
	# @param {Error} _next.err
	# @return {Object} description
	###
	loadPlugin: (fileFullPath,_next) ->
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		next = (err) ->
			# Remove from slow plugins
			delete docpad.slowPlugins[pluginName]
			# Forward
			return _next(err)

		# Prepare variables
		loader = new PluginLoader(
			dirPath: fileFullPath
			docpad: @
			BasePlugin: BasePlugin
		)
		pluginName = loader.pluginName
		enabled = (
			(config.enableUnlistedPlugins  and  config.enabledPlugins[pluginName]? is false)  or
			config.enabledPlugins[pluginName] is true
		)

		# If we've already been loaded, then exit early as there is no use for us to load again
		if docpad.loadedPlugins[pluginName]?
			# However we probably want to reload the configuration as perhaps the user or environment configuration has changed
			docpad.loadedPlugins[pluginName].setConfig()
			# Complete
			return _next()

		# Add to loading stores
		docpad.slowPlugins[pluginName] = true

		# Check
		unless enabled
			# Skip
			docpad.log 'debug', util.format(locale.pluginSkipped, pluginName)
			return next()
		else
			# Load
			docpad.log 'debug', util.format(locale.pluginLoading, pluginName)

			# Check existance
			loader.exists (err,exists) ->
				# Error or doesn't exist?
				return next(err)  if err or not exists

				# Check support
				loader.unsupported (err,unsupported) ->
					# Error?
					return next(err)  if err

					# Unsupported?
					if unsupported
						# Version?
						if unsupported in ['version-docpad','version-plugin'] and config.skipUnsupportedPlugins is false
							docpad.log 'warn', util.format(locale.pluginContinued, pluginName)
						else
							# Type?
							if unsupported is 'type'
								docpad.log 'debug', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)

							# Something else?
							else
								docpad.log 'warn', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)
							return next()

					# Load the class
					loader.load (err) ->
						return next(err)  if err

						# Create an instance
						loader.create {}, (err,pluginInstance) ->
							return next(err)  if err

							# Add to plugin stores
							docpad.loadedPlugins[loader.pluginName] = pluginInstance

							# Log completion
							docpad.log 'debug', util.format(locale.pluginLoaded, pluginName)

							# Forward
							return next()

		# Chain
		@

	###*
	# Load plugins from a directory path
	# @private
	# @method loadPluginsIn
	# @param {String} pluginsPath
	# @param {Function} next
	# @param {Error} next.err
	###
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Load Plugins
		docpad.log 'debug', util.format(locale.pluginsLoadingFor, pluginsPath)
		@scandir(
			# Path
			path: pluginsPath

			# Skip files
			fileAction: false

			# Handle directories
			dirAction: (fileFullPath,fileRelativePath,nextFile) ->
				# Prepare
				pluginName = pathUtil.basename(fileFullPath)

				# Delve deeper into the directory if it is a direcotry of plugins
				return nextFile(null, false)  if fileFullPath is pluginsPath

				# Otherwise, it is a plugin directory, so load the plugin
				docpad.loadPlugin fileFullPath, (err) ->
					# Warn about the plugin load error if there is one
					if err
						docpad.warn util.format(locale.pluginFailedToLoad, pluginName, fileFullPath), err

					# All done and don't recurse into this directory
					return nextFile(null, true)

			# Next
			next: (err) ->
				docpad.log 'debug', util.format(locale.pluginsLoadedFor, pluginsPath)
				return next(err)
		)

		# Chain
		@


	# =================================
	# Utilities

	# ---------------------------------
	# Utilities: Misc

	###*
	# Compare current DocPad version to the latest
	# and print out the result to the console.
	# Used at startup.
	# @private
	# @method compareVersion
	###
	compareVersion: ->
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Check
		return @  if config.offline or !config.checkVersion

		# Check
		balUtil.packageCompare(
			local: @packagePath
			remote: config.helperUrl+'latest'
			newVersionCallback: (details) ->
				isLocalInstallation = docpadUtil.isLocalDocPadExecutable()
				message = (if isLocalInstallation then locale.versionOutdatedLocal else locale.versionOutdatedGlobal)
				currentVersion = 'v'+details.local.version
				latestVersion = 'v'+details.remote.version
				upgradeUrl = details.local.upgradeUrl or details.remote.installUrl or details.remote.homepage
				messageFilled = util.format(message, currentVersion, latestVersion, upgradeUrl)
				docpad.notify(latestVersion, title:locale.versionOutdatedNotification)
				docpad.log('notice', messageFilled)
		)

		# Chain
		@


	# ---------------------------------
	# Utilities: Exchange


	###*
	# Get DocPad's exchange data
	# Requires internet access
	# next(err,exchange)
	# @private
	# @method getExchange
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.exchange docpad.exchange
	###
	getExchange: (next) ->
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Check if it is stored locally
		return next(null, docpad.exchange)  if typeChecker.isEmptyObject(docpad.exchange) is false

		# Offline?
		return next(null, null)  if config.offline

		# Log
		docpad.log('info', locale.exchangeUpdate+' '+locale.pleaseWait)

		# Otherwise fetch it from the exchangeUrl
		exchangeUrl = config.helperUrl+'?method=exchange&version='+@version
		docpad.loadConfigUrl exchangeUrl, (err,parsedData) ->
			# Check
			if err
				locale = docpad.getLocale()
				docpad.warn(locale.exchangeError, err)
				return next()

			# Log
			docpad.log('info', locale.exchangeUpdated)

			# Success
			docpad.exchange = parsedData
			return next(null, parsedData)

		# Chain
		@


	# ---------------------------------
	# Utilities: Files

	###*
	# Contextualize files.
	# Contextualizing is the process of adding layouts and
	# awareness of other documents to our document. The
	# contextualizeBefore and contextualizeAfter events
	# are emitted here.
	# @private
	# @method contextualizeFiles
	# @param {Object} [opts={}]
	# @param {Function} next
	# @param {Error} next.err
	###
	contextualizeFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("contextualizeFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.contextualizingFiles, collection.length)

		# Start contextualizing
		docpad.emitSerial 'contextualizeBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = new docpad.TaskGroup "contextualizeFiles tasks", concurrency:0, next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("contextualizeFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'contextualizeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.contextualizedFiles, collection.length)

					# Forward
					return next()

			# Add contextualize tasks
			opts.progress?.step('contextualizeFiles').total(collection.length).setTick(0)
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				slowFilesObject[file.id] = file.get('relativePath') or file.id
				tasks.addTask "conextualizing: #{filePath}", (complete) ->
					file.action 'contextualize', (err) ->
						delete slowFilesObject[file.id]
						opts.progress?.tick()
						return complete(err)

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'contextualizeFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@

	###*
	# Render the DocPad project's files.
	# The renderCollectionBefore, renderCollectionAfter,
	# renderBefore, renderAfter events are all emitted here.
	# @private
	# @method renderFiles
	# @param {Object} [opts={}]
	# @param {Function} next
	# @param {Error} next.err
	###
	renderFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData,renderPasses} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("renderFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.renderingFiles, collection.length)

		# Render File
		# next(null, outContent, file)
		renderFile = (file,next) ->
			# Render
			if file.get('render') is false or !file.get('relativePath')
				file.attributes.rtime = new Date()
				next(null, file.getOutContent(), file)
			else
				file.action('render', {templateData}, next)

			# Return
			return file

		# Render Collection
		renderCollection = (collectionToRender,{renderPass},next) ->
			# Plugin Event
			docpad.emitSerial 'renderCollectionBefore', {collection:collectionToRender,renderPass}, (err) ->
				# Prepare
				return next(err)  if err

				subTasks = new docpad.TaskGroup "renderCollection: #{collectionToRender.options.name}", concurrency:0, next:(err) ->
					# Prepare
					return next(err)  if err

					# Plugin Event
					docpad.emitSerial('renderCollectionAfter', {collection:collectionToRender,renderPass}, next)

				# Cycle
				opts.progress?.step("renderFiles (pass #{renderPass})").total(collectionToRender.length).setTick(0)
				collectionToRender.forEach (file) ->
					filePath = file.getFilePath()
					slowFilesObject[file.id] = file.get('relativePath')
					subTasks.addTask "rendering: #{filePath}", (complete) ->
						renderFile file, (err) ->
							delete slowFilesObject[file.id] or file.id
							opts.progress?.tick()
							return complete(err)

				# Return
				subTasks.run()
				return collectionToRender

		# Plugin Event
		docpad.emitSerial 'renderBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Async
			tasks = new docpad.TaskGroup "renderCollection: renderBefore tasks", next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("renderFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'renderAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.renderedFiles, collection.length)

					# Forward
					return next()

			# Queue the initial render
			initialCollection = collection.findAll('referencesOthers':false)
			subsequentCollection = null
			tasks.addTask "rendering the initial collection", (complete) ->
				renderCollection initialCollection, {renderPass:1}, (err) ->
					return complete(err)  if err
					subsequentCollection = collection.findAll('referencesOthers':true)
					renderCollection(subsequentCollection, {renderPass:2}, complete)

			# Queue the subsequent renders
			if renderPasses > 1
				[3..renderPasses].forEach (renderPass) ->  tasks.addTask "rendering the subsequent collection index #{renderPass}", (complete) ->
					renderCollection(subsequentCollection, {renderPass}, complete)

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'renderFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@

	###*
	# Write rendered files to the DocPad out directory.
	# The writeBefore and writeAfter events are emitted here.
	# @private
	# @method writeFiles
	# @param {Object} [opts={}]
	# @param {Function} next
	# @param {Error} next.err
	###
	writeFiles: (opts={},next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}
		slowFilesTimer = null

		# Update progress
		opts.progress?.step("writeFiles (preparing)").total(1).setTick(0)

		# Log
		docpad.log 'debug', util.format(locale.writingFiles, collection.length)

		# Plugin Event
		docpad.emitSerial 'writeBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = new docpad.TaskGroup "writeFiles tasks", concurrency:0, next:(err) ->
				# Kill the timer
				clearInterval(slowFilesTimer)
				slowFilesTimer = null

				# Check
				return next(err)  if err

				# Update progress
				opts.progress?.step("writeFiles (postparing)").total(1).setTick(0)

				# After
				docpad.emitSerial 'writeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# docpad.log 'debug', util.format(locale.wroteFiles, collection.length)
					return next()

			# Add write tasks
			opts.progress?.step('writeFiles').total(collection.length).setTick(0)
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				tasks.addTask "writing the file: #{filePath}", (complete) ->
					# Prepare
					slowFilesObject[file.id] = file.get('relativePath')

					# Create sub tasks
					fileTasks = new docpad.TaskGroup "tasks for file write: #{filePath}", concurrency:0, next:(err) ->
						delete slowFilesObject[file.id]
						opts.progress?.tick()
						return complete(err)

					# Write out
					if file.get('write') isnt false and file.get('dynamic') isnt true and file.get('outPath')
						fileTasks.addTask "write out", (complete) ->
							file.action('write', complete)

					# Write source
					if file.get('writeSource') is true and file.get('fullPath')
						fileTasks.addTask "write source", (complete) ->
							file.action('writeSource', complete)

					# Run sub tasks
					fileTasks.run()

			# Setup the timer
			slowFilesTimer = setInterval(
				->
					slowFilesArray = (value or key  for own key,value of slowFilesObject)
					docpad.log('info', util.format(locale.slowFiles, 'writeFiles')+' \n'+slowFilesArray.join('\n'))
				config.slowFilesDelay
			)

			# Run tasks
			tasks.run()

		# Chain
		@


	# ---------------------------------
	# Generate

	# Generate Helpers
	###*
	# Has DocPad's generation process started?
	# @private
	# @property {Boolean} generateStarted
	###
	generateStarted: null

	###*
	# Has DocPad's generation process ended?
	# @private
	# @property {Boolean} generateEnded
	###
	generateEnded: null

	###*
	# Is DocPad currently generating?
	# @private
	# @property {Boolean} generating
	###
	generating: false

	###*
	# Has DocPad done at least one generation?
	# True once the first generation has occured.
	# @private
	# @property {Object} generated
	###
	generated: false

	###*
	# Create the console progress bar.
	# Progress only shown if the DocPad config 'progress'
	# option is true, the DocPad config 'prompts' option is true
	# and the log level is 6 (default)
	# @private
	# @method createProgress
	# @return {Object} the progress object
	###
	createProgress: ->
		# Prepare
		docpad = @
		config = docpad.getConfig()

		# Only show progress if
		# - progress is true
		# - prompts are supported (so no servers)
		# - and we are log level 6 (the default level)
		progress = null
		if config.progress and config.prompts and @getLogLevel() is 6
			progress = require('progressbar').create()
			@getLoggers().console.unpipe(process.stdout)
			@getLogger().once 'log', progress.logListener ?= (data) ->
				if data.levelNumber <= 5  # notice or higher
					docpad.destroyProgress(progress)

		# Return
		return progress

	###*
	# Destructor. Destroy the progress object
	# @private
	# @method destroyProgress
	# @param {Object} progress
	# @return {Object} the progress object
	###
	destroyProgress: (progress) ->
		# Fetch
		if progress
			progress.finish()
			@getLoggers().console.unpipe(process.stdout).pipe(process.stdout)

		# Return
		return progress

	###*
	# Destructor. Destroy the regeneration timer.
	# @private
	# @method destroyRegenerateTimer
	###
	destroyRegenerateTimer: ->
		# Prepare
		docpad = @

		# Clear Regenerate Timer
		if docpad.regenerateTimer
			clearTimeout(docpad.regenerateTimer)
			docpad.regenerateTimer = null

		# Chain
		@

	###*
	# Create the regeneration timer
	# @private
	# @method createRegenerateTimer
	###
	createRegenerateTimer: ->
		# Prepare
		docpad = @
		locale = docpad.getLocale()
		config = docpad.getConfig()

		# Create Regenerate Timer
		if config.regenerateEvery
			docpad.regenerateTimer = setTimeout(
				->
					docpad.log('info', locale.renderInterval)
					docpad.action('generate', config.regenerateEveryOptions)
				config.regenerateEvery
			)

		# Chain
		@

	###*
	# Set off DocPad's generation process.
	# The generated, populateCollectionsBefore, populateCollections, populateCollections
	# generateBefore and generateAfter events are emitted here
	# @method generate
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	generate: (opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = docpad.getConfig()
		locale = docpad.getLocale()
		database = docpad.getDatabase()

		# Check
		return next()  if opts.collection?.length is 0


		# Update generating flag
		lastGenerateStarted = docpad.generateStarted
		docpad.generateStarted = new Date()
		docpad.generateEnded = null
		docpad.generating = true

		# Update the cached database
		docpad.databaseTempCache = new FilesCollection(database.models)  if database.models.length

		# Create Progress
		# Can be over-written by API calls
		opts.progress ?= docpad.createProgress()

		# Grab the template data we will use for rendering
		opts.templateData = docpad.getTemplateData(opts.templateData or {})

		# How many render passes will we require?
		# Can be over-written by API calls
		opts.renderPasses or= config.renderPasses


		# Destroy Regenerate Timer
		docpad.destroyRegenerateTimer()

		# Check plugin count
		docpad.log('notice', locale.renderNoPlugins)  unless docpad.hasPlugins()

		# Log
		docpad.log('info', locale.renderGenerating)
		docpad.notify (new Date()).toLocaleTimeString(), {title: locale.renderGeneratingNotification}

		# Tasks
		tasks = new @TaskGroup("generate tasks", {progress: opts.progress}).done (err) ->
			# Update generating flag
			docpad.generating = false
			docpad.generateEnded = new Date()

			# Update caches
			docpad.databaseTempCache = null

			# Create Regenerate Timer
			docpad.createRegenerateTimer()

			# Clear Progress
			if opts.progress
				docpad.destroyProgress(opts.progress)
				opts.progress = null

			# Error?
			return next(err)  if err

			# Log success message
			seconds = (docpad.generateEnded - docpad.generateStarted) / 1000
			howMany = "#{opts.collection?.length or 0}/#{database.length}"
			docpad.log 'info', util.format(locale.renderGenerated, howMany, seconds)
			docpad.notify (new Date()).toLocaleTimeString(), {title: locale.renderGeneratedNotification}

			# Generated
			if opts.initial is true
				docpad.generated = true
				return docpad.emitSerial('generated', opts, next)

			# Safety check if generated is false but initial was false too
			# https://github.com/bevry/docpad/issues/811
			else if docpad.generated is false
				return next(
					new Error('DocPad is in an invalid state, please report this on the github issue tracker. Reference 3360')
				)

			else
				return next()

		# Extract functions from tasks for simplicity
		# when dealing with nested tasks/groups
		addGroup = tasks.addGroup.bind(tasks)
		addTask = tasks.addTask.bind(tasks)


		# Setup a clean database
		addTask 'Reset our collections', (complete) ->
			# Skip if we are not a reset generation, or an initial generation (generated is false)
			return complete()  unless opts.reset is true or docpad.generated is false
			return docpad.resetCollections(opts, complete)


		# Figure out the options
		# This is here as resetCollections could change our state
		# https://github.com/bevry/docpad/issues/811
		addTask 'Figure out options', ->
			# Mode: Cache
			# Shall we write to the database cache?
			# Set to true if the configuration option says we can, and we are the initial generation
			opts.cache     ?= config.databaseCache

			# Mode: Initial
			# Shall we do some basic initial checks
			# Set to the opts.reset value if specified, or whether are the initial generation
			opts.initial   ?= !(docpad.generated)

			# Mode: Reset
			# Shall we reset the database
			# Set to true if we are the initial generation
			opts.reset     ?= opts.initial

			# Mode: Populate
			# Shall we fetch in new data?
			# Set to the opts.reset value if specified, or the opts.initial value
			opts.populate  ?= opts.reset

			# Mode: Reload
			# Shall we rescan the file system for changes?
			# Set to the opts.reset value if specified, or the opts.initial value
			opts.reload    ?= opts.reset

			# Mode: Partial
			# Shall we perform a partial generation (false) or a completion generation (true)?
			# Set to false if we are the initial generation
			opts.partial   ?= !(opts.reset)

			# Log our opts
			docpad.log(
				'debug'
				'Generate options:'
				pick(opts, ['cache', 'initial', 'reset', 'populate', 'reload', 'partial', 'renderPasses'])
			)


		# Check directory structure
		addTask 'check source directory exists', (complete) ->
			# Skip if we are not the initial generation
			return complete()  unless opts.initial is true

			# Continue if we are the initial generation
			safefs.exists config.srcPath, (exists) ->
				# Check
				unless exists
					err = new Error(locale.renderNonexistant)
					return complete(err)

				# Forward
				return complete()


		addGroup 'fetch data to render', (addGroup, addTask) ->
			# Fetch new data
			# If we are a populate generation (by default an initial generation)
			if opts.populate is true
				# This will pull in new data from plugins
				addTask 'populateCollectionsBefore', (complete) ->
					docpad.emitSerial('populateCollectionsBefore', opts, complete)

				# Import the cached data
				# If we are the initial generation, and we have caching enabled
				if opts.initial is true and opts.cache in [true, 'read']
					addTask 'import data from cache', (complete) ->
						# Check if we do have a databae cache
						safefs.exists config.databaseCachePath, (exists) ->
							return complete()  if exists is false

							# Read the database cache if it exists
							safefs.readFile config.databaseCachePath, (err, data) ->
								return complete(err)  if err

								# Parse it and apply the data values
								databaseData = JSON.parse data.toString()
								opts.cache     = true
								opts.initial   = true
								opts.reset     = false
								opts.populate  = true
								opts.reload    = true
								opts.partial   = true

								lastGenerateStarted = new Date(databaseData.generateStarted)
								addedModels = docpad.addModels(databaseData.models)
								docpad.log 'info', util.format(locale.databaseCacheRead, database.length, databaseData.models.length)

								# @TODO we need a way of detecting deleted files between generations

								return complete()

				# Rescan the file system
				# If we are a reload generation (by default an initial generation)
				# This is useful when the database is out of sync with the source files
				# For instance, someone shut down docpad, and made some changes, then ran docpad again
				# See https://github.com/bevry/docpad/issues/705#issuecomment-29243666 for details
				if opts.reload is true
					addGroup 'import data from file system', (addGroup, addTask) ->
						# Documents
						config.documentsPaths.forEach (documentsPath) ->
							addTask 'import documents', (complete) ->
								docpad.parseDirectory({
									modelType: 'document'
									collection: database
									path: documentsPath
									next: complete
								})

						# Files
						config.filesPaths.forEach (filesPath) ->
							addTask 'import files', (complete) ->
								docpad.parseDirectory({
									modelType: 'file'
									collection: database
									path: filesPath
									next: complete
								})

						# Layouts
						config.layoutsPaths.forEach (layoutsPath) ->
							addTask 'import layouts', (complete) ->
								docpad.parseDirectory({
									modelType: 'document'
									collection: database
									path: layoutsPath
									next: complete
								})

				# This will pull in new data from plugins
				addTask 'populateCollections', (complete) ->
					docpad.emitSerial('populateCollections', opts, complete)


		addGroup 'determine files to render', (addGroup, addTask) ->
			# Perform a complete regeneration
			# If we are a reset generation (by default an initial non-cached generation)
			if opts.partial is false
				# Use Entire Collection
				addTask 'Add all database models to render queue', ->
					opts.collection ?= new FilesCollection().add(docpad.getCollection('generate').models)

			# Perform a partial regeneration
			# If we are not a reset generation (by default any non-initial generation)
			else
				# Use Partial Collection
				addTask 'Add only changed models to render queue', ->
					changedQuery =
						$or:
							# Get changed files
							mtime: $gte: lastGenerateStarted

							# Get new files
							$and:
								wtime: null
								write: true
					opts.collection ?= new FilesCollection().add(docpad.getCollection('generate').findAll(changedQuery).models)


		addTask 'generateBefore', (complete) ->
			# If we have nothing to generate
			if opts.collection.length is 0
				# then there is no need to execute further tasks
				tasks.clear()
				complete()

			# Otherwise continue down the task loop
			else
				docpad.emitSerial('generateBefore', opts, complete)


		addTask 'prepare files', (complete) ->
			# Log the files to generate if we are in debug mode
			docpad.log 'debug', 'Files to generate at', (lastGenerateStarted), '\n', (
				{
					id: model.id
					path: model.getFilePath()
					mtime: model.get('mtime')
					wtime: model.get('wtime')
					dynamic: model.get('dynamic')
					ignored: model.get('ignored')
					write: model.get('write')
				}  for model in opts.collection.models
			)

			# Add anything that references other documents (e.g. partials, listing, etc)
			# This could eventually be way better
			standalones = opts.collection.pluck('standalone')
			allStandalone = standalones.indexOf(false) is -1
			if allStandalone is false
				opts.collection.add(docpad.getCollection('referencesOthers').models)

			# Deeply/recursively add the layout children
			addLayoutChildren = (collection) ->
				collection.forEach (file) ->
					if file.get('isLayout') is true
						# Find
						layoutChildrenQuery =
							layoutRelativePath: file.get('relativePath')
						layoutChildrenCollection = docpad.getCollection('hasLayout').findAll(layoutChildrenQuery)

						# Log the files to generate if we are in debug mode
						docpad.log 'debug', 'Layout children to generate at', (lastGenerateStarted), '\n', (
							{
								id: model.id
								path: model.getFilePath()
								mtime: model.get('mtime')
								wtime: model.get('wtime')
								write: model.get('write')
							}  for model in layoutChildrenCollection.models
						), '\n', layoutChildrenQuery

						# Recurse
						addLayoutChildren(layoutChildrenCollection)

						# Add
						opts.collection.add(layoutChildrenCollection.models)
			addLayoutChildren(opts.collection)

			# Filter out ignored, and no-render no-write files
			opts.collection.reset opts.collection.reject (file) ->
				return (file.get('render') is false and file.get('write') is false)

			# Log the files to generate if we are in debug mode
			docpad.log 'debug', 'Files to generate at', (lastGenerateStarted), '\n', (
				{
					id: model.id
					path: model.getFilePath()
					mtime: model.get('mtime')
					wtime: model.get('wtime')
					dynamic: model.get('dynamic')
					ignored: model.get('ignored')
					write: model.get('write')
				}  for model in opts.collection.models
			)

			# Forward
			return complete()


		addGroup 'process file', (addGroup, addTask) ->
			addTask 'contextualizeFiles', {args:[opts]}, docpad.contextualizeFiles.bind(docpad)
			addTask 'renderFiles', {args:[opts]}, docpad.renderFiles.bind(docpad)
			addTask 'writeFiles', {args:[opts]}, docpad.writeFiles.bind(docpad)


		addTask 'generateAfter', (complete) ->
			docpad.emitSerial('generateAfter', opts, complete)


		# Write the cache file
		addTask 'Write the database cache', (complete) ->
			# Skip if we do not care for writing the cache
			return complete()  unless opts.cache in [true, 'write']

			# Write the cache
			databaseData =
				generateStarted: docpad.generateStarted
				generateEnded: docpad.generateEnded
				models: (model.getAttributes()  for model in database.models)
			databaseDataDump = JSON.stringify(databaseData, null, '  ')
			docpad.log 'info', util.format(locale.databaseCacheWrite, databaseData.models.length)
			return safefs.writeFile(config.databaseCachePath, databaseDataDump, complete)


		# Run
		tasks.run()

		# Chain
		@


	# ---------------------------------
	# Render

	###*
	# Load a document
	# @private
	# @method loadDocument
	# @param {Object} document
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.document
	###
	loadDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Load
		# @TODO: don't load if already loaded
		document.action('load contextualize', opts, next)

		# Chain
		@

	###*
	# Load and render a document
	# @method loadAndRenderDocument
	# @param {Object} document
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.document
	###
	loadAndRenderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @

		# Load
		docpad.loadDocument document, opts, (err) ->
			return next(err)  if err

			# Render
			docpad.renderDocument(document, opts, next)

		# Chain
		@

	###*
	# Render a document
	# @method renderDocument
	# @param {Object} document
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @param {Object} next.result
	# @param {Object} next.document
	###
	renderDocument: (document,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)

		# Render
		clone = document.clone().action 'render', opts, (err) ->
			result = clone.getOutContent()
			return next(err, result, document)

		# Chain
		@

	###*
	# Render a document at a file path
	# next(err,result)
	# @method renderPath
	# @param {String} path
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.result the rendered document
	###
	renderPath: (path,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			fullPath: path
		},opts.attributes)

		# Handle
		document = @createDocument(attributes)
		@loadAndRenderDocument(document, opts, next)

		# Chain
		@

	###*
	# Render the passed content data as a
	# document. Required option, filename
	# (opts.filename)
	# next(err,result)
	# @method renderData
	# @param {String} content
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.result the rendered document
	###
	renderData: (content,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		attributes = extendr.extend({
			filename: opts.filename
			data: content
		}, opts.attributes)

		# Handle
		document = @createDocument(attributes)
		@loadAndRenderDocument(document, opts, next)

		# Chain
		@

	# Render Text
	# Doesn't extract meta information, or render layouts
	# TODO: Why not? Why not just have renderData?

	###*
	# Render the passed text data as a
	# document. Required option, filename
	# (opts.filename)
	# next(err,result)
	# @private
	# @method renderText
	# @param {String} text
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Object} next.result the rendered content
	# @param {Object} next.document the rendered document model
	###
	renderText: (text,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		opts.actions ?= ['renderExtensions', 'renderDocument']
		attributes = extendr.extend({
			filename: opts.filename
			data: text
			body: text
			content: text
		}, opts.attributes)

		# Handle
		document = @createDocument(attributes)

		# Render
		clone = document.clone().action 'normalize contextualize render', opts, (err) ->
			result = clone.getOutContent()
			return next(err, result, document)

		# Chain
		@

	###*
	# Render action
	# next(err,document,result)
	# @method render
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	render: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		locale = @getLocale()

		# Extract document
		if opts.document
			@renderDocument(opts.document, opts, next)
		else if opts.data
			@renderData(opts.data, opts, next)
		else if opts.text
			@renderText(opts.text, opts, next)
		else
			path = opts.path or opts.fullPath or opts.filename or null
			if path
				@renderPath(path, opts, next)
			else
				# Check
				err = new Error(locale.renderInvalidOptions)
				return next(err)

		# Chain
		@


	# ---------------------------------
	# Watch

	###*
	# Array of file watchers
	# @private
	# @property {Array} watchers
	###
	watchers: null

	###*
	# Destructor. Destroy the watchers used
	# by DocPad
	# @private
	# @method destroyWatchers
	###
	destroyWatchers: ->
		# Prepare
		docpad = @

		# Check
		if docpad.watchers
			# Close each of them
			for watcher in docpad.watchers
				watcher.close()

			# Reset the array
			docpad.watchers = []

		# Chain
		@

	###*
	# Start up file watchers used by DocPad
	# @private
	# @method watch
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	watch: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		database = @getDatabase()
		@watchers ?= []

		# Restart our watchers
		restartWatchers = (next) ->
			# Close our watchers
			docpad.destroyWatchers()

			# Start a group
			tasks = new docpad.TaskGroup("watch tasks", {concurrency:0, next})

			# Watch reload paths
			reloadPaths = union(config.reloadPaths, config.configPaths)
			tasks.addTask "watch reload paths", (complete) -> docpad.watchdir(
				paths: reloadPaths
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': ->
						docpad.log 'info', util.format(locale.watchReloadChange, new Date().toLocaleTimeString())
						docpad.action 'load', (err) ->
							return docpad.fatal(err)  if err
							performGenerate(reset:true)
				next: (err,_watchers) ->
					if err
						docpad.warn("Watching the reload paths has failed:\n"+docpad.inspector(reloadPaths), err)
						return complete()
					for watcher in _watchers
						docpad.watchers.push(watcher)
					return complete()
			)

			# Watch regenerate paths
			regeneratePaths = config.regeneratePaths
			tasks.addTask "watch regenerate paths", (complete) -> docpad.watchdir(
				paths: regeneratePaths
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': -> performGenerate(reset:true)
				next: (err,_watchers) ->
					if err
						docpad.warn("Watching the regenerate paths has failed:\n"+docpad.inspector(regeneratePaths), err)
						return complete()
					for watcher in _watchers
						docpad.watchers.push(watcher)
					return complete()
			)

			# Watch the source
			srcPath = config.srcPath
			tasks.addTask "watch the source path", (complete) -> docpad.watchdir(
				path: srcPath
				listeners:
					'log': docpad.log
					'error': docpad.error
					'change': changeHandler
				next: (err,watcher) ->
					if err
						docpad.warn("Watching the src path has failed: "+srcPath, err)
						return complete()
					docpad.watchers.push(watcher)
					return complete()
			)

			# Run
			tasks.run()

			# Chain
			@

		# Timer
		regenerateTimer = null
		queueRegeneration = ->
			# Reset the wait
			if regenerateTimer
				clearTimeout(regenerateTimer)
				regenerateTimer = null

			# Regenerat after a while
			regenerateTimer = setTimeout(performGenerate, config.regenerateDelay)

		performGenerate = (opts={}) ->
			# Q: Should we also pass over the collection?
			# A: No, doing the mtime query in generate is more robust

			# Log
			docpad.log util.format(locale.watchRegenerating, new Date().toLocaleTimeString())

			# Afterwards, re-render anything that should always re-render
			docpad.action 'generate', opts, (err) ->
				docpad.error(err)  if err
				docpad.log util.format(locale.watchRegenerated, new Date().toLocaleTimeString())

		# Change event handler
		changeHandler = (changeType,filePath,fileCurrentStat,filePreviousStat) ->
			# Prepare
			fileEitherStat = (fileCurrentStat or filePreviousStat)

			# For some reason neither of the stats may exist, this will cause errors as this is an invalid state
			# as we depend on at least one stat existing, otherwise, what on earth is going on?
			# Whatever the case, this should be fixed within watchr, not docpad
			# as watchr should not be giving us invalid data
			# https://github.com/bevry/docpad/issues/792
			unless fileEitherStat
				err = new Error("""
						DocPad has encountered an invalid state while detecting changes for your files.
						So the DocPad team can fix this right away, please provide any information you can to:
						https://github.com/bevry/docpad/issues/792
						""")
				return docpad.error(err)

			# Log the change
			docpad.log 'info', util.format(locale.watchChange, new Date().toLocaleTimeString()), changeType, filePath

			# Check if we are a file we don't care about
			# This check should not be needed with v2.3.3 of watchr
			# however we've still got it here as it may still be an issue
			isIgnored = docpad.isIgnoredPath(filePath)
			if isIgnored
				docpad.log 'debug', util.format(locale.watchIgnoredChange, new Date().toLocaleTimeString()), filePath
				return

			# Don't care if we are a directory
			isDirectory = fileEitherStat.isDirectory()
			if isDirectory
				docpad.log 'debug', util.format(locale.watchDirectoryChange, new Date().toLocaleTimeString()), filePath
				return

			# Override the stat's mtime to now
			# This is because renames will not update the mtime
			fileCurrentStat?.mtime = new Date()

			# Create the file object
			file = docpad.addModel({fullPath:filePath, stat:fileCurrentStat})
			file.setStat(fileCurrentStat)  if changeType is 'update'

			# File was deleted, delete the rendered file, and remove it from the database
			if changeType is 'delete'
				database.remove(file)
				file.action 'delete', (err) ->
					return docpad.error(err)  if err
					queueRegeneration()

			# File is new or was changed, update it's mtime by setting the stat
			else if changeType in ['create', 'update']
				file.action 'load', (err) ->
					return docpad.error(err)  if err
					queueRegeneration()

		# Watch
		docpad.log(locale.watchStart)
		restartWatchers (err) ->
			return next(err)  if err
			docpad.log(locale.watchStarted)
			return next()

		# Chain
		@


	# ---------------------------------
	# Run Action

	###*
	# Run an action
	# @method run
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	run: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		locale = @getLocale()
		config = @getConfig()
		{srcPath, rootPath} = config

		# Prepare
		run = (complete) ->
			balUtil.flow(
				object: docpad
				action: 'server generate watch'
				args: [opts]
				next: complete
			)

		# Check if we have the docpad structure
		safefs.exists srcPath, (exists) ->
			# Check if have the correct structure, if so let's proceed with DocPad
			return run(next)  if exists

			# We don't have the correct structure
			# Check if we are running on an empty directory
			safefs.readdir rootPath, (err,files) ->
				return next(err)  if err

				# Check if our directory is empty
				if files.length
					# It isn't empty, display a warning
					docpad.warn util.format(locale.skeletonNonexistant, rootPath)
					return next()
				else
					docpad.skeleton opts, (err) ->
						# Check
						return next(err)  if err

						# Keep in global?
						return run(next)  if opts.global is true or docpad.getConfig().global is true

						# Log
						docpad.log('notice', locale.startLocal)

						# Destroy our DocPad instance so we can boot the local one
						docpad.destroy (err) ->
							# Check
							return next(err)  if err

							# Forward onto the local DocPad Instance now that it has been installed
							return docpadUtil.startLocalDocPadExecutable(next)

		# Chain
		@


	# ---------------------------------
	# Skeleton

	###*
	# Initialize the skeleton install process.
	# @private
	# @method initInstall
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	initInstall: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new @TaskGroup("initInstall tasks", {concurrency:0, next})

		tasks.addTask "node modules", (complete) ->
			path = pathUtil.join(config.rootPath, 'node_modules')
			safefs.ensurePath(path, complete)

		tasks.addTask "package", (complete) ->
			# Exists?
			path = pathUtil.join(config.rootPath, 'package.json')
			safefs.exists path, (exists) ->
				# Check
				return complete()  if exists

				# Write
				data = JSON.stringify({
					name: 'no-skeleton.docpad'
					version: '0.1.0'
					description: 'New DocPad project without using a skeleton'
					dependencies:
						docpad: '~'+docpad.getVersion()
					main: 'node_modules/.bin/docpad-server'
					scripts:
						start: 'node_modules/.bin/docpad-server'
				}, null, '  ')
				safefs.writeFile(path, data, complete)

		# Run
		tasks.run()

		# Chain
		@

	###*
	# Uninstall a plugin.
	# @private
	# @method uninstall
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	uninstall: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new @TaskGroup("uninstall tasks", {next})

		# Uninstall a plugin
		if opts.plugin
			tasks.addTask "uninstall the plugin: #{opts.plugin}", (complete) ->
				plugins =
					for plugin in opts.plugin.split(/[,\s]+/)
						plugin = "docpad-plugin-#{plugin}"  if plugin.indexOf('docpad-plugin-') isnt 0
						plugin
				docpad.uninstallNodeModule(plugins, {
					stdio: 'inherit'
					next: complete
				})

		# Re-load configuration
		tasks.addTask "re-load configuration", (complete) ->
			docpad.load(complete)

		# Run
		tasks.run()

		# Chain
		@

	###*
	# Install a plugin
	# @private
	# @method install
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	install: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new @TaskGroup("install tasks", {next})

		tasks.addTask "init the installation", (complete) ->
			docpad.initInstall(opts, complete)

		# Install a plugin
		if opts.plugin
			tasks.addTask "install the plugin: #{opts.plugin}", (complete) ->
				plugins =
					for plugin in opts.plugin.split(/[,\s]+/)
						plugin = "docpad-plugin-#{plugin}"  if plugin.indexOf('docpad-plugin-') isnt 0
						plugin += '@'+docpad.pluginVersion  if plugin.indexOf('@') is -1
						plugin
				docpad.installNodeModule(plugins, {
					stdio: 'inherit'
					next: complete
				})

		tasks.addTask "re-initialize the website's modules", (complete) ->
			docpad.initNodeModules({
				stdio: 'inherit'
				next: complete
			})

		tasks.addTask "fix node package versions", (complete) ->
			docpad.fixNodePackageVersions(complete)

		tasks.addTask "re-load the configuration", (complete) ->
			docpad.load(complete)

		# Run
		tasks.run()

		# Chain
		@

	###*
	# Update global NPM and DocPad
	# @private
	# @method upgrade
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @return {Object} description
	###
	upgrade: (opts,next) ->
		# Update Global NPM and DocPad
		@installNodeModule('npm docpad@6', {
			global: true
			stdio: 'inherit'
			next: next
		})

		# Chain
		@

	###*
	# Update the local DocPad and plugin dependencies
	# @private
	# @method update
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	###
	update: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Tasks
		tasks = new @TaskGroup("update tasks", {next})

		tasks.addTask "init the install", (complete) ->
			docpad.initInstall(opts, complete)

		# Update the local docpad and plugin dependencies
		# Grouped together to avoid npm dependency shortcuts that can cause missing dependencies
		# But don't update git/http/https dependencies, those are special for some reason
		# > https://github.com/bevry/docpad/pull/701
		dependencies = []
		eachr docpad.websitePackageConfig.dependencies, (version,name) ->
			return  if /^docpad-plugin-/.test(name) is false or /// :// ///.test(version) is true
			dependencies.push(name+'@'+docpad.pluginVersion)
		if dependencies.length isnt 0
			tasks.addTask "update plugins that are dependencies", (complete) ->
				docpad.installNodeModule('docpad@6 '+dependencies, {
					stdio: 'inherit'
					next: complete
				})

		# Update the plugin dev dependencies
		devDependencies = []
		eachr docpad.websitePackageConfig.devDependencies, (version,name) ->
			return  if /^docpad-plugin-/.test(name) is false
			devDependencies.push(name+'@'+docpad.pluginVersion)
		if devDependencies.length isnt 0
			tasks.addTask "update plugins that are dev dependencies", (complete) ->
				docpad.installNodeModule(devDependencies, {
					save: '--save-dev'
					stdio: 'inherit'
					next: complete
				})

		tasks.addTask "fix node package versions", (complete) ->
			docpad.fixNodePackageVersions(complete)

		tasks.addTask "re-initialize the rest of the website's modules", (complete) ->
			docpad.initNodeModules({
				stdio: 'inherit'
				next: complete
			})

		# Run
		tasks.run()

		# Chain
		@

	###*
	# DocPad cleanup tasks.
	# @private
	# @method clean
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @return {Object} description
	###
	clean: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = docpad.getConfig()
		locale = @getLocale()

		# Log
		docpad.log('info', locale.renderCleaning)

		# Tasks
		tasks = new @TaskGroup "clean tasks", {concurrency:0}, next:(err) ->
			# Error?
			return next(err)  if err

			# Log
			docpad.log('info', locale.renderCleaned)

			# Forward
			return next()

		tasks.addTask 'reset the collecitons', (complete) ->
			docpad.resetCollections(opts, complete)

		# Delete out path
		# but only if our outPath is not a parent of our rootPath
		tasks.addTask 'delete out path', (complete) ->
			# Check if our outPath is higher than our root path, so do not remove files
			return complete()  if config.rootPath.indexOf(config.outPath) isnt -1

			# Our outPath is not related or lower than our root path, so do remove it
			rimraf(config.outPath, complete)

		# Delete database cache
		tasks.addTask 'delete database cache file', (complete) ->
			safefs.unlink(config.databaseCachePath, complete)

		# Run tasks
		tasks.run()

		# Chain
		@



	###*
	# Initialize a Skeleton into to a Directory
	# @private
	# @method initSkeleton
	# @param {Object} skeletonModel
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	initSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @getConfig()

		# Defaults
		opts.destinationPath ?= config.rootPath

		# Tasks
		tasks = new @TaskGroup("initSkeleton tasks", {next})

		tasks.addTask "ensure the path we are writing to exists", (complete) ->
			safefs.ensurePath(opts.destinationPath, complete)

		# Clone out the repository if applicable
		if skeletonModel? and skeletonModel.id isnt 'none'
			tasks.addTask "clone out the git repo", (complete) ->
				docpad.initGitRepo({
					cwd: opts.destinationPath
					url: skeletonModel.get('repo')
					branch: skeletonModel.get('branch')
					remote: 'skeleton'
					stdio: 'inherit'
					next: complete
				})
		else
			tasks.addTask "ensure src path exists", (complete) ->
				safefs.ensurePath(config.srcPath, complete)

			tasks.addGroup "initialize the website directory files", ->
				@setConfig(concurrency:0)

				# README
				@addTask "README.md", (complete) ->
					# Exists?
					path = pathUtil.join(config.rootPath, 'README.md')
					safefs.exists path, (exists) ->
						# Check
						return complete()  if exists

						# Write
						data = """
							# Your [DocPad](http://docpad.org) Project

							## License
							Copyright &copy; #{(new Date()).getFullYear()}+ All rights reserved.
							"""
						safefs.writeFile(path, data, complete)

				# Config
				@addTask "docpad.coffee configuration file", (complete) ->
					# Exists?
					docpad.getConfigPath (err,path) ->
						# Check
						return complete(err)  if err or path
						path = pathUtil.join(config.rootPath, 'docpad.coffee')

						# Write
						data = """
							# DocPad Configuration File
							# http://docpad.org/docs/config

							# Define the DocPad Configuration
							docpadConfig = {
								# ...
							}

							# Export the DocPad Configuration
							module.exports = docpadConfig
							"""
						safefs.writeFile(path, data, complete)

				# Documents
				@addTask "documents directory", (complete) ->
					safefs.ensurePath(config.documentsPaths[0], complete)

				# Layouts
				@addTask "layouts directory", (complete) ->
					safefs.ensurePath(config.layoutsPaths[0], complete)

				# Files
				@addTask "files directory", (complete) ->
					safefs.ensurePath(config.filesPaths[0], complete)

		# Run
		tasks.run()

		# Chain
		@

	###*
	# Install a Skeleton into a Directory
	# @private
	# @method installSkeleton
	# @param {Object} skeletonModel
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	installSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @

		# Defaults
		opts.destinationPath ?= @getConfig().rootPath

		# Initialize and install the skeleton
		docpad.initSkeleton skeletonModel, opts, (err) ->
			# Check
			return next(err)  if err

			# Forward
			docpad.install(opts, next)

		# Chain
		@

	###*
	# Use a Skeleton
	# @private
	# @method useSkeleton
	# @param {Object} skeletonModel
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @return {Object} description
	###
	useSkeleton: (skeletonModel,opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()

		# Defaults
		opts.destinationPath ?= @getConfig().rootPath

		# Extract
		skeletonId = skeletonModel?.id or 'none'
		skeletonName = skeletonModel?.get('name') or locale.skeletonNoneName

		# Track
		docpad.track('skeleton-use', {skeletonId})

		# Log
		docpad.log('info', util.format(locale.skeletonInstall, skeletonName, opts.destinationPath)+' '+locale.pleaseWait)

		# Install Skeleton
		docpad.installSkeleton skeletonModel, opts, (err) ->
			# Error?
			return next(err)  if err

			# Log
			docpad.log('info', locale.skeletonInstalled)

			# Forward
			return next(err)

		# Chain
		@


	###*
	# Select a Skeleton
	# @private
	# @method selectSkeleton
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	# @param {Error} next.skeletonModel
	###
	selectSkeleton: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		opts.selectSkeletonCallback ?= null

		# Track
		docpad.track('skeleton-ask')

		# Get the available skeletons
		docpad.getSkeletons (err,skeletonsCollection) ->
			# Check
			return next(err)  if err

			# Provide selection to the interface
			opts.selectSkeletonCallback(skeletonsCollection, next)

		# Chain
		@

	###*
	# Skeleton Empty?
	# @private
	# @method skeletonEmpty
	# @param {Object} path
	# @param {Function} next
	# @param {Error} next.err
	###
	skeletonEmpty: (path, next) ->
		# Prepare
		locale = @getLocale()

		# Defaults
		path ?= @getConfig().rootPath

		# Check the destination path is empty
		safefs.exists pathUtil.join(path, 'package.json'), (exists) ->
			# Check
			if exists
				err = new Error(locale.skeletonExists)
				return next(err)

			# Success
			return next()

		# Chain
		@

	###*
	# Initialize the project directory
	# with the basic skeleton.
	# @private
	# @method skeleton
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	skeleton: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		opts.selectSkeletonCallback ?= null

		# Init the directory with the basic skeleton
		@skeletonEmpty null, (err) ->
			# Check
			return next(err)  if err

			# Select Skeleton
			docpad.selectSkeleton opts, (err,skeletonModel) ->
				# Check
				return next(err)  if err

				# Use Skeleton
				docpad.useSkeleton(skeletonModel, next)

		# Chain
		@

	###*
	# Initialize the project directory
	# with the basic skeleton.
	# @private
	# @method init
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @return {Object} description
	###
	init: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @

		# Init the directory with the basic skeleton
		@skeletonEmpty null, (err) ->
			# Check
			return next(err)  if err

			# Basic Skeleton
			docpad.useSkeleton(null, next)

		# Chain
		@


	# ---------------------------------
	# Server

	###*
	# Serve a document
	# @private
	# @method serveDocument
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	serveDocument: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{document,err,req,res} = opts
		docpad = @
		config = @getConfig()

		# If no document, then exit early
		unless document
			if opts.statusCode?
				return res.send(opts.statusCode)
			else
				return next()

		# Prepare
		res.setHeaderIfMissing ?= (name, value) ->
			res.setHeader(name, value)  unless res.getHeader(name)

		# Content Type + Encoding/Charset
		encoding = document.get('encoding')
		charset = 'utf-8'  if encoding in ['utf8', 'utf-8']
		contentType = document.get('outContentType') or document.get('contentType')
		res.setHeaderIfMissing('Content-Type', contentType + (if charset then "; charset=#{charset}" else ''))

		# Cache-Control (max-age)
		res.setHeaderIfMissing('Cache-Control', "public, max-age=#{config.maxAge}")  if config.maxAge

		# Send
		dynamic = document.get('dynamic')
		if dynamic
			# If you are debugging why a dynamic document isn't rendering
			# it could be that you don't have cleanurls installed
			# e.g. if index.html is dynamic, and you are accessing it via /
			# then this code will not be reached, as we don't register that url
			# where if we have the cleanurls plugin installed, then do register that url
			# against the document, so this is reached
			collection = new FilesCollection([document], {name:'dynamic collection'})
			templateData = extendr.extend({}, req.templateData or {}, {req,err})
			docpad.action 'generate', {collection, templateData}, (err) ->
				content = document.getOutContent()
				if err
					docpad.error(err)
					return next(err)
				else
					if opts.statusCode?
						return res.send(opts.statusCode, content)
					else
						return res.send(content)

		else
			# ETag: `"<size>-<mtime>"`
			ctime = document.get('date')    # use the date or mtime, it should always exist
			mtime = document.get('wtime')   # use the last generate time, it may not exist though
			stat = document.getStat()
			etag = stat.size + '-' + Number(mtime)   if mtime and stat
			res.setHeaderIfMissing('ETag', '"' + etag + '"')  if etag

			# Date
			res.setHeaderIfMissing('Date', ctime.toUTCString())  if ctime?.toUTCString?
			res.setHeaderIfMissing('Last-Modified', mtime.toUTCString())  if mtime?.toUTCString?
			# @TODO:
			# The above .toUTCString? check is a workaround because sometimes the date object
			# isn't really a date object, this needs to be fixed properly
			# https://github.com/bevry/docpad/pull/781

			# Send
			if etag and etag is (req.get('If-None-Match') or '').replace(/^"|"$/g, '')
				res.send(304)  # not modified
			else
				content = document.getOutContent()
				if content
					if opts.statusCode?
						res.send(opts.statusCode, content)
					else
						res.send(content)
				else
					if opts.statusCode?
						res.send(opts.statusCode)
					else
						next()

		# Chain
		@


	###*
	# Server Middleware: Header
	# @private
	# @method serverMiddlewareHeader
	# @param {Object} req
	# @param {Object} res
	# @param {Object} next
	###
	serverMiddlewareHeader: (req,res,next) ->
		# Prepare
		docpad = @

		# Handle
		# Always enable this until we get a complaint about not having it
		# For instance, Express.js also forces this
		tools = res.get('X-Powered-By').split(/[,\s]+/g)
		tools.push("DocPad v#{docpad.getVersion()}")
		tools = tools.join(', ')
		res.set('X-Powered-By', tools)

		# Forward
		next()

		# Chain
		@


	###*
	# Server Middleware: Router
	# @private
	# @method serverMiddlewareRouter
	# @param {Object} req
	# @param {Object} res
	# @param {Function} next
	# @param {Error} next.err
	###
	serverMiddlewareRouter: (req,res,next) ->
		# Prepare
		docpad = @

		# Get the file
		docpad.getFileByRoute req.url, (err,file) ->
			# Check
			return next(err)  if err or file? is false

			# Check if we are the desired url
			# if we aren't do a permanent redirect
			url = file.get('url')
			cleanUrl = docpad.getUrlPathname(req.url)
			if (url isnt cleanUrl) and (url isnt req.url)
				return res.redirect(301, url)

			# Serve the file to the user
			docpad.serveDocument({document:file, req, res, next})

		# Chain
		@


	###*
	# Server Middleware: 404
	# @private
	# @method serverMiddleware404
	# @param {Object} req
	# @param {Object} res
	# @param {Object} next
	###
	serverMiddleware404: (req,res,next) ->
		# Prepare
		docpad = @
		database = docpad.getDatabaseSafe()

		# Notify the user of a 404
		docpad.log('notice', "404 Not Found:", req.url)

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '404.html'})
		docpad.serveDocument({document, req, res, next, statusCode:404})

		# Chain
		@


	###*
	# Server Middleware: 500
	# @private
	# @method serverMiddleware500
	# @param {Object} err
	# @param {Object} req
	# @param {Object} res
	# @param {Function} next
	###
	serverMiddleware500: (err,req,res,next) ->
		# Prepare
		docpad = @
		database = docpad.getDatabaseSafe()

		# Check
		return res.send(500)  unless database

		# Serve the document to the user
		document = database.findOne({relativeOutPath: '500.html'})
		docpad.serveDocument({document,err,req,res,next,statusCode:500})

		# Chain
		@

	###*
	# Configure and start up the DocPad web server.
	# Http and express server is created, extended with
	# middleware, started up and begins listening.
	# The events serverBefore, serverExtend and
	# serverAfter emitted here.
	# @private
	# @method server
	# @param {Object} opts
	# @param {Function} next
	###
	server: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		config = @config
		locale = @getLocale()
		port = @getPort()
		hostname = @getHostname()

		# Require
		http = require('http')
		express = require('express')

		# Config
		servers = @getServer(true)
		opts.serverExpress ?= servers.serverExpress
		opts.serverHttp ?= servers.serverHttp
		opts.middlewareBodyParser ?= config.middlewareBodyParser ? config.middlewareStandard
		opts.middlewareMethodOverride ?= config.middlewareMethodOverride ? config.middlewareStandard
		opts.middlewareExpressRouter ?= config.middlewareExpressRouter ? config.middlewareStandard
		opts.middleware404 ?= config.middleware404
		opts.middleware500 ?= config.middleware500
		# @TODO: Why do we do opts here instead of config???

		# Tasks
		tasks = new @TaskGroup("server tasks", {next})

		# Before Plugin Event
		tasks.addTask "emit serverBefore", (complete) ->
			docpad.emitSerial('serverBefore', complete)

		# Create server when none is defined
		if !opts.serverExpress or !opts.serverHttp
			tasks.addTask "create server", ->
				opts.serverExpress or= express()
				opts.serverHttp or= http.createServer(opts.serverExpress)
				docpad.setServer(opts)

		# Extend the server with our middlewares
		if config.extendServer is true
			tasks.addTask "extend the server", (complete) ->
				# Parse url-encoded and json encoded form data
				if opts.middlewareBodyParser isnt false
					opts.serverExpress.use(express.urlencoded())
					opts.serverExpress.use(express.json())

				# Allow over-riding of the request type (e.g. GET, POST, PUT, DELETE)
				if opts.middlewareMethodOverride isnt false
					if typeChecker.isString(opts.middlewareMethodOverride)
						opts.serverExpress.use(require('method-override')(opts.middlewareMethodOverride))
					else
						opts.serverExpress.use(require('method-override')())

				# Emit the serverExtend event
				# So plugins can define their routes earlier than the DocPad routes
				docpad.emitSerial 'serverExtend', {
					server: opts.serverExpress # b/c
					express: opts.serverExpress # b/c
					serverHttp: opts.serverHttp
					serverExpress: opts.serverExpress
				}, (err) ->
					return next(err)  if err

					# DocPad Header Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddlewareHeader)

					# Router Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(opts.serverExpress.router)  if opts.middlewareExpressRouter isnt false

					# DocPad Router Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddlewareRouter)

					# Static
					# Keep it after the serverExtend event
					if config.maxAge
						opts.serverExpress.use(express.static(config.outPath, {maxAge:config.maxAge}))
					else
						opts.serverExpress.use(express.static(config.outPath))

					# DocPad 404 Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddleware404)  if opts.middleware404 isnt false

					# DocPad 500 Middleware
					# Keep it after the serverExtend event
					opts.serverExpress.use(docpad.serverMiddleware500)  if opts.middleware500 isnt false

					# Done
					return complete()

		# Start Server
		tasks.addTask "start the server", (complete) ->
			# Catch
			opts.serverHttp.once 'error', (err) ->
				# Friendlify the error message if it is what we suspect it is
				if err.message.indexOf('EADDRINUSE') isnt -1
					err = new Error(util.format(locale.serverInUse, port))

				# Done
				return complete(err)

			# Listen
			docpad.log 'debug', util.format(locale.serverStart, hostname, port)
			opts.serverHttp.listen port, hostname,  ->
				# Log
				address = opts.serverHttp.address()
				serverUrl = docpad.getServerUrl(
					hostname: address.hostname
					port: address.port
				)
				simpleServerUrl = docpad.getSimpleServerUrl(
					hostname: address.hostname
					port: address.port
				)
				docpad.log 'info', util.format(locale.serverStarted, serverUrl)
				if serverUrl isnt simpleServerUrl
					docpad.log 'info', util.format(locale.serverBrowse, simpleServerUrl)

				# Done
				return complete()

		# After Plugin Event
		tasks.addTask "emit serverAfter", (complete) ->
			docpad.emitSerial('serverAfter', {
				server: opts.serverExpress # b/c
				express: opts.serverExpress # b/c
				serverHttp: opts.serverHttp
				serverExpress: opts.serverExpress
			}, complete)

		# Run the tasks
		tasks.run()

		# Chain
		@


# ---------------------------------
# Export

module.exports = DocPad
