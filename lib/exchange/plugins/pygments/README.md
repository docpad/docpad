# Pygments Plugin for DocPad

This plugin enables [Pygments](http://pygments.org/) syntax highlighting for DocPad.



## Installation

1. Install Python

	If you are on Linux or OSX, generally Python is already installed for you.
	
	- Via Homebrew

		1. [Install Homebrew](http://mxcl.github.com/homebrew/)

		2. Install Python

			``` bash
			brew install python
			
			```
		
		3. Add the Python share directory to your path: `/usr/local/share/python`

		4. Now follow the generic installation instructions


2. Install Pip
	
	``` bash
	easy_install pip
	```


3. Install Pygments

	```
	pip install pygments
	```


## Usage

- With Github Flavored Markdown
	
		## Coffeescript with markdown backticks:

		``` coffeescript
		alert 'hello'
		```

		## Guessing with markdown backticks:

		```
		alert 'hello'
		```

		## Guessing with markdown standard:

			alert 'hello'
		

- With HTML

	``` html
	<h2>Coffeescript with html:</h2>

	<code class="highlight" lang="coffeescript">
		alert 'hello'
	</code>


	<h2>Guessing with html:</h2>

	<code class="highlight">
		alert 'hello'
	</code>
	```



## History

You can discover the history inside the `History.md` file


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)