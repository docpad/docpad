# Cachr Plugin for DocPad

This plugin caches remote resources locally.


## Usage

To use, simply wrap any url you want to cache locally within the exposed `@cachr(url)` function inside your templates.

- [CoffeeKup](http://coffeekup.org/) example:

	``` coffeescript
	img src:'http://somewebsite.com/someimage.gif'
	```

	would become:

	``` coffeescript
	img src:@cachr('http://somewebsite.com/someimage.gif')
	```

- [Eco](https://github.com/sstephenson/eco) example:

	``` coffeescript
	<img src="http://somewebsite.com/someimage.gif"/>
	```

	would become:

	``` coffeescript
	<img src="<%=@cachr('http://somewebsite.com/someimage.gif')%>"/>
	```



## History

You can discover the history inside the `History.md` file


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)