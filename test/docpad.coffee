module.exports =
	reportStatistics: false
	reportErrors: false
	detectEncoding: require('safeps').isWindows() is false

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

		site:
			styles: ['/styles/style.css']
			scripts: ['/scripts/script.js']
			title: "Your Website"
			description: """
				When your website appears in search results in say Google, the text here will be shown underneath your website's title.
				"""
			keywords: """
				place, your, website, keywoards, here, keep, them, related, to, the, content, of, your, website
				"""

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

	collections:
		docpadConfigCollection: (database) ->
			database.findAllLive({tag: $has: 'docpad-config-collection'})

	events:
		renderDocument: (opts) ->
			src = "testing the docpad configuration renderDocument event"
			out = src.toUpperCase()
			opts.content = (opts.content or '').replace(src, out)
