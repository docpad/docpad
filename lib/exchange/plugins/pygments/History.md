## History

- v0.2.0 March 18, 2012
	- Fixed Pygments plugin highlighting the code multiple times for documents with layouts

- v0.1.0 February 29, 2012
	- Added the [Pygments](http://pygments.org/) Syntax Highlighting plugin
		- It is disabled by default as not everyone would want syntax highlighting, to enable it, add the following to your website's `package.json` file:
			``` javascript
			"docpad": {
				"enabledPlugins": {
					"pygments": true
				}
			}
			```
		- Thanks to [Doug Neiner](https://github.com/dcneiner) for urging it along