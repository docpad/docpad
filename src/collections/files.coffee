# Necessary
_ = require('underscore')

# Local
{QueryCollection,Model} = require(__dirname+'/../base')
FileModel = require(__dirname+'/../models/file')

# Files Collection
class FilesCollection extends QueryCollection

	# Base Model for all items in this collection
	model: FileModel

	# Base Collection for all child collections
	collection: FilesCollection


	# Contextualize files
	# next(err)
	contextualize: (opts={},next) ->
		# Prepare
		me = @
		collection = @

		# Log
		me.log 'debug', "Contextualizing #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			# After
			me.emit 'contextualizeAfter', {collection}, (err) ->
				me.log 'debug', "Contextualized #{collection.length} files"
				next?()

		# Fetch
		@forEach (file) -> tasks.push (complete) ->
			file.contextualize(complete)

		# Start contextualizing
		if tasks.total
			me.emit 'contextualizeBefore', {collection,templateData}, (err) =>
				return next?(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

	# Render files
	# next(err)
	render: (opts={},next) ->
		# Prepare
		me = @
		collection = @
		{templateData} = opts

		# Log
		me.log 'debug', "Rendering #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			return next?(err)  if err
			# After
			me.emit 'renderAfter', {collection}, (err) ->
				me.log 'debug', "Rendered #{collection.length} files"  unless err
				return next?(err)

		# Push the render tasks
		collection.forEach (file) -> tasks.push (complete) ->
			# Skip?
			dynamic = file.get('dynamic')
			render = file.get('render')

			# Render
			if dynamic or (render? and !render)
				complete()
			else if file.render?
				file.render({templateData},complete)
			else
				complete()

		# Start rendering
		if tasks.total
			me.emit 'renderBefore', {collection,templateData}, (err) =>
				return next?(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@

	# Write files
	# next(err)
	write: (opts={},next) ->
		# Prepare
		me = @
		collection = @

		# Log
		me.log 'debug', "Writing #{collection.length} files"

		# Async
		tasks = new balUtil.Group (err) ->
			# After
			me.emit 'writeAfter', {collection}, (err) ->
				me.log 'debug', "Wrote #{collection.length} files"  unless err
				return next?(err)

		# Cycle
		collection.forEach (file) -> tasks.push (complete) ->
			# Skip
			dynamic = file.get('dynamic')
			write = file.get('write')

			# Write
			if dynamic or (write? and !write)
				complete()
			else if file.writeRendered?
				file.write(complete)
			else if file.write?
				file.write(complete)
			else
				complete()

		#  Start writing
		if tasks.total
			me.emit 'writeBefore', {collection,templateData}, (err) =>
				return next?(err)  if err
				tasks.async()
		else
			tasks.exit()

		# Chain
		@


# Export
module.exports = FilesCollection
