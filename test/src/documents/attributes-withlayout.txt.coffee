---
title: 'Attributes With Layout'
layout: 'attributes'
tags: ['attributes','with-layout']
---

# Fetch data
data = @documentModel.getAttributes()

# Delete environment specific variables
delete data.date
delete data.fullPath
delete data.outPath

# Output data
text @require('util').inspect(data)