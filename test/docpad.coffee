module.exports =
	reportStatistics: false
	reportErrors: false

	environments:
		development:
			a: 'websiteConfig'
			b: 'websiteConfig'
			c: 'websiteConfig'
			templateData:
				a: 'websiteConfig'
				b: 'websiteConfig'
				c: 'websiteConfig'

	templateData:
		require: require

	collections:
		docpadConfigCollection: (database) ->
			database.findAllLive({tag: $has: 'docpad-config-collection'})

	events:
		renderDocument: (opts) ->
			src = "testing the docpad configuration renderDocument event"
			out = src.toUpperCase()
			opts.content = opts.content.replace(src,out)