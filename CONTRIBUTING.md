<!--
2020 March 26
https://github.com/bevry/base
-->

# Before You Post!

## Support

We offer support through our [Official Support Channels](https://bevry.me/support). Do not use GitHub Issues for support, your issue will be closed.

## Contribute

Our [Contributing Guide](https://bevry.me/contribute) contains useful tips and suggestions for how to contribute to this project, it's worth the read.

## Development

### Setup

1. [Install Node.js](https://bevry.me/install/node)

1. Fork the project and clone your fork - [guide](https://help.github.com/articles/fork-a-repo/)

1. Setup the project for development

    ```bash
    npm run our:setup
    ```

### Developing

1. Compile changes

    ```bash
    npm run our:compile
    ```

1. Run tests

    ```bash
    npm test
    ```

### Publishing

Follow these steps in order to implement your changes/improvements into your desired project:

#### Preparation

1. Make sure your changes are on their own branch that is branched off from master.

    1. You can do this by: `git checkout master; git checkout -b your-new-branch`
    1. And push the changes up by: `git push origin your-new-branch`

1. Ensure all tests pass:

    ```bash
    npm test
    ```

    > If possible, add tests for your change, if you don't know how, mention this in your pull request

1. Ensure the project is ready for publishing:

    ```
    npm run our:release:prepare
    ```

#### Pull Request

To send your changes for the project owner to merge in:

1. Submit your pull request
    1. When submitting, if the original project has a `dev` or `integrate` branch, use that as the target branch for your pull request instead of the default `master`
    1. By submitting a pull request you agree for your changes to have the same license as the original plugin

#### Publish

To publish your changes as the project owner:

1. Switch to the master branch:

    ```bash
    git checkout master
    ```

1. Merge in the changes of the feature branch (if applicable)

1. Increment the version number in the `package.json` file according to the [semantic versioning](http://semver.org) standard, that is:

    1. `x.0.0` MAJOR version when you make incompatible API changes (note: DocPad plugins must use v2 as the major version, as v2 corresponds to the current DocPad v6.x releases)
    1. `x.y.0` MINOR version when you add functionality in a backwards-compatible manner
    1. `x.y.z` PATCH version when you make backwards-compatible bug fixes

1. Add an entry to the changelog following the format of the previous entries, an example of this is:

    ```markdown
    ## v6.29.0 2013 April 1

    -   Progress on [issue #474](https://github.com/docpad/docpad/issues/474)
    -   DocPad will now set permissions based on the process's ability
        -   Thanks to [Avi Deitcher](https://github.com/deitch), [Stephan Lough](https://github.com/stephanlough) for [issue #165](https://github.com/docpad/docpad/issues/165)
    -   Updated dependencies
    ```

1. Commit the changes with the commit title set to something like `v6.29.0. Bugfix. Improvement.` and commit description set to the changelog entry

1. Ensure the project is ready for publishing:

    ```
    npm run our:release:prepare
    ```

1. Prepare the release and publish it to npm and git:

    ```bash
    npm run our:release
    ```
