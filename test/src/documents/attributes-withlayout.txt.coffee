---
title: 'Attributes With Layout'
layout: 'attributes'
tags: ['attributes','with-layout']
---

# Fetch data
attrs = @documentModel.getAttributes()

# Delete environment specific variables
delete attrs.date
delete attrs.fullPath
delete attrs.fullDirPath
delete attrs.outPath
delete attrs.data

# Output data
text @require('util').inspect(attrs)