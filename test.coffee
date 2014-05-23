regex = ///
	# allow some space
	^\s*

	# allow potential comment characters in seperator
	[^\n]*?

	# discover our seperator characters
	(
		([^\s\d\w])  #\2
		\2{2,}  # match the above (the first character of our seperator), 2 or more times
	) #\1

	# discover our parser (optional)
	(?:
		\x20*  # allow zero or more space characters, see https://github.com/jashkenas/coffee-script/issues/2668
		(
			[a-z]+  # parser must be lowercase alpha
		)  #\3
	)?

	# discover our meta content
	(
		[\s\S]*?  # match anything/everything lazily
	) #\4

	# allow potential comment characters in seperator
	[^\n]*?

	# match our seperator (the first group) exactly
	\1

	# allow potential comment characters in seperator
	[^\n]*
	///

str = """
	/***
	works: true
	***/
	"""

console.log regex.exec(str)