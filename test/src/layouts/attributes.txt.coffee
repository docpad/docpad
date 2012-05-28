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
	delete attrs.fullDirPath
	delete attrs.outPath
	delete attrs.outDirPath
	delete attrs.data

	# Output data
	text @require('util').inspect(attrs)