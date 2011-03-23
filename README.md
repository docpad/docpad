- Layouts
	- Content
	- Stylesheet
- Markdown Document
	- Title
	- Page Numbers
	- Content
	- Which Layout
	- Stylesheet associated with that particular document
	- Listed or Unlisted
- Images
	- Images should be 3rd party, we do not support image uploads
- User Page
	- Document Listing
	- Bio
	- Email
	- GitHub Account for Login



----

Create your Layout Form

Name: [...]

Content:
[ your html layout content ]

Stylesheet:
[ CSS content 							]

----


----

Create your Document Form

Title: [ title of the document ]
Layout: [ references a created layout ] <-- theme stylesheet

Format:
[ dropdown: html, markdown, textile ]

Content:
[ your format content ]

Stylesheet:
[ CSS content 							]

----

=============

/server/doxbox/

	server.js < node.js file

	_users
		_users.json

		~balupton
			_balupton.json <- private file

			_layouts
				index.html
				index.css
					>
						{{curl gist.github.com/balupton/balupton-hyde.css}}
				security.html < inherits from index.html
				security.css

			_documents
				...
				projects
					jquery-ajaxy.html
					jquery-ajaxy.css
				posts
					intelligent-state-handling.md
				security
					webct-exploit.md
					webct-exploit.css
					bluemountain-exploit.md
					bluemountain-exploit.css

		~disenchant


LAYOUTS ONLY BODY ELEMENT.
WE STRIP JAVASCRIPT, SCRIPT ELEMENTS.
WE RUN compiled css and html through a checker <style src="..."
CURL checks mime-types, if text plain fallback to extension, ignores files bigger than 100KB.


Monentise through:
	- Document limits
	- Unlisted accounts



<!DOCTYPE html>
<html>
	<head>
		<title>WebCT Exploit</title>
		<script src="http://doxbox.com/resources/script.js"></script>
		<link href="http://doxbox.com/~balupton/security/webct-exploit.css?bundled" />
			^ bundles:
				http://doxbox.com/resources/style.css
				http://doxbox.com/~balupton.css aliases http://doxbox.com/~balupton/index.css
				http://doxbox.com/~balupton/security.css
				http://doxbox.com/~balupton/security/webct-exploit.css
	</head>
	<body>
		<div id="toolbar">
			<div>Print</div>
			<div>View as Markdown</div>
		</div>
		<article typeof="soic:Post" about="http://doxbox.com/~balupton/security/webct-exploit">
			<





=============

~balupton
	security
		webct-exploit.md


http://doxbox.com/~balupton/security/webct-exploit
	> toolbar up the top, has download as markdown, print button, edit if able, etc.


http://doxbox.com/~balupton/security/webct-exploit
> http://doxbox.com/~balupton/security/webct-exploit.md


http://doxbox.com/~balupton/security/webct-exploit
> redirect to http://doxbox.com/~balupton/security/webct-exploit.md

security.html
	> should theoretically be a layout not document
		^ omg complexity!

	>







http://doxbox.com/~balupton/security/webct-exploit.md

http://doxbox.com/~balupton/security/
	->
		list of all listed documents in security (if owner + unlisted)
		layout should this use?
	->
		security.html




http://doxbox-content.com/ <- sandbox domain, holds all

http://doxbox.com/~balupton/
	->
		listing of all my LISTED documents (if logged in, you see unlisted as well - in its own section)
		with bio, bio layout customisable (secret... called bio template)

http://doxbox.com/~balupton/security-report.md
	-> HTML rendering of this security-report document

http://doxbox.com
	-> signup



Here is some code:

	{{curl https://gist.github.com/867260}}




Your css:

{{curl https://gist.github.com/867260}}




======





var cssFiles = [], $head = $('head');

$head.children('link[href]').each(function(){
	var $link = $(this);
	cssFiles.push($link.attr('href'));
});

var compiledUrl = Hyde.compileCssFiles(cssFiles);

$head.append(
	$('<link href="'+compiledUrl+'" rel="stylesheet" type="text/css" />');
);


