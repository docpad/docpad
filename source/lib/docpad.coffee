##*
# The central module for DocPad
# @module DocPad
##

# =====================================
# Requires

# Standard
util = require('util')
pathUtil = require('path')

# External
Errlop = require('errlop')
queryEngine = require('query-engine')
{uniq, union, pick} = require('underscore')
CSON = require('cson')
balUtil = require('bal-util')
scandir = require('scandirectory')
extendr = require('extendr')
eachr = require('eachr')
typeChecker = require('typechecker')
ambi = require('ambi')
unbounded = require('unbounded')
{TaskGroup} = require('taskgroup')
safefs = require('safefs')
safeps = require('safeps')
ignorefs = require('ignorefs')
rimraf = require('rimraf')
Progress = require('progress-title')
fetch = require('node-fetch')
extractOptsAndCallback = require('extract-opts')
{EventEmitterGrouped} = require('event-emitter-grouped')
envFile = require('envfile')
ansiStyles = require('ansistyles')

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
PluginLoader = require('@bevry/pluginloader')
BasePlugin = require('docpad-baseplugin')


# ---------------------------------
# Variables

isUser = docpadUtil.isUser()


###*
# Contains methods for managing the DocPad application.
# Extends https://github.com/bevry/event-emitter-grouped
#
# You can use it like so:
#
# 	new DocPad(docpadConfig, function(err, docpad) {
# 		if (err) return docpad.fatal(err)
# 		return docpad.action(action, function(err) {
# 			if (err) return docpad.fatal(err)
# 			return console.log('OK')
# 		})
# 	})
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
	@create: (args...) -> return new @(args...)

	# Require a local DocPad file
	# Before v6.73.0 this allowed requiring of files inside src/lib, as well as files inside src
	# After v6.73.0 it only allows requiring of files inside src/lib as that makes more sense
	# After v6.80.9 it only allows requiring specific aliases
	@require: (name) ->
		if name is 'testers'
			console.log(
				''''
				docpad.require('testers') is deprecated, replacement instructions at: https://github.com/docpad/docpad-plugintester
				'''
			)
			return require('docpad-plugintester')
		else
			throw new Errlop("docpad.require is limited to requiring: testers")


	# =================================
	# Variables

	# ---------------------------------
	# Modules

	# ---------------------------------
	# Base

	###*
	# Events class
	# @property {Object} Events
	###
	Events: Events

	###*
	# Model class
	# Extension of the Backbone Model class
	# http://backbonejs.org/#Model
	# @property {Object} Model
	###
	Model: Model

	###*
	# Collection class
	# Extension of the Backbone Collection class
	# http://backbonejs.org/#Collection
	# @property {Object} Collection
	###
	Collection: Collection

	###*
	# QueryCollection class
	# Extension of the Query Engine QueryCollection class
	# @property {Object} QueryCollection
	###
	QueryCollection: QueryCollection

	# ---------------------------------
	# Models

	###*
	# File Model class
	# Extension of the Model class
	# @property {Object} FileModel
	###
	FileModel: FileModel

	###*
	# Document Model class
	# Extension of the File Model class
	# @property {Object} DocumentModel
	###
	DocumentModel: DocumentModel

	# ---------------------------------
	# Collections

	###*
	# Collection of files in a DocPad project
	# Extension of the QueryCollection class
	# @property {Object} FilesCollection
	###
	FilesCollection: FilesCollection

	###*
	# Collection of elements in a DocPad project
	# Extension of the Collection class
	# @property {Object} ElementsCollection
	###
	ElementsCollection: ElementsCollection

	###*
	# Collection of metadata in a DocPad project
	# Extension of the ElementsCollection class
	# @property {Object} MetaCollection
	###
	MetaCollection: MetaCollection

	###*
	# Collection of JS script files in a DocPad project
	# Extension of the ElementsCollection class
	# @property {Object} ScriptsCollection
	###
	ScriptsCollection: ScriptsCollection

	###*
	# Collection of CSS style files in a DocPad project
	# Extension of the ElementsCollection class
	# @property {Object} StylesCollection
	###
	StylesCollection: StylesCollection

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
	# Destructor. Destroy the caterpillar logger instances bound to DocPad
	# @private
	# @method {Object} destroyLoggers
	###
	destroyLoggers: ->
		if @loggerInstances
			for own key,value of @loggerInstances
				value.end()
				@loggerInstances[key] = null
			@loggerInstances = null
		@

	###*
	# All the timers that exist within DocPad
	# Used for closing them at shutdown
	# @private
	# @property {Object} timers
	###
	timers: null

	###*
	# Create a timer and add it to the known timers
	# @method timer
	# @param {string} type - either timeout or interval
	# @param {number} time - the time to apply to the timer
	# @param {method} method - the method to use for the timer
	###
	timer: (id, type, time, method) ->
		@timers ?= {}

		# Create a new timer
		if type?
			@timer(id)  # clear
			if type is 'timeout'
				if time is -1
					timer = setImmediate(method)
				else
					timer = setTimeout(method, time)
			else if type is 'interval'
				timer = setInterval(method, time)
			else
				throw new Errlop('unexpected type on new timer')
			@timers[id] = {id, type, time, method, timer}

		# Destroy an old timer
		else if @timers[id]
			if @timers[id].type is 'interval'
				clearInterval(@timers[id].timer)
			else if @timers[id].type is 'timeout'
				if @timers[id].time is -1
					clearImmediate?(@timers[id].timer)
				else
					clearTimeout(@timers[id].timer)
			else
				throw new Errlop('unexpected type on stored timer')
			@timers[id] = null

		@

	###*
	# Destructor. Destroy all the timers we have kept.
	# @private
	# @method {Object} destroyTimers
	###
	destroyTimers: (timer) ->
		@timers ?= {}

		for own key, value of @timers
			@timer(key)

		@

	###*
	# Instance of progress-title
	# @private
	# @property {Progress} progressInstance
	###
	progressInstance: null

	###*
	# Update the configuration of the progress instance, to either enable it or disable it
	# Progress will be enabled if DocPad config 'progress' is true
	# @private
	# @method updateProgress
	# @param {boolean} [enabled] manually enable or disable the progress bar
	###
	updateProgress: (enabled) ->
		# Prepare
		docpad = @
		config = docpad.getConfig()
		debug = @getDebugging()

		# Enabled
		enabled ?= config.progress

		# If we are in debug mode, then output more detailed title messages
		options = {}
		if debug
			options.verbose = true
			options.interval = 0
			# options.log = true

		# If we wish to have it enabled
		if enabled
			if @progressInstance
				@progressInstance.pause().configure(options).resume()
			else
				@progressInstance = Progress.create(options).start()
		else if @progressInstance
			@progressInstance.stop().configure(options)

		# Return
		return this

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
	action: (action, opts, next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		locale = @getLocale()

		# Log
		@progressInstance?.resume()
		@log 'debug', util.format(locale.actionStart, action)

		# Act
		docpadUtil.action.call @, action, opts, (args...) =>
			# Prepare
			err = args[0]

			# Log
			@progressInstance?.stop()
			if err
				@error(new Errlop(
					util.format(locale.actionFailure, action),
					err
				))
			else
				@log 'debug', util.format(locale.actionSuccess, action)

			# Act
			return next?(args...)

		# Chain
		@

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
		'docpadReady'                  # fired only once
		'docpadDestroy'                # fired once on shutdown
		'consoleSetup'                 # fired once
		'runBefore'
		'runAfter'
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
	# Description for getDatabase
	# @method {Object} getDatabase
	###
	getDatabase: -> @database

	###*
	# Destructor. Destroy the DocPad database
	# @private
	# @method destroyDatabase
	###
	destroyDatabase: ->
		if @database?
			@database.destroy()
			@database = null
		@

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
	# Get a file by its selector (this is used to fetch layouts by their name)
	# @method getFileBySelector
	# @param {Object} selector
	# @param {Object} [opts={}]
	# @return {Object} a file
	###
	getFileBySelector: (selector,opts={}) ->
		opts.collection ?= @getDatabase()
		file = opts.collection.fuzzyFindOne(selector)
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
	corePath: pathUtil.resolve(__dirname, '..', '..')

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
	localePath: pathUtil.resolve(__dirname, 'locale')


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
					err = new Errlop(util.format(locale.includeFailed, subRelativePath))
					throw err

		# Fetch our result template data
		templateData = extendr.extend({}, @initialTemplateData, @pluginsTemplateData, @getConfig().templateData, userTemplateData)

		# Add site data
		templateData.site.url or= ''
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
	getLocale: (key) ->
		unless @locale?
			try
				locales = @getPath('locales').map((locale) -> require(locale))
				@locale = extendr.extend(locales...)
			catch localeError
				docpad.warn(new Errlop('Failed to load a locale', localeError))
				try
					@locale = require(@getPath('locale'))
				catch err
					docpad.fatal(new Errlop('Failed to load any locale', err))
					@locale = {}

		if key
			return @locale[key] or key
		else
			return @locale


	# -----------------------------
	# Environments


	###*
	# Get the DocPad environment, eg: development,
	# production or static
	# @method getEnvironment
	# @return {String} the environment
	###
	getEnvironment: ->
		return @env

	###*
	# Get the environments
	# @method getEnvironments
	# @return {Array} array of environment strings
	###
	getEnvironments: ->
		return @envs


	# -----------------------------
	# Configuration

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
	userConfig: null  # {}

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

		# Whether or not we should use the global docpad instance
		global: false

		# Configuration to pass to any plugins pluginName: pluginConfiguration
		plugins: {}


		# -----------------------------
		# Project Paths

		# The project directory
		rootPath: process.cwd()

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

		# Paths that we should watch for reload changes in
		reloadPaths: []

		# Paths that we should watch for regeneration changes in
		regeneratePaths: []

		# The DocPad debug log path (docpad-debug.log)
		debugLogPath: 'docpad-debug.log'

		# The User's configuration path (.docpad.cson)
		userConfigPath: '.docpad.cson'

		# -----------------------------
		# Project Options

		# The project's out directory
		outPath: 'out'

		# The project's source directory
		sourcePaths: [
			'source'
			'src'
		]

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
		# Logging

		# Log Level
		# Which level of logging should we actually output
		logLevel: 6

		# Verbose
		# Set log level to 7
		verbose: false

		# Debug
		# Output all log messages to the debugLogPath
		debug: false

		# Color
		# Whether or not our terminal output should have color
		# `null` will default to what the terminal supports
		color: docpadUtil.isTTY()

		# Silent
		# Will set the following
		# logLEvel = 3
		# progress = welcome = checkVersion = false
		silent: false

		# Progress
		# Whether or not we should display the progress in the terminal title bar
		progress: true


		# -----------------------------
		# Other

		# Catch our own exceptions (error events on the DocPad instance)
		# use "error"/truthy to report
		# use "fatal" to report and exit
		catchOurExceptions: 'error'

		# Catch any uncaught exception
		# use "error" to report
		# use "fatal"/truthy to report and exit
		catchUncaughtExceptions: 'fatal'

		# Whether or not DocPad is allowed to set the exit code on fatal errors
		# May only work on node v0.11.8 and above
		setExitCodeOnFatal: true

		# Whether or not DocPad is allowed to set the exit code on standard errors
		# May only work on node v0.11.8 and above
		setExitCodeOnError: true

		# Whether or not DocPad is allowed to set the exit code when some code has requested to
		# May only work on node v0.11.8 and above
		setExitCodeOnRequest: true

		# The time to wait before cancelling a request
		requestTimeout: 30*1000

		# The time to wait when destroying DocPad
		destroyDelay: -1

		# Whether or not to destroy on exit
		destroyOnExit: true

		# Whether or not to destroy on signal interrupt (ctrl+c)
		destroyOnSignalInterrupt: true

		# The time to wait after a source file has changed before using it to regenerate
		regenerateDelay: 100

		# The time to wait before outputting the files we are waiting on
		slowFilesDelay: 20*1000

		# The time to wait before outputting the plugins we are waiting on
		slowPluginsDelay: 20*1000

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
		# - fetching skeletons
		offline: false

		# Check Version
		# Whether or not to check for newer versions of DocPad
		checkVersion: false

		# Powered By DocPad
		# Whether or not we should include DocPad in the Powered-By meta header
		# Please leave this enabled as it is a standard practice and promotes DocPad in the web eco-system
		poweredByDocPad: true

		# Helper Url
		# Helper's source-code can be found at: https://github.com/docpad/helper
		helperUrl: if true then 'http://helper.docpad.org/' else 'http://localhost:8000/'

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
				# Only do these if we are running standalone (aka not included in a module)
				checkVersion: isUser
				welcome: isUser
				progress: isUser

	###*
	# Get the DocPad configuration
	# @method getConfig
	# @return {Object} the DocPad configuration object
	###
	getConfig: ->
		return @config or {}


	# =================================
	# Initialization Functions

	###*
	# Create our own custom TaskGroup instance for DocPad.
	# That will listen to tasks as they execute and provide debugging information.
	# @method createTaskGroup
	# @param {Object} opts
	# @return {TaskGroup}
	###
	createTaskGroup: (opts...) =>
		docpad = @
		progress = docpad.progressInstance
		tasks = TaskGroup.create(opts...)

		# Listen to executing tasks and output their progress
		tasks.on 'running', ->
			config = tasks.getConfig()
			name = tasks.getNames()
			if progress
				totals = tasks.getItemTotals()
				progress.update(name, totals)
			else
				docpad.log('debug', name+' > running')

		# Listen to executing tasks and output their progress
		tasks.on 'item.add', (item) ->
			config = tasks.getConfig()
			name = item.getNames()
			unless progress
				docpad.log('debug', name+' > added')

			# Listen to executing tasks and output their progress
			item.on 'started', (item) ->
				config = tasks.getConfig()
				name = item.getNames()
				if progress
					totals = tasks.getItemTotals()
					progress.update(name, totals)
				else
					docpad.log('debug', name+' > started')

			# Listen to executing tasks and output their progress
			item.done (err) ->
				config = tasks.getConfig()
				name = item.getNames()
				if progress
					totals = tasks.getItemTotals()
					progress.update(name, totals)
				else
					docpad.log('debug', name+' > done')

		# Return
		return tasks

	###*
	# Constructor method. Sets up the DocPad instance.
	# next(err)
	# @method constructor
	# @param {Object} instanceConfig
	# @param {Function} next callback
	# @param {Error} next.err
	# @param {DocPad} next.docpad
	###
	constructor: (instanceConfig,next) ->
		# Prepare
		super()
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig, next)
		docpad = @

		# Allow DocPad to have unlimited event listeners
		@setMaxListeners(0)

		# Binders
		# Using this over coffescript's => on class methods, ensures that the method length is kept
		for methodName in "action log warn error fatal inspect notify checkRequest activeHandles onBeforeExit onSignalInterruptOne onSignalInterruptTwo onSignalInterruptThree destroyWatchers".split(/\s+/)
			@[methodName] = @[methodName].bind(@)

		# Adjust configPaths
		if typeChecker.isString(instanceConfig.configPaths)
			instanceConfig.configPaths = [instanceConfig.configPaths]

		# Dereference and initialise advanced variables
		# we deliberately ommit initialTemplateData here, as it is setup in getTemplateData
		@slowPlugins = {}
		@loadedPlugins = {}
		@exchange = {}
		@pluginsTemplateData = {}
		@collections = []
		@blocks = {}
		@websitePackageConfig = {}
		@websiteConfig = {}
		@userConfig = {}
		@initialConfig = extendr.dereferenceJSON(@initialConfig)
		@instanceConfig = instanceConfig or {}
		@config = @mergeConfigs()

		# Create and apply the loggers
		@loggerInstances = {}
		@loggerInstances.logger = require('caterpillar').create(lineOffset: 2)
		@loggerInstances.console = @loggerInstances.logger
				.pipe(
					require('caterpillar-filter').create()
				)
				.pipe(
					require('caterpillar-human').create(color: @config.color)
				)

		# Create the debug logger
		if instanceConfig.debug
			logPath = @getPath(false, 'log')
			safefs.unlink logPath, =>
				@loggerInstances.debug = @loggerInstances.logger
					.pipe(
						require('caterpillar-human').create(color: false)
					)
					.pipe(
						require('fs').createWriteStream(logPath)
					)

		# Start logging
		@loggerInstances.console.pipe(process.stdout)

		# Forward log events to the logger
		@on 'log', (args...) ->
			docpad.log.apply(@, args)

		# Setup configuration event wrappers
		configEventContext = {docpad}  # here to allow the config event context to persist between event calls
		@getEvents().forEach (eventName) ->
			# Bind to the event
			docpad.on eventName, (opts,next) ->
				eventHandler = docpad.getConfig().events?[eventName]

				# Fire the config event handler for this event, if it exists
				if typeChecker.isFunction(eventHandler)
					args = [opts,next]
					ambi(unbounded.binder.call(eventHandler, configEventContext), args...)

				# It doesn't exist, so lets continue
				else
					next()

		# Create our action runner
		@actionRunnerInstance = @createTaskGroup('action runner', {abortOnError: false, destroyOnceDone: false}).whenDone (err) ->
			docpad.progressInstance?.update('')
			docpad.error(err)  if err

		# Setup the database
		@database = new FilesCollection(null, {name:'database'})
			.on('remove', (model,options) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
				outPath = model.get('outPath')
				if outPath
					updatedModels = docpad.database.findAll({outPath})
					updatedModels.remove(model)
					if updatedModels.length
						updatedModels.each (model) ->
							model.set('mtime': new Date())
						docpad.log('info', 'Updated mtime for these models due to the removal of a similar one:', updatedModels.pluck('relativePath'))

				# Return safely
				return true
			)
			.on('add change:outPath', (model) ->
				# Skip if we are not a writeable file
				return  if model.get('write') is false

				# Prepare
				outPath = model.get('outPath')
				previousOutPath = model.previous('outPath')

				# Check if we have changed our outPath
				if previousOutPath
					# Ensure we regenerate anything (on the next regeneration) that was using the same outPath
					previousModels = docpad.database.findAll({outPath: previousOutPath})
					previousModels.remove(model)
					if previousModels.length
						previousModels.each (previousModel) ->
							previousModel.set('mtime': new Date())
						docpad.log('info', 'Updated mtime for these models due to the addition of a similar one:', previousModels.pluck('relativePath'))

				# Determine if there are any conflicts with the new outPath
				if outPath
					existingModels = docpad.database.findAll({outPath})
					existingModels.each (existingModel) ->
						if existingModel.id isnt model.id
							modelPath = model.get('fullPath') or (model.get('relativePath')+':'+model.id)
							existingModelPath = existingModel.get('fullPath') or (existingModel.get('relativePath')+':'+existingModel.id)
							docpad.warn util.format(docpad.getLocale().outPathConflict, outPath, modelPath, existingModelPath)

				# Return safely
				return true
			)

		# Continue with load and ready
		@action 'load ready', {}, (err) ->
			if next?
				next(err, docpad)
			else if err
				docpad.fatal(err)

		# Chain
		@

	###*
	# Has DocPad commenced destruction?
	###
	destroying: false

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
		return @  if @destroying
		@destroying = true

		# Prepare
		[opts,next] = extractOptsAndCallback(opts, next)
		docpad = @
		config = @getConfig()
		locale = @getLocale()

		# Log
		docpad.log('info', locale.destroyDocPad)

		# Drop all the remaining tasks
		dropped = @getActionRunner().clearRemaining()
		docpad.error("DocPad destruction had to drop #{Number(dropped)} action tasks")  if dropped

		# Destroy Timers
		docpad.destroyTimers()

		# Wait a configurable oment
		docpad.timer 'destroy', 'timeout', config.destroyDelay, ->

			# Destroy Plugins
			docpad.emitSerial 'docpadDestroy', (eventError) ->
				# Check
				if eventError
					# Note
					err = new Errlop(
						"DocPad's destroyEvent event failed",
						eventError
					)
					docpad.fatal(err)

					# Callback
					return next?(err)

				# Final closures and checks
				try
					# Destroy Timers
					docpad.destroyTimers()

					# Destroy Plugins
					docpad.destroyPlugins()

					# Destroy Watchers
					docpad.destroyWatchers()

					# Destroy Blocks
					docpad.destroyBlocks()

					# Destroy Collections
					docpad.destroyCollections()

					# Destroy Database
					docpad.destroyDatabase()

					# Destroy progress
					docpad.updateProgress(false)

					# Destroy Logging
					docpad.destroyLoggers()

					# Destroy Process Listeners
					process.removeListener('uncaughtException', docpad.fatal)
					process.removeListener('uncaughtException', docpad.error)
					process.removeListener('beforeExit', docpad.onBeforeExit)
					process.removeListener('SIGINT', docpad.onSignalInterruptOne)
					process.removeListener('SIGINT', docpad.onSignalInterruptTwo)
					process.removeListener('SIGINT', docpad.onSignalInterruptThree)

					# Destroy DocPad Listeners
					docpad.removeAllListeners()

				catch finalError
					# Note
					err = new Errlop(
						"DocPad's final destruction efforts failed",
						finalError
					)
					docpad.fatal(err)
					return next?(err)

				# Success
				docpad.log(locale.destroyedDocPad)  # log level omitted, as this will hit console.log
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
	# @private
	# @method watchdir
	# @param {String} path - the path to watch
	# @param {Object} listeners - listeners to attach to the watcher
	# @param {Function} next - completion callback accepting error
	# @return {Object} the watcher
	###
	watchdir: (path, listeners, next) ->
		opts = extendr.extend(@getIgnoreOpts(), @config.watchOptions or {})
		stalker = require('watchr').create(path)
		for own key, value of listeners
			stalker.on(key, value)
		stalker.setConfig(opts)
		stalker.watch(next)
		return stalker

	###*
	# Watch Directories. Wrapper around watchdir.
	# @private
	# @method watchdirs
	# @param {Array} paths - the paths to watch
	# @param {Object} listeners - listeners to attach to the watcher
	# @param {Function} next - completion callback accepting error and watchers/stalkers
	###
	watchdirs: (paths, listeners, next) ->
		docpad = @
		stalkers = []

		tasks = new TaskGroup('watching directories').setConfig(concurrency:0).done (err) ->
			if err
				for stalker in stalkers
					stalker.close()
				next(err)
			else
				next(err, stalkers)

		paths.forEach (path) ->
			tasks.addTask "watching #{path}", (done) ->
				# check if the dir exists first as reloadPaths may not apparently
				safefs.exists path, (exists) ->
					return done()  unless exists
					stalkers.push docpad.watchdir(path, listeners, done)

		tasks.run()

		# Chain
		@


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

		# Fetch the plugins
		pluginsList = Object.keys(@loadedPlugins).sort().join(', ')

		# Welcome Output
		docpad.log 'info', util.format(locale.welcome, @getVersionString())
		docpad.log 'notice', locale.welcomeDonate
		docpad.log 'info', locale.welcomeContribute
		docpad.log 'info', util.format(locale.welcomePlugins, pluginsList)
		docpad.log 'info', util.format(locale.welcomeEnvironment, @getEnvironment())

		# Prepare
		tasks = @createTaskGroup('ready tasks').done (err) ->
			# Error?
			return docpad.error(err)  if err

			# All done, forward our DocPad instance onto our creator
			return next?(null,docpad)

		# kept here in case plugins use it
		tasks.addTask 'welcome event', (complete) ->
			# No welcome
			return complete()  unless config.welcome

			# Welcome
			docpad.emitSerial('welcome', {docpad}, complete)

		tasks.addTask 'emit docpadReady', (complete) ->
			docpad.emitSerial('docpadReady', {docpad}, complete)

		# Run tasks
		tasks.run()

		# Chain
		@

	###*
	# Performs the merging of the passed configuration objects
	# @private
	# @method mergeConfigs
	###
	mergeConfigs: (configPackages, destination = {}) ->
		# A plugin is calling us with its configuration
		unless configPackages
			# Apply the environment
			# websitePackageConfig.env is left out of the detection here as it is usually an object
			# that is already merged with our process.env by the environment runner
			# rather than a string which is the docpad convention
			@env = (
				@instanceConfig.env or @websiteConfig.env or @initialConfig.env or process.env.NODE_ENV or 'development'
			)
			@envs = @env.split(/[, ]+/)

			# Merge the configurations together
			configPackages = [@initialConfig, @userConfig, @websiteConfig, @instanceConfig]

		# Figure out merging
		configsToMerge = [destination]
		for configPackage in configPackages
			continue  unless configPackage
			configsToMerge.push(configPackage)
			for env in @envs
				envConfig = configPackage.environments?[env]
				configsToMerge.push(envConfig)  if envConfig

		# Merge
		return extendr.deep(configsToMerge...)

	###*
	# Legacy version of mergeConmergeConfigsfigurations
	# @private
	# @method mergeConfigurations
	###
	mergeConfigurations: (configPackages, [destination]) ->
		return @mergeConfigs(configPackages, destination)

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
	setConfig: (instanceConfig) ->
		# Prepare
		[instanceConfig,next] = extractOptsAndCallback(instanceConfig,next)
		docpad = @
		locale = @getLocale()

		# Apply the instance configuration, generally we won't have it at this level
		# as it would have been applied earlier the load step
		extendr.deepDefaults(@instanceConfig, instanceConfig)  if instanceConfig

		# Merge the configurations together
		@config = @mergeConfigs()

		# Shorthands
		if @config.offline
			@config.checkVersion = false
		if @config.silent
			@config.logLevel = 3 # 3:error, 2:critical, 1:alert, 0:emergency
			@config.progress = @config.welcome = @config.checkVersion = false
		if @config.verbose
			@config.logLevel = 7

		# Apply the log level
		@setLogLevel(@config.logLevel)

		# Update the progress bar configuration
		@updateProgress()

		# Legacy to ensure srcPath customisation works, as well as srcPath fetcing works
		if @config.srcPath and @config.sourcePaths.includes(@config.srcPath) is false
			@config.srcPath = @getPath('root', @config.srcPath)
			@config.sourcePaths.push(@config.srcPath)
		else
			@config.srcPath = @getPath('source')

		# Handle errors
		process.removeListener('uncaughtException', @fatal)
		process.removeListener('uncaughtException', @error)
		@removeListener('error', @fatal)
		@removeListener('error', @error)
		if @config.catchExceptions # legacy
			@config.catchOurExceptions = @config.catchUncaughtExceptions = 'error'
		if @config.catchUncaughtExceptions
			process.setMaxListeners(0)
			if @config.catchUncaughtExceptions is 'error'
				process.on('uncaughtException', @error)
			else
				process.on('uncaughtException', @fatal)
		if @config.catchOurExceptions
			if @config.catchUncaughtExceptions is 'fatal'
				@on('error', @fatal)
			else
				@on('error', @error)

		# Handle interrupt
		process.removeListener('beforeExit', @onBeforeExit)
		process.removeListener('SIGINT', @onSignalInterruptOne)
		process.removeListener('SIGINT', @onSignalInterruptTwo)
		process.removeListener('SIGINT', @onSignalInterruptThree)
		if @config.destroyOnExit
			process.once('beforeExit', @onBeforeExit)
		if @config.destroyOnSignalInterrupt
			process.once('SIGINT', @onSignalInterruptOne)

		# Chain
		@

	onSignalInterruptOne: ->
		# Log
		@log('notice', "Signal Interrupt received, queued DocPad's destruction")

		# Escalate next time
		process.once('SIGINT', @onSignalInterruptTwo)

		# Act
		@action('destroy')

		# Chain
		@

	onSignalInterruptTwo: ->
		# Log
		@log('alert', 'Signal Interrupt received again, closing stdin and dumping handles')

		# Escalate next time
		process.once('SIGINT', @onSignalInterruptThree)

		# Handle any errors that occur when stdin is closed
		# https://github.com/docpad/docpad/pull/1049
		process.stdin?.once? 'error', (stdinError) ->
			# ignore ENOTCONN as it means stdin was already closed when we called stdin.end
			# node v8 and above have stdin.destroy to avoid emitting this error
			if stdinError.toString().indexOf('ENOTCONN') is -1
				err = new Errlop(
					"closing stdin encountered an error",
					stdinError
				)
				docpad.fatal(err)

		# Close stdin
		# https://github.com/docpad/docpad/issues/1028
		# https://github.com/docpad/docpad/pull/1029
		process.stdin?.destroy?() or process.stdin?.end?()

		# Wait a moment before outputting things that are preventing closure
		setImmediate(@activeHandles)

		# Chain
		@

	onSignalInterruptThree: ->
		# Log
		@log('alert', 'Signal Interrupt received yet again, skipping queue and destroying DocPad right now')

		# Act
		@exitCode(130)
		@destroy()

		# Chain
		@

	onBeforeExit: ->
		@action('destroy')

	activeHandles: ->
		# Note any requests that are still active
		activeRequests = process._getActiveRequests?()
		if activeRequests?.length
			docpadUtil.writeStderr """
				Waiting on these #{activeRequests.length} requests to close:
				#{@inspect activeRequests}
				"""

		# Note any handles that are still active
		activeHandles = process._getActiveHandles?()
		if activeHandles?.length
			docpadUtil.writeStderr """
				Waiting on these #{activeHandles.length} handles to close:
				#{@inspect activeHandles}
				"""

	###*
	# Load the various configuration files from the
	# file system. Set the instanceConfig.
	# next(err,config)
	# @private
	# @method load
	# @param {Object} opts
	# @param {Function} next
	# @param {Error} next.err
	###
	load: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		docpad = @
		locale = @getLocale()
		config = @getConfig()

		# Prepare the Load Tasks
		loadTasks = @createTaskGroup('load tasks').done(next)

		# User Configuration
		loadTasks.addTask "load the user's configuration", (complete) =>
			userConfigPath = @getPath('user')
			return complete()  unless userConfigPath
			docpad.log 'debug', util.format(locale.loadingUserConfig, userConfigPath)
			@loadConfigPath userConfigPath, (err,data) =>
				return complete(err)  if err

				# Apply
				if data
					@userConfig = data
					docpad.log 'debug', util.format(locale.loadedUserConfig, userConfigPath)
					return complete()

				# Complete
				return complete()

		# Website Env Configuration
		loadTasks.addTask "read the .env file if it exists", (complete) =>
			envPath = @getPath('env')
			return complete()  unless envPath
			docpad.log 'debug', util.format(locale.loadingEnvConfig, envPath)
			envFile.parseFile envPath, (err,data) ->
				return complete(err)  if err
				for own key,value of data
					process.env[key] = value
				docpad.log 'debug', util.format(locale.loadedEnvConfig, envPath)
				return complete()

		# Website Package Configuration
		loadTasks.addTask "load the website's package data", (complete) =>
			packagePath = @getPath('package')
			return complete()  unless packagePath
			docpad.log 'debug', util.format(locale.loadingWebsitePackageConfig, packagePath)
			@loadConfigPath packagePath, (err,data) =>
				return complete(err)  if err

				# Apply
				if data
					@websitePackageConfig = data
					docpad.log 'debug', util.format(locale.loadedWebsitePackageConfig, packagePath)

				# Complete
				return complete()

		# Website Configuration
		loadTasks.addTask "load the website's configuration", (complete) =>
			configPath = @getPath('config')
			return complete()  unless configPath
			docpad.log 'debug', util.format(locale.loadingWebsiteConfig, configPath)
			@loadConfigPath configPath, (err,data) =>
				return complete(err)  if err

				# Apply
				if data
					@websiteConfig = data
					docpad.log 'debug', util.format(locale.loadedWebsiteConfig, configPath)

				# Complete
				return complete()

		loadTasks.addTask "update the configurations", =>
			@setConfig()

		###
		loadTasks.addTask 'lazy dependencies: encoding', (complete) =>
			lazyRequire = require('lazy-require')
			return complete()  unless @config.detectEncoding
			return lazyRequire 'encoding', {cwd:corePath, stdio:'inherit'}, (err) ->
				docpad.warn(locale.encodingLoadFailed)  if err
				return complete()
		###

		loadTasks.addTask 'load plugins', (complete) ->
			docpad.loadPlugins(complete)

		loadTasks.addTask 'extend collections', (complete) ->
			docpad.extendCollections(complete)

		loadTasks.addTask 'fetch plugins templateData', (complete) ->
			docpad.emitSerial('extendTemplateData', {templateData:docpad.pluginsTemplateData}, complete)

		# Fire post tasks
		loadTasks.run()

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
		userConfigPath = @getConfig(false, 'user')

		# Apply back to our loaded configuration
		# does not apply to @config as we would have to reparse everything
		# and that appears to be an imaginary problem
		extendr.extend(@userConfig, data)  if data

		# Convert to CSON
		CSON.createCSONString @userConfig, (parseError, userConfigString) ->
			if parseError
				err = new Errlop(
					"Failed to create the CSON string for the user configuration",
					parseError
				)
				return next(err)

			# Write it
			safefs.writeFile userConfigPath, userConfigString, 'utf8', (writeError) ->
				if writeError
					err = new Errlop(
						"Failed to write the CSON string for the user configuration to #{userConfigPath}",
						writeError
					)
					return next(err)

				# Forward
				return next()

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
		config = @getConfig()

		# Log
		docpad.log 'debug', util.format(locale.loadingConfigUrl, configUrl)

		# Read the URL
		fetch(configUrl, {timeout: config.requestTimeout})
			.then((res) -> res.text())
			.then((text) -> CSON.parseCSONString(text))
			.catch(next)
			.then((data) -> next(null, data))

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
	loadConfigPath: (configPath,next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Check
		return next()  unless configPath

		# Log
		docpad.log 'debug', util.format(locale.loadingConfigPath, configPath)

		# Prepare CSON Options
		csonOptions =
			cson: true
			json: true
			coffeescript: true
			javascript: true

		# Read the path using CSON
		CSON.requireFile configPath, csonOptions, (parseError, data) ->
			if parseError
				err = new Errlop(
					util.format(locale.loadingConfigPathFailed, configPath),
					parseError
				)
				return next(err)

			# Check if the data is a function, if so, then execute it as one
			while typeChecker.isFunction(data)
				try
					data = data(docpad)
				catch executeError
					err = new Errlop(
						util.format(locale.executeConfigPathFailed, configPath),
						executeError
					)
					return next(err)
			unless typeChecker.isObject(data)
				err = new Errlop(
					util.format(locale.invalidConfigPathData, configPath, docpad.inspect(data))
				)
				return next(err)

			# Return the data
			return next(null, data)

		# Chain
		@

	resolvePath: (args...) ->
		path = pathUtil.resolve(args...)
		return path  if safefs.existsSync(path)
		return false

	getPath: (args...) ->
		# Use join if first argument is false
		if typeChecker.isBoolean(args[0])
			[check, name, tail...] = args
		else
			check = true
			[name, tail...] = args

		# Prepare
		method = if check then @resolvePath else pathUtil.resolve
		config = @getConfig()

		# Determine
		path = switch name
			when 'locales' then [pathUtil.resolve(@localePath, 'en.js')] ###
				uniq([
					safeps.getLocaleCode   config.localeCode
					safeps.getLocaleCode   safeps.getLocaleCode()
					safeps.getLanguageCode config.localeCode
					safeps.getLanguageCode safeps.getLocaleCode()
					'en'
				]).map((code) => @resolvePath(@localePath, code + '.js'))
				###
			when 'locale' then @getPath(check, 'locales')[0]
			when 'root' then method(check, config.rootPath)
			when 'log' then method(check, process.cwd(), config.debugLogPath)
			when 'out' then @getPath(check, 'root', config.outPath)
			when 'env' then @getPath(check, 'root', '.env')
			when 'home' then require('os').homedir()  # works in node v4 and above
			when 'dropbox' then @getPath(check, 'home', 'Dropbox')
			when 'users' then [@getPath(check, 'dropbox', config.userConfigPath), @getPath(check, 'root', config.userConfigPath)].filter(Boolean)
			when 'user' then @getPath(check, 'users')[0]
			when 'package' then @getPath(check, 'root', config.packagePath)
			when 'sources' then config.sourcePaths.map((path) => @getPath(check, 'root', path)).filter(Boolean)
			when 'source' then @getPath(check, 'sources')[0]
			when 'configs' then config.configPaths.map((path) => @getPath(check, 'root', path)).filter(Boolean)
			when 'config' then @getPath(check, 'configs')[0]
			when 'documents' then config.documentsPaths.map((path) => @getPath(check, 'source', path)).filter(Boolean)
			when 'document' then @getPath(check, 'documents')[0]
			when 'files' then config.filesPaths.map((path) => @getPath(check, 'source', path)).filter(Boolean)
			when 'file' then @getPath(check, 'files')[0]
			when 'layouts' then config.layoutsPaths.map((path) => @getPath(check, 'source', path)).filter(Boolean)
			when 'layout' then @getPath(check, 'layouts')[0]
			when 'reloads' then config.reloadPaths.map((path) => @getPath(check, 'source', path)).filter(Boolean)
			when 'regenerates' then config.regeneratePaths.map((path) => @getPath(check, 'source', path)).filter(Boolean)
			else null

		result = if typeof path is 'string' and tail.length
			method(check, path, tail...)
		else
			path

		return result

	###*
	# Extend collections. Create DocPad's
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
						fullPath: $startsWith: @getPath('layouts')
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
					ignored: false
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingGenerate, model.getFilePath()))
				)
			referencesOthers: database.createLiveChildCollection()
				.setQuery('referencesOthers', {
					ignored: false
					referencesOthers: true
				})
				.on('add', (model) ->
					docpad.log('debug', util.format(locale.addingReferencesOthers, model.getFilePath()))
				)
			hasLayout: database.createLiveChildCollection()
				.setQuery('hasLayout', {
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
		tasks = @createTaskGroup("extendCollections tasks", concurrency:0).done (err) ->
			docpad.error(err)  if err
			docpad.emitSerial('extendCollections', next)

		# Cycle through Custom Collections
		eachr docpadConfig.collections or {}, (fn,name) ->
			if !name or !typeChecker.isString(name)
				err = new Errlop("Inside your DocPad configuration you have a custom collection with an invalid name of: #{docpad.inspect name}")
				docpad.error(err)
				return

			if !fn or !typeChecker.isFunction(fn)
				err = new Errlop("Inside your DocPad configuration you have a custom collection called #{docpad.inspect name} with an invalid method of: #{docpad.inspect fn}")
				docpad.error(err)
				return

			tasks.addTask "creating the custom collection: #{name}", (complete) ->
				# Init
				ambi unbounded.binder.call(fn, docpad), database, (err, collection) ->
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
		opts.stdio = 'inherit'
		opts.cwd ?= @getPath('root')

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
		opts.stdio = 'inherit'
		opts.cwd ?= @getPath('root')
		opts.args ?= []

		# Command
		command = ['npm', 'install']
		command.push(opts.args...)
		command.push('--no-registry')  if config.offline

		# Log
		docpad.log('info', command.join(' '))

		# Forward
		safeps.spawn(command, opts, next)

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
		opts.packagePath ?= @getPath('package')

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
		opts.stdio = 'inherit'
		opts.cwd ?= @getPath('root')
		opts.args ?= []
		opts.save = []  if opts.global
		opts.save = ['--save']   if opts.save is true
		opts.save = [opts.save]  if opts.save and Array.isArray(opts.save) is false

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
		command.push('--no-registry')  if config.Offline
		command.push(opts.save...)     if opts.save and opts.save.length
		command.push('--global')       if opts.global

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
		opts.stdio = 'inherit'
		opts.cwd ?= @getPath('root')
		opts.args ?= []
		opts.save = ['--save', '--save-dev']   if opts.save is true
		opts.save = [opts.save]                if opts.save and Array.isArray(opts.save) is false

		# Command
		command = ['npm', 'uninstall']

		# Names
		names = names.split(/[,\s]+/)  unless typeChecker.isArray(names)
		command.push(names...)

		# Arguments
		command.push(opts.args...)
		command.push(opts.save...)  if opts.save

		# Log
		docpad.log('info', command.join(' '))

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
		level = 7  if level is true
		@getLogger().setConfig({level})
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
		config = @getConfig()
		return config.logLevel is 7 or config.debug

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
				err = new Errlop(res.body.error or 'unknown request error')
				return next(err, res)

			# Success
			return next(null, res)

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
	# Inspect. Converts object to JSON string. Wrapper around nodes util.inspect method.
	# Can't use the inspect namespace as for some silly reason it destroys everything
	# @method inspect
	# @param {Object} obj
	# @param {Object} opts
	# @return {String} JSON string of passed object
	###
	inspect: (obj, opts) ->
		opts ?= {}
		opts.colors ?= @getConfig().color
		return util.inspect(obj, opts)

	###*
	# Log arguments to
	# @property {Object} log
	# @param {Mixed} args...
	###
	log: (args...) ->
		# Log
		logger = @getLogger()
		if logger?.log?
			logger.log.apply(logger, args)
		else
			# logger doesn't exist, this is probably because it was destroyed
			# so handle the most basic case ourselves
			# that case being when the first argument is a log level string
			# as we don't want to interpret log(new Date().getTime()) as a log level number
			# @todo
			# ideally, this logic would be static methods inside caterpillar
			# as caterpillar methods is already where this logic exist, they just have to be made static
			logLevels = require('rfc-log-levels')
			logLevel = logLevels[args[0]] ? 6
			if @getLogLevel() >= logLevel
				console.log(args...)

		# Chain
		@

	###*
	# Create an error and log it
	# This is called by all sorts of things, including docpad.warn
	# As such, the err.level is important
	# @method error
	# @param {*} value
	# @return {Error}
	###
	error: (value) ->
		# Prepare
		locale = @getLocale()

		# Ensure it is an error
		err = Errlop.ensure(value)
		err.level ?= 'error'
		err.log ?= true
		err.logged ?= false
		err.notify ?= true
		err.notified ?= false
		err.report ?= err.level isnt 'warn'

		# Set the exit code
		@exitCode(err)

		# Log the error
		if err.log isnt false and err.logged isnt true
			err.logged = true
			@log(
				err.logLevel or err.level, err.stack + (err.report and ('\n' + locale.errorSubmission) or '')
			)

		# Notify the error
		if err.notify isnt false and err.notified isnt true
			err.notified = true
			title = locale[err.level + 'Occured'] or locale.errorOccured
			@notify(err.message, {title})

		# Return the result error
		return err

	###*
	# Log an error of level 'warn'
	# @method warn
	# @param {*} value
	# @return {Error}
	###
	warn: (value) ->
		err = Errlop.ensure(value)
		err.level ?= 'warn'

		# Foward
		return @error(err)

	###*
	# Handle a fatal error
	# @private
	# @method fatal
	# @param {*} value
	# @param {Function} [next]
	# @return {Error}
	###
	fatal: (value, next) ->
		# Check
		return @  unless value

		# Enforce errlop with fatal level
		err = new Errlop('A fatal error occured within DocPad', value)
		err.level = 'fatal'
		err.logLevel = 'critical'

		# Handle
		@error(err)

		# Set the exit code if we are allowed to
		@exitCode(err)

		# Destroy DocPad
		@destroy({}, next)

		# Return the error
		return err

	###*
	# Sets the exit code if we are allowed to, and if it hasn't already been set
	# @method exitCode
	# @param {number|Error [input]
	# @return {number}
	###
	exitCode: (input) ->
		# Determine if necessary
		unless process.exitCode
			# Prepare
			{setExitCodeOnRequest, setExitCodeOnError, setExitCodeOnFatal} = @getConfig()

			# Number
			if typeChecker.isNumber(input)
				code = input
				level = null

			# Error
			else if input instanceof Error
				code = input.exitCode
				level = input.level or null
				error = input

			# Defaults
			if !code or isNaN(Number(code))
				exitCode = 1
			else
				exitCode = code

			# Determine desire
			because = (
				(!level and setExitCodeOnRequest and 'requested') or
				(level is 'fatal' and setExitCodeOnFatal and 'fatal') or
				(level is 'error' and setExitCodeOnFatal and 'error')
			)
			if because
				# Fetch before we apply so we can log it shortly
				originalExitCode = process.exitCode or 'unset'

				# Apply
				process.exitCode = exitCode

				# And log it
				message = ['Set the exit code from', originalExitCode, 'to', exitCode, 'because of', because]
				message.push('from:', error.message)  if error and error.message
				@log('note', message...)

		# Return the application
		return process.exitCode


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
	parseFileDirectory: (opts,next) ->
		[opts,next] = extractOptsAndCallback(opts, next)
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
	parseDocumentDirectory: (opts,next) ->
		[opts,next] = extractOptsAndCallback(opts, next)
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
				model.on 'getLayout', (opts,next) ->
					opts.collection = docpad.getCollection('layouts')
					layout = docpad.getFileBySelector(opts.selector, opts)
					next(null, {layout})

			# Remove
			#model.on 'remove', (file) ->
			#	docpad.getDatabase().remove(file)
			# ^ Commented out as for some reason this stops layouts from working

			# Error
			model.on 'error', (args...) ->
				docpad.emit('error', args...)

			# Log
			model.on 'log', (args...) ->
				# .error and .warn only accept one argument
				# so only forward to them if args length is 2
				if args.length is 2
					if args[0] in ['err', 'error']
						docpad.error(args[1])
						return

					if args[0] in ['warn', 'warning']
						docpad.warn(args[1])
						return

				# otherwise forward to log
				docpad.log(args...)
				return

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
				for dirPath in @getPath('documents').concat(@getPath('layouts'))
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'document'
						break

			# Check if we have a file
			unless opts.modelType
				for dirPath in @getPath('files')
					if fileFullPath.indexOf(dirPath) is 0
						attrs.relativePath or= fileFullPath.replace(dirPath, '').replace(/^[\/\\]/,'')
						opts.modelType = 'file'
						break

		# -----------------------------
		# Create the appropriate emodel

		# Extend the opts with things we need
		opts = extendr.extend({
			detectEncoding: config.detectEncoding
			rootOutDirPath: @getPath(false, 'out')
			locale: @getLocale()
			createTaskGroup: @createTaskGroup  # @TODO this a bit dodgy, but works well enough
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
	parseDirectory: (opts,next) ->
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

			# Tasks
			tasks = new TaskGroup('parse directory').setConfig(concurrency:0).done (err) ->
				# Check
				return next(err)  if err

				# Log
				docpad.log 'debug', util.format(locale.renderDirectoryParsed, path)

				# Forward
				return next(null, files)

			# Files
			docpad.scandir(
				# Path
				path: path

				# File Action
				fileAction: (fileFullPath, fileRelativePath, filename, fileStat) ->
					# Prepare
					data =
						fullPath: fileFullPath
						relativePath: fileRelativePath
						stat: fileStat

					# Create file
					file = createFunction.call(docpad, data, opts)

					# Create a task to load the file
					tasks.addTask "load the file #{fileRelativePath}", (complete) ->
						# Update the file's stat
						# To ensure changes files are handled correctly in generation
						file.action 'load', (err) ->
							# Error?
							return complete(err)  if err

							# Add the file to the collection
							files.add(file)

							# Next
							complete()

					# Return
					return

				# Next
				next: (err) ->
					return next(err)  if err
					tasks.run()
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
		config = @getConfig()
		locale = @getLocale()

		# Track the slow plugins
		@slowPlugins = {}
		@timer 'slowplugins', 'interval', config.slowPluginsDelay, ->
			docpad.log 'notice', util.format(locale.pluginsSlow, Object.keys(docpad.slowPlugins).join(', '))

		# Async
		tasks = @createTaskGroup("loadPlugins tasks", concurrency:0).done (err) ->
			docpad.timer('slowplugins')
			docpad.slowPlugins = {}
			return next(err)

		# Load the plugins
		plugins = new Set(
			Object.keys(docpad.websitePackageConfig.dependencies or {}).concat(
				Object.keys(docpad.websitePackageConfig.devDependencies or {})
			)
			.filter((name) -> name.startsWith('docpad-plugin-'))
			.concat(config.pluginPaths or [])
			.map((name) -> docpad.getPath('root', 'node_modules', name))
		)
		plugins.forEach (pluginPath) ->
			tasks.addTask "load the plugin at: #{pluginPath}", (complete) ->
				docpad.loadPlugin({pluginPath}, complete)

		# Execute the loading asynchronously
		tasks.run()

		# Chain
		@

	###*
	# Load a plugin from its full file path
	# _next(err)
	# @private
	# @method loadPlugin
	# @param {Object} opts
	# @param {Function} _next
	# @param {Error} _next.err
	###
	loadPlugin: (opts = {}, _next) ->
		# Prepare
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		next = (err) ->
			# Remove from slow plugins
			delete docpad.slowPlugins[pluginName]  if pluginName
			# Forward
			_next(err)
			# Chain
			return docpad

		# Default opts
		opts.keyword ?= 'docpad-plugin'
		opts.prefix ?= 'docpad-plugin-'
		opts.BasePlugin ?= BasePlugin
		opts.log ?= @log

		# Load and validate the plugin
		try
			loader = new PluginLoader(opts)
		catch unsupportedError
			docpad.warn(new Errlop(
				util.format(locale.pluginUnsupported, opts.pluginPath),
				unsupportedError
			))
			return next()

		# Prepare
		pluginName = loader.pluginName
		enabled = config.plugins[pluginName] isnt false

		# If we've already been loaded, then exit early as there is no use for us to load again
		if docpad.loadedPlugins[pluginName]?
			# However we probably want to reload the configuration as perhaps the user or environment configuration has changed
			docpad.loadedPlugins[pluginName].setConfig()
			# Complete
			return next()

		# Add to loading stores
		docpad.slowPlugins[pluginName] = true

		# Check
		unless enabled
			# Skip
			docpad.log 'info', util.format(locale.pluginDisabled, opts.pluginName)
			return next()
		else
			# Load
			docpad.log 'debug', util.format(locale.pluginLoading, opts.pluginPath)

		# Create an instance
		try
			# Add to plugin stores
			docpad.loadedPlugins[pluginName] = loader.create({docpad})
		catch failedError
			err = new Errlop(
				util.format(locale.pluginFailed, opts.pluginPath),
				failedError
			)
			return next(err)

		# Log completion
		docpad.log 'debug', util.format(locale.pluginLoaded, opts.pluginPath)
		return next()


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
		return @  unless config.checkVersion

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
				docpad.warn(new Errlop(locale.exchangeError, err))
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
	contextualizeFiles: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}

		# Log
		docpad.log 'debug', util.format(locale.contextualizingFiles, collection.length)

		# Start contextualizing
		docpad.emitSerial 'contextualizeBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = docpad.createTaskGroup("contextualizeFiles", concurrency:0).done (err) ->
				# Kill the timer
				docpad.timer('slowfiles')

				# Check
				return next(err)  if err

				# After
				docpad.emitSerial 'contextualizeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# Log
					docpad.log 'debug', util.format(locale.contextualizedFiles, collection.length)

					# Forward
					return next()

			# Add contextualize tasks
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				slowFilesObject[file.id] = file.get('relativePath') or file.id
				tasks.addTask "conextualizing: #{filePath}", (complete) ->
					file.action 'contextualize', (err) ->
						delete slowFilesObject[file.id]
						return complete(err)

			# Setup the timer
			docpad.timer 'slowfiles', 'interval', config.slowFilesDelay, ->
				slowFilesArray = (value or key  for own key,value of slowFilesObject)
				docpad.log('info', util.format(locale.slowFiles, 'contextualizeFiles')+' \n'+slowFilesArray.join('\n'))

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
	renderFiles: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData,renderPasses} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}

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

				subTasks = docpad.createTaskGroup("renderFiles: Pass #{renderPass}]: renderCollection: #{collectionToRender.options.name}", concurrency:0).done (err) ->
					# Prepare
					return next(err)  if err

					# Plugin Event
					docpad.emitSerial('renderCollectionAfter', {collection:collectionToRender,renderPass}, next)

				# Cycle
				collectionToRender.forEach (file) ->
					filePath = file.getFilePath()
					slowFilesObject[file.id] = file.get('relativePath')
					subTasks.addTask "rendering: #{filePath}", (complete) ->
						renderFile file, (err) ->
							delete slowFilesObject[file.id] or file.id
							return complete(err)

				# Return
				subTasks.run()
				return collectionToRender

		# Plugin Event
		docpad.emitSerial 'renderBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Async
			tasks = docpad.createTaskGroup("renderFiles: renderCollection: renderBefore").done (err) ->
				# Kill the timer
				docpad.timer('slowfiles')

				# Check
				return next(err)  if err

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
			docpad.timer 'slowfiles', 'interval', config.slowFilesDelay, ->
				slowFilesArray = (value or key  for own key,value of slowFilesObject)
				docpad.log('info', util.format(locale.slowFiles, 'renderFiles')+' \n'+slowFilesArray.join('\n'))

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
	writeFiles: (opts,next) ->
		# Prepare
		[opts,next] = extractOptsAndCallback(opts,next)
		{collection,templateData} = opts
		docpad = @
		config = @getConfig()
		locale = @getLocale()
		slowFilesObject = {}

		# Log
		docpad.log 'debug', util.format(locale.writingFiles, collection.length)

		# Plugin Event
		docpad.emitSerial 'writeBefore', {collection,templateData}, (err) ->
			# Prepare
			return next(err)  if err

			# Completion callback
			tasks = docpad.createTaskGroup("writeFiles", concurrency:0).done (err) ->
				# Kill the timer
				docpad.timer('slowfiles')

				# Check
				return next(err)  if err

				# After
				docpad.emitSerial 'writeAfter', {collection}, (err) ->
					# Check
					return next(err)  if err

					# docpad.log 'debug', util.format(locale.wroteFiles, collection.length)
					return next()

			# Add write tasks
			collection.forEach (file,index) ->
				filePath = file.getFilePath()
				tasks.addTask "writing the file: #{filePath}", (complete) ->
					# Prepare
					slowFilesObject[file.id] = file.get('relativePath')

					# Create sub tasks
					fileTasks = docpad.createTaskGroup("tasks for file write: #{filePath}", concurrency:0).done (err) ->
						delete slowFilesObject[file.id]
						return complete(err)

					# Write out
					if file.get('write') isnt false and file.get('outPath')
						fileTasks.addTask "write out", (complete) ->
							file.action('write', complete)

					# Write source
					if file.get('writeSource') is true and file.get('fullPath')
						fileTasks.addTask "write source", (complete) ->
							file.action('writeSource', complete)

					# Run sub tasks
					fileTasks.run()

			# Setup the timer
			docpad.timer 'slowfiles', 'interval', config.slowFilesDelay, ->
				slowFilesArray = (value or key  for own key,value of slowFilesObject)
				docpad.log('info', util.format(locale.slowFiles, 'writeFiles')+' \n'+slowFilesArray.join('\n'))

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

		# Grab the template data we will use for rendering
		opts.templateData = docpad.getTemplateData(opts.templateData or {})

		# How many render passes will we require?
		# Can be over-written by API calls
		opts.renderPasses or= config.renderPasses

		# Destroy Regenerate Timer
		docpad.timer('regenerate')

		# Check plugin count
		docpad.log('notice', locale.renderNoPlugins)  unless docpad.hasPlugins()

		# Log
		docpad.log('info', locale.renderGenerating)
		docpad.notify (new Date()).toLocaleTimeString(), {title: locale.renderGeneratingNotification}

		# Tasks
		tasks = @createTaskGroup("generate tasks").done (err) ->
			# Update generating flag
			docpad.generating = false
			docpad.generateEnded = new Date()

			# Create Regenerate Timer
			if config.regenerateEvery
				docpad.timer 'regenerate', 'timeout', config.regenerateEvery, ->
					docpad.log('info', locale.renderInterval)
					docpad.action('generate', config.regenerateEveryOptions)

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
					new Errlop('DocPad is in an invalid state, please report this. Reference 3360')
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
				pick(opts, ['initial', 'reset', 'populate', 'reload', 'partial', 'renderPasses'])
			)


		# Check directory structure
		addTask 'check source directory exists', (complete) ->
			# Skip if we are not the initial generation
			return complete()  unless opts.initial is true

			# Continue if we are the initial generation
			sourcePath = docpad.getPath('source')
			unless sourcePath
				err = new Errlop(locale.renderNonexistant)
				return complete(err)

			# Forward
			return complete()

		# Check directory structure
		addTask 'ensure out directory exists', (complete) ->
			outPath = docpad.getPath(false, 'out')
			return safefs.ensurePath(outPath, complete)

		addGroup 'fetch data to render', (addGroup, addTask) ->
			# Fetch new data
			# If we are a populate generation (by default an initial generation)
			if opts.populate is true
				# This will pull in new data from plugins
				addTask 'populateCollectionsBefore', (complete) ->
					docpad.emitSerial('populateCollectionsBefore', opts, complete)

				# Rescan the file system
				# If we are a reload generation (by default an initial generation)
				# This is useful when the database is out of sync with the source files
				# For instance, someone shut down docpad, and made some changes, then ran docpad again
				# See https://github.com/bevry/docpad/issues/705#issuecomment-29243666 for details
				if opts.reload is true
					addGroup 'import data from file system', (addGroup, addTask) ->
						# Documents
						docpad.getPath('documents').forEach (documentsPath) ->
							addTask 'import documents', (complete) ->
								docpad.parseDirectory({
									modelType: 'document'
									collection: database
									path: documentsPath
									next: complete
								})

						# Files
						docpad.getPath('files').forEach (filesPath) ->
							addTask 'import files', (complete) ->
								docpad.parseDirectory({
									modelType: 'file'
									collection: database
									path: filesPath
									next: complete
								})

						# Layouts
						docpad.getPath('layouts').forEach (layoutsPath) ->
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
		}, opts.attributes or {})

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
		}, opts.attributes or {})

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
		}, opts.attributes or {})

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
	# @method render
	# @param {Object} opts
	# @param {Object} next
	# @param {Error} next.err
	# @param {Object} next.result
	# @param {Object} next.document
	###
	render: (opts,next) ->
		# Prepare
		docpad = @
		locale = @getLocale()
		config = @getConfig()
		[opts,next] = extractOptsAndCallback(opts,next)
		opts.stdin ?= false

		# Completion
		unless opts.output
			complete = next
		else
			complete = (err, result, document) ->
				# Forward
				return next(err)  if err

				# Output
				if opts.output is true
					process.stdout.write(result)
				else if opts.output
					return safefs.writeFile opts.output, result, (err) ->
						return next(err, result, document)

				# Forward
				return next(null, result, document)

		# Render
		if opts.stdin
			docpad.renderStdin(opts, complete)
		else if opts.document
			docpad.renderDocument(opts.document, opts, complete)
		else if opts.data
			docpad.renderData(opts.data, opts, complete)
		else if opts.text
			docpad.renderText(opts.text, opts, complete)
		else
			path = opts.path or opts.fullPath or opts.filename or null
			if path
				docpad.renderPath(path, opts, complete)
			else
				err = new Errlop(locale.renderInvalidOptions)
				return complete(err)

		# Chain
		@

	renderStdin: (opts, next) ->
		# Prepare
		docpad = @
		[opts,next] = extractOptsAndCallback(opts,next)
		data = ''

		# Read
		stdin = process.stdin
		stdin.resume()
		stdin.setEncoding('utf8')
		stdin.on 'data', (_data) ->
			docpad.timer('render')
			data += _data.toString()
		process.stdin.on 'end', ->
			docpad.timer('render')
			docpad.renderData(data, opts, next)

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
			tasks = docpad.createTaskGroup("watch tasks", concurrency:0).done(next)

			# Watch reload paths
			reloadPaths = union(docpad.getPath('reloads'), docpad.getPath('configs'))
			tasks.addTask "watch reload paths", (complete) ->
				docpad.watchdirs(
					reloadPaths,
					{
						'log': docpad.log
						'error': docpad.error
						'change': ->
							docpad.log 'info', util.format(locale.watchReloadChange, new Date().toLocaleTimeString())
							docpad.action 'load', (err) ->
								return docpad.fatal(err)  if err
								performGenerate(reset:true)
					},
					(err,_watchers) ->
						if err
							docpad.warn("Watching the reload paths has failed:\n"+docpad.inspect(reloadPaths), err)
							return complete()
						for watcher in _watchers
							docpad.watchers.push(watcher)
						return complete()
				)

			# Watch regenerate paths
			regeneratePaths = docpad.getPath('regenerates')
			tasks.addTask "watch regenerate paths", (complete) ->
				docpad.watchdirs(
					regeneratePaths,
					{
						'log': docpad.log
						'error': docpad.error
						'change': -> performGenerate(reset:true)
					},
					(err,_watchers) ->
						if err
							docpad.warn("Watching the regenerate paths has failed:\n"+docpad.inspect(regeneratePaths), err)
							return complete()
						for watcher in _watchers
							docpad.watchers.push(watcher)
						return complete()
				)

			# Watch the source
			sourcePaths = docpad.getPath('sources')
			tasks.addTask "watch the source path", (complete) ->
				docpad.watchdirs(
					sourcePaths,
					{
						'log': docpad.log
						'error': docpad.error
						'change': changeHandler
					},
					(err,_watchers) ->
						if err
							docpad.warn("Watching the source paths has failed:\n"+docpad.inspect(sourcePaths), err)
							return complete()
						for watcher in _watchers
							docpad.watchers.push(watcher)
						return complete()
				)

			# Run
			tasks.run()

			# Chain
			@

		# Timer
		queueRegeneration = ->
			docpad.timer('regeneration', 'timeout', config.regenerateDelay, performGenerate)

		# Generate
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
				err = new Errlop("""
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

		# Prepare
		run = (next) ->
			docpad.emitSerial 'runBefore', (err) ->
				return next(err)  if err
				balUtil.flow(
					object: docpad
					action: 'generate watch'
					args: [opts]
					next: (err) ->
						docpad.emitSerial('runAfter', next)
				)

		# Check if have the correct structure, if so let's proceed with DocPad
		sourcePath = @getPath('source')
		return run(next)  if sourcePath

		# We don't have the correct structure
		# Check if we are running on an empty directory
		rootPath = @getPath('root')
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

	###*
	# Info action
	# @private
	# @method info
	# @param {Object} opts
	# @param {Function} next
	###
	info: (opts, next) ->
		[opts,next] = extractOptsAndCallback(opts,next)
		console.log @inspect @getConfig()
		next?()
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

		# Exists?
		packagePath = @getPath(false, 'package')
		safefs.exists packagePath, (exists) ->
			# Check
			return next()  if exists

			# Write
			data = JSON.stringify({
				name: 'no-skeleton.docpad'
				version: '0.1.0'
				description: 'New DocPad project without using a skeleton'
				dependencies:
					docpad: '~'+docpad.getVersion()
				scripts:
					start: 'docpad run'
					test: 'docpad generate'
			}, null, '  ')
			safefs.writeFile(packagePath, data, next)

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
		tasks = @createTaskGroup("uninstall tasks").done(next)

		# Uninstall a plugin
		if opts.plugin
			tasks.addTask "uninstall the plugin: #{opts.plugin}", (complete) ->
				plugins =
					for plugin in opts.plugin.split(/[,\s]+/)
						plugin = "docpad-plugin-#{plugin}"  if plugin.indexOf('docpad-plugin-') isnt 0
						plugin
				docpad.uninstallNodeModule(plugins, complete)

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
		tasks = @createTaskGroup("install tasks").done(next)

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
				docpad.installNodeModule(plugins, complete)

		tasks.addTask "re-initialize the website's modules", (complete) ->
			docpad.initNodeModules(complete)

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
		@installNodeModule('npm docpad@6', {global: true}, next)

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
		tasks = @createTaskGroup("update tasks").done(next)

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
				docpad.installNodeModule('docpad@6 '+dependencies, complete)

		# Update the plugin dev dependencies
		devDependencies = []
		eachr docpad.websitePackageConfig.devDependencies, (version,name) ->
			return  if /^docpad-plugin-/.test(name) is false
			devDependencies.push(name+'@'+docpad.pluginVersion)
		if devDependencies.length isnt 0
			tasks.addTask "update plugins that are dev dependencies", (complete) ->
				docpad.installNodeModule(devDependencies, {save: '--save-dev'}, complete)

		tasks.addTask "fix node package versions", (complete) ->
			docpad.fixNodePackageVersions(complete)

		tasks.addTask "re-initialize the rest of the website's modules", (complete) ->
			docpad.initNodeModules(complete)

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
		config = @getConfig()
		locale = @getLocale()
		paths = []

		# Log
		docpad.log('info', locale.cleanStarted)

		# Tasks
		tasks = @createTaskGroup("clean tasks", concurrency:0).done (err) ->
			# Error?
			return next(err)  if err

			# Log
			message = util.format(
				locale.cleanFinish,
				paths.length
			)
			if paths.length
				message += ': '
				if paths.length isnt 1
					message += '\n'
				message += paths.join('\n')
			docpad.log('info', message)

			# Forward
			return next()

		tasks.addTask 'reset the collections', (complete) ->
			docpad.resetCollections(opts, complete)

		# Delete out path
		# but only if our outPath is not a parent of our rootPath
		tasks.addTask 'delete out path', (complete) ->
			rootPath = docpad.getPath('root')
			outPath = docpad.getPath('out')

			# Only remove outpath if it does not contain our root path
			if outPath and pathUtil.relative(outPath, rootPath).startsWith('..')
				paths.push(outPath)
				rimraf(outPath, complete)
			else
				complete()

		# Run tasks
		tasks.run()

		# Chain
		@



	###*
	# Initialize a Skeleton into to a Directory
	# @private
	# @method initSkeleton
	# @param {Object} skeletonModel
	# @param {Function} next
	# @param {Error} next.err
	###
	initSkeleton: (skeletonModel,next) ->
		# Prepare
		docpad = @
		config = @getConfig()
		rootPath = @getPath(false, 'root')

		# Tasks
		tasks = @createTaskGroup("initSkeleton tasks").done(next)

		tasks.addTask "ensure the path we are writing to exists", (complete) ->
			safefs.ensurePath(rootPath, complete)

		# Clone out the repository if applicable
		if skeletonModel? and skeletonModel.id isnt 'none'
			tasks.addTask "clone out the git repo", (complete) ->
				docpad.initGitRepo({
					cwd: rootPath
					url: skeletonModel.get('repo')
					branch: skeletonModel.get('branch')
					remote: 'skeleton'
					next: complete
				})
		else
			tasks.addTask "ensure src path exists", (complete) ->
				safefs.ensurePath(docpad.getPath(false, 'source'), complete)

			tasks.addGroup "initialize the website directory files", ->
				@setConfig(concurrency:0)

				# README
				@addTask "README.md", (complete) ->
					readmePath = docpad.getPath(false, 'root', 'README.md')
					data = """
						# Your [DocPad](http://docpad.org) Project

						## License
						Copyright &copy; #{(new Date()).getFullYear()}+ All rights reserved.
						"""
					safefs.writeFile(readmePath, data, complete)

				# Config
				@addTask "docpad.coffee configuration file", (complete) ->
					configPath = docpad.getPath(false, 'root', 'docpad.js')
					data = """
						// DocPad Configuration File
						// http://docpad.org/docs/config

						// Define the DocPad Configuration
						const docpadConfig = {
							// ...
						}

						// Export the DocPad Configuration
						module.exports = docpadConfig
						"""
					safefs.writeFile(configPath, data, complete)

				# Documents
				@addTask "documents directory", (complete) ->
					safefs.ensurePath(docpad.getPath(false, 'document'), complete)

				# Layouts
				@addTask "layouts directory", (complete) ->
					safefs.ensurePath(docpad.getPath(false, 'layout'), complete)

				# Files
				@addTask "files directory", (complete) ->
					safefs.ensurePath(docpad.getPath(false, 'file'), complete)

		# Run
		tasks.run()

		# Chain
		@

	###*
	# Install a Skeleton into a Directory
	# @private
	# @method installSkeleton
	# @param {Object} skeletonModel
	# @param {Function} next
	# @param {Error} next.err
	###
	installSkeleton: (skeletonModel,next) ->
		# Prepare
		docpad = @

		# Initialize and install the skeleton
		docpad.initSkeleton skeletonModel, (err) ->
			# Check
			return next(err)  if err

			# Forward
			docpad.install(null, next)

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
	useSkeleton: (skeletonModel,next) ->
		# Prepare
		docpad = @
		locale = @getLocale()

		# Extract
		skeletonId = skeletonModel?.id or 'none'
		skeletonName = skeletonModel?.get('name') or locale.skeletonNoneName

		# Log
		docpad.log('info', util.format(locale.skeletonInstall, skeletonName)+' '+locale.pleaseWait)

		# Install Skeleton
		docpad.installSkeleton skeletonModel, (err) ->
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
		locale = @getLocale()
		config = @getConfig()

		# Get the available skeletons
		docpad.getSkeletons (err,skeletonsCollection) ->
			# Check
			return next(err)  if err

			# Prepare
			skeleton = opts.skeleton

			# Already selected
			if skeleton
				skeletonModel = skeletonsCollection.get(skeleton)
				if skeletonModel
					return next(null, skeletonModel)
				else
					return next(new Errlop(
						"Couldn't fetch the skeleton with id #{@commander.skeleton}"
					))

			# Show
			docpad.log('info', locale.skeletonSelectionIntroduction + '\n')
			skeletonNames = skeletonsCollection.map (skeletonModel) ->
				skeletonName = skeletonModel.get('name')
				skeletonDescription = skeletonModel.get('description').replace(/\n/g, '\n\t')
				console.log "  #{ansiStyles.underline skeletonName}\n  #{skeletonDescription}\n"
				return skeletonName

			# Select
			docpadUtil.choose locale.skeletonSelectionPrompt, skeletonNames, {}, (err, name) ->
				return next(err)  if err
				index = skeletonNames.indexOf(name)
				return next(null, skeletonsCollection.at(index))

		# Chain
		@

	###*
	# Fail if the skeleton is not empty
	# @private
	# @method skeletonEmpty
	# @param {Function} next
	# @param {Error} next.err
	###
	skeletonEmpty: (next) ->
		# Prepare
		locale = @getLocale()
		packagePath = @getPath('package')

		# Check
		if packagePath
			err = new Errlop(locale.skeletonExists)
			return next(err)

		# Success
		return next()

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
		@skeletonEmpty (err) ->
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


# ---------------------------------
# Export

module.exports = DocPad
