---
tags: ['attr']
---

article =>
	# Document
	text @content

aside =>
	# Fetch data
	attrs = @documentModel.getAttributes()

	# Delete environment specific variables
	delete attrs.date
	delete attrs.fullPath
	delete attrs.outPath
	delete attrs.data

	# Output data
	text @require('util').inspect(attrs)