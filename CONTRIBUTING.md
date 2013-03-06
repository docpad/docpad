# Contributing


## Support

1. **GitHub Issues IS ONLY for bug reports and development tasks related to the core**
1. For everything else (questions, support, etc) use our [Official Support Channels](http://docpad.org/support)
1. With bug reports, be sure to specify:
	1. Your docpad version `docpad --version`
	1. Your node version `node --version`
	1. Your npm version `npm --version`
	1. Your operating system's name, architecture, and version
	1. What you did
	1. What happened
	1. What you expected


## Development

1. Fork the DocPad Repository
1. Clone your fork and cd into it
1. Insure CoffeeScript is installed globally; `npm install -g coffee-script`
1. Run `cake setup` to setup project for development
1. Run `npm link` to link our local copy as the global instance (so it is available via `docpad`)
1. Run `cake watch` to compile our source files and recompile on changes


## Pull Requests

1. Each pull request should be made on its own branch. Branches should be stemmed from master. E.g. `git checout master; git checkout -b your-new-branch`
1. Test your changes before you submit the pull request (see testing section), if possible, add tests for your change - if you don't know how to fix the tests, submit your pull request and say so, happy to help (but it will slow down integration)
1. **When submitting the pull request, specify the `dev` branch as the integration branch (the integration branch is which branch your pull request will be merged into on the official repo)**
1. If you'd like, feel free to add yourself to the contributors section of the `package.json` file if it exists
1. By submitting a pull request, you agree that your submission can be used freely and without restraint by those whom your submitting the pull request to


## Testing

1. Run `cake test` to run the tests
1. There are several types of tests run, the most common is the rendering test, which compares files inside `test/out` to `test/out-expected`
