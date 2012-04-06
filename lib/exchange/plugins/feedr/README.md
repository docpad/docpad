# Feedr Plugin for DocPad

This plugin is able to pull in remote json and xml feeds, convert them to JSON data, and expose them to `@feedr.feeds[feednName]` for your templates.


## Usage

### Setup

First we have to tell Feedr which feeds it should retrieve, you can do this by adding the following to your website's `package.json` file:

``` json
"docpad": {
	"plugins": {
		"feedr": {
			"feeds": {
				"twitter": {
					"url": "https://api.twitter.com/1/statuses/user_timeline.json?screen_name=balupton&count=20&include_entities=true&include_rts=true"
				},
				"someOtherFeedName": {
					"url": "someOtherFeedUrl"
				}
			}
		}
	}
}
```

### Rendering

Then inside your templates, we would do something like the following to render the items:

- Using [CoffeeKup](http://coffeekup.org/)

	``` coffeescript
	ul ->
		for tweet in @feedr.feeds.twitter
			continue  if tweet.in_reply_to_user_id
			li datetime: tweet.created_at, ->
				a href: "https://twitter.com/#!/#{tweet.user.screen_name}/status/#{tweet.id_str}", title: "View on Twitter", ->
					tweet.text
	```

- Using [Eco](https://github.com/sstephenson/eco)

	``` coffeescript
	<ul>
		<% for tweet in @feedr.feeds.twitter: %>
			<% continue  if tweet.in_reply_to_user_id %>
			<li datetime="<%=tweet.created_at%>">
				<a href="https://twitter.com/#!/<%=tweet.user.screen_name%>/status/<%=tweet.id_str%>" title="View on Twitter">
					<%=tweet.text%>
				</a>
			</li>
		<% end %>
	</ul>
	```


## History

You can discover the history inside the `History.md` file


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)