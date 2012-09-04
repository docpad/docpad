---
title: 'Attributes No Layout'
date: 2012-03-14
tags: ['attributes','with-layout']
---

# Fetch data
attrs = @getDocument().getAttributes()

# Delete environment specific variables
# timezone makes the dates impossible
# path differences make them impossible
# data is too much output
delete attrs.ctime
delete attrs.mtime
delete attrs.date
delete attrs.fullPath
delete attrs.fullDirPath
delete attrs.outPath
delete attrs.outDirPath
delete attrs.data

# Sort the attributes
keys = []
keys.push(key)  for own key,value of attrs
keys.sort()
sortedAttrs = {}
for key in keys
	sortedAttrs[key] = attrs[key]

# Output data
text @require('util').inspect(sortedAttrs)