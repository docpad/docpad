module.exports = {
	# Project
	invalidProject: """
		We couldn't find an existing DocPad project inside your current directory. Looked at: %s
		If you're wanting to use a pre-made project, then refer to:
		    https://docpad.bevry.me/projects
		If you're wanting to start your new project from scratch, then refer to the Getting Started guide here:
		    https://docpad.bevry.me/start
		For more information about what this means, visit:
		    https://docpad.bevry.me/troubleshoot
		"""

	# Watching
	watchStart: 'Watching is starting...'
	watchStarted: 'Watching has started successfully!'
	watchRegenerating: "Regenerating at: %s"
	watchRegenerated: "Regenerated at: %s"
	watchChange: "Change detected at: %s"
	watchIgnoredChange: "Ignored change at: %s"
	watchDirectoryChange: "Directory change at: %s"
	watchReloadChange: "Reload change detected at: %s"

	# File
	filenameMissingError: 'filename is required, it can be specified via filename, fullPath, or relativePath'
	fileEncode: "Converting encoding to [%s] from [%s] on: %s"
	fileEncodeConvertError: 'Encoding conversion failed, therefore we cannot convert the encoding to [%s] from [%s] on: %s'
	fileEncodeLoadError: 'Encoding utilities did not load, therefore we cannot convert the encoding to [%s] from [%s] on: %s'
	fileWrite: 'Writing the %s: %s %s'
	fileWrote: 'Wrote the %s: %s %s'
	fileDelete: 'Delete the %s: %s'
	fileDeleted: 'Deleted the %s: %s'

	# Document
	documentMissingParserError: "Unknown meta parser [%s] on: %s"
	documentParserError: "Failed to parse the meta data using the [%s] parser on: %s"
	documentIdChangeError: """
		The document %s tried to overwrite its `id` attribute with its meta-data.
		This will cause unexpected issues. We have ignored the `id` attribute changes to prevent further errors.
		We recommend you rename the `id` meta-data attribute on this document to something else.
		For more information, see: https://docpad.bevry.me/id-overwrite
		"""
	documentRenderExtensionNoChange: """
		Rendering the extension [%s] to [%s] on [%s] didn't do anything.
		Explanation here: https://docpad.bevry.me/extension-not-rendering
		"""
	documentMissingContentType: "ContentType was missing on document: %s"
	documentMissingLayoutError: "Could not find the layout [%s] on: %s"
	documentApplyError: "The `apply` option when rendering documents is now deprecated. Use `document.clone().action('render', ...)` instead"
	documentRender: "Rendering the file: %s"
	documentRenderError: "Something went wrong while rendering: %s"
	documentRendered: "Rendered the file: %s"

	# Render
	renderingFiles: "Rendering [%s] files"
	renderedFiles: "Rendered [%s] files"
	renderInvalidOptions: 'Invalid options passed to the render action'
	renderProgress: "Currently on [%s] at: %s"
	renderGenerating: "Generating..."
	renderGeneratingNotification: "Website generating..."
	renderGenerated: "Generated [%s] files in [%s] seconds!"
	renderGeneratedNotification: "Website generated"
	renderParsing: 'Parsing everything'
	renderParsed: 'Parsed everything'
	renderNonexistant: 'Cannot generate website as the source path was not found: %s'
	renderNoPlugins: "DocPad is currently running without any plugins installed. You probably want to install some: https://docpad.bevry.me/plugins"
	renderDirectoryParsing: "Parsing directory: %s"
	renderDirectoryParsed: "Parsed directory: %s"
	renderDirectoryNonexistant: "Skipped directory: %s (it does not exist)"
	cleanStarted: "Cleaning..."
	cleanFinish: "Cleaned [%s] paths"
	renderInterval: "Performing interval regeneration"
	slowFiles: "Waiting on the following files on %s:"

	# Contextualize
	contextualizingFiles: "Contextualizing [%s] files"
	contextualizedFiles: "Contextualized [%s] files"

	# Write
	writingFiles: "Writing [%s] files"
	wroteFiles: "Wrote [%s] files"

	# Action
	actionStart: "The action [%s] is starting..."
	actionSuccess: "The action [%s] completed successfully!"
	actionFailure: "The action [%s] failed to complete!"
	actionNonexistant: "The action %s does not exist"
	actionEmpty: "No action was provided"

	# Plugins
	pluginsSlow: "We're preparing your plugins, this may take a while the first time. Waiting on the plugins: %s"
	pluginLoading: "Loading plugin: %s"
	pluginLoaded: "Loaded plugin: %s"
	pluginUnsupported: "Skipped unsupported plugin: %s"
	pluginDisabled: "Skipped disabled plugin: %s"
	pluginFailed: "Plugin failed to instantiate: %s"

	# Collections
	addingDocument: "Adding document: %s"
	addingFile: "Adding file: %s"
	addingLayout: "Adding layout: %s"
	addingHtml: "Adding html file: %s"
	addingHasLayout: "Adding has layout file: %s"
	addingStylesheet: "Adding stylesheet file: %s"
	addingReferencesOthers: "Adding file that references others: %s"
	addingGenerate: "Adding generate file: %s"

	# Loading
	loadingConfigUrl: "Loading configuration url: %s"
	loadingConfigPath: "Loading configuration path: %s"
	loadingConfigPathFailed: "Failed to load the configuration path: %s"
	executeConfigPathFailed: "Failed to execute the configuration path: %s"
	invalidConfigPathData: "Loading the configuration [%s] returned an invalid result: %s"
	loadingFiles: "Loading [%s] files"
	loadedFiles: "Loaded [%s] files"
	loadingFileFailed: "Failed to load the file: %s"
	loadingFileIgnored: "Skipped ignored file: %s"
	loadingUserConfig: "Loading user's configuration: %s"
	loadedUserConfig: "Loaded user's configuration: %s"
	loadingDocPadPackageConfig: "Loading DocPad's package.json configuration: %s"
	loadedDocPadPackageConfig: "Loaded DocPad's package.json configuration: %s"
	loadingWebsitePackageConfig: "Loading website package.json configuration: %s"
	loadedWebsitePackageConfig: "Loaded website package.json configuration: %s"
	loadingEnvConfig: "Loading .env file configuration: %s"
	loadedEnvConfig: "Loaded .env file configuration: %s"
	loadingWebsiteConfig: "Loading website configuration"
	loadedWebsiteConfig: "Loaded website configuration"

	# Console
	consoleDescriptionInit: "initialize your project"
	consoleDescriptionRun: "run docpad on your project"
	consoleDescriptionRender: "render the file at <path> and output its results to stdout"
	consoleDescriptionGenerate: "(re)generates your project"
	consoleDescriptionWatch: "watches your project for changes, and (re)generates whenever a change is made"
	consoleDescriptionInstall: "install plugins"
	consoleDescriptionUninstall: "uninstall a plugin"
	consoleDescriptionUpdate: "update your local DocPad and plugin installations to their latest compatible version"
	consoleDescriptionUpgrade: "upgrade your global DocPad and NPM installations to the latest"
	consoleDescriptionClean: "ensure everything is cleaned correctly (will remove your out directory)"
	consoleDescriptionInfo: "display the information about your docpad instance"
	consoleDescriptionHelp: "output the help"
	consoleDescriptionUnknown: "anything else outputs the help"
	consoleOptionGlobal: "whether or not we should just fire the global installation of docpad"
	consoleOptionOutPath: "a custom directory to place the rendered project"
	consoleOptionOutput: "where to output the rendered document"
	consoleOptionStdin: "whether we should receive input via stdin"
	consoleOptionConfig: "a custom configuration file to load in"
	consoleOptionEnv: "the environment name to use for this instance, multiple names can be separated with a comma"
	consoleOptionLogLevel: "the rfc log level to display"
	consoleOptionVerbose: "set log level to 7"
	consoleOptionDebug: "output a log file"
	consoleOptionColor: "use color in terminal output"
	consoleOptionSilent: "don't write anything that isn't essential"
	consoleOptionProgress: "output the progress as it occurs"

	# Misc
	emittingEvent: "Emitting the event: %s"
	emittedEvent: "Emitted the event: %s"
	outPathConflict: """
		You have multiple files being written to [%s], they are:
		  - %s
		  - %s
		  Rename one of them to avoid an overwrite
		"""
	renderedEarlyViaInclude: """
		Your include of %s has failed as that document has not been rendered yet.
		For more information about what this means, visit:
		    https://docpad.bevry.me/render-early-via-include
		"""
	versionGlobal: "v%s (global installation: %s)"
	versionLocal: "v%s (local installation: %s)"
	welcome: "Welcome to DocPad %s"
	welcomeContribute: "Contribute: https://docpad.bevry.me/contribute"
	welcomeDonate: "Please donate to DocPad or have your company sponsor it: https://docpad.bevry.me/donate"
	welcomePlugins: "Plugins: %s"
	welcomeEnvironment: "Environment: %s"
	includeFailed: "Could not include the file at path [%s] as we could not find it"
	encodingLoadFailed: "Could not load the libraries required for encoding detection"
	warnOccured: "A warning occured:"
	fatalOccured: "A fatal error occured:"
	errorOccured: "An error occured:"
	errorSubmission: "Please report it using this guide: https://docpad.bevry.me/bug"
	errorInvalidCollection: "The custom collection [%s] is not a valid collection instance"
	unknownModelInCollection: "Unknown model structure inside the collection"
	startLocal: "Shutting down the global DocPad, and starting up the local"
	consoleExit: "Console is exiting..."
	destroyDocPad: "DocPad is shutting down..."
	destroyedDocPad: "Shutdown complete. See you next time."
}
