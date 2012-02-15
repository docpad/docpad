###
This plugin is still in beta, don't use it.
###

# Export Plugin
module.exports = (BasePlugin) ->

	# Define User
	class User
		email: null
		username: null
		name: null
		url: null
		id: null

		constructor: (user) ->
			@apply user
		
		fromGithub: (user) ->
			@apply user

		apply: (user) ->
			for own key, value of user
				@[key] = value
			@normalize()

		normalize: ->
			@id or= @username or @email


	# Define Plugin
	class AuthenticatePlugin extends BasePlugin
		# Plugin Name
		name: 'authenticate'
		config: {}

		# DocPad Maintainers
		maintainers: {} # email indexed
		authenticated: {} # email indexed
		users: {} # listing of users

		# User
		User: User
		user: null

		# Do we have a logged user?
		isAuthenticated: ->
			return @user?
		
		# Authenticate
		authenticate: ->
			everyauth.github
				.appId(@config.github.appId)
				.appSecret(@config.github.appSecret)
				.redirectPath('/')
				.findOrCreateUser (session, accessToken, accessTokenExtra, githubUserMetadata) =>
					return @users[user.id] = @users[user.id] or new User().fromGithub(githubUserMetadata)

		# Fetch the logged in user
		getUser: (user) ->
			user or= @user
			unless user instanceof @User
				user = null
			return user
		
		# Set the logged in user
		setUser: (user) ->
			@user = @getUser(user)
			return @
		
		# Create a new User
		newUser: (user) ->
			return new @User(user)
		
		# Are they a maintainer
		isMaintainer: (user) ->
			user = @getUser(user)
			return false  unless user

			for maintainer in @docpad.maintainers
				if maintainer.email? and maintainer.email is user.email
					return true
			
			return false
