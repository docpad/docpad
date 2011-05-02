---
layout: post
title: Intelligent State Handling
---

Hashbangs (#!), hashes (#) and even the HTML5 History API (pushState, popState) all have issues. This article will go through the issues with each one, their use cases, then provide the evolution of their solutions. At the end with little bit of educated simplicity you'll be able to achieve better results; in terms of a better experience for your users as well as better compatibility, accessibility and maintainability in your solutions.


## The Problems

### Issues Coupled with the Hashbang

1. Your website will require tedious routing, mapping and escaping on your applications side which break the traditional web architecture <sup>[1](http://code.google.com/web/ajaxcrawling/docs/getting-started.html), [2](http://code.google.com/web/ajaxcrawling/docs/html-snapshot.html)</sup>:
	1. Have the traditional url that we are use to `http://mywebsite.com/page1` redirect to `http://mywebsite.com/#!page1`
	2. Code an `onhashchange` event which hooks into `http://mywebsite.com/#!page1` and send a ajax request off to some custom server-side code made to handle that ajax
	3. Ensure that `http://mywebsite.com?_escaped_fragment_=page1` is exactly the same of what we would have traditionally expected to be at `http://mywebsite.com/page1` and have it accessible via search Engines
2. Your website will no longer work for js-disabled users and is no longer crawlable by search engines other than Google (a sitemap will have to be provided to them).


### Issues Coupled with Hashes

These issues are unavoidable if hashes are used.

1. There are now two urls for the same content
	1. `http://twitter.com/balupton` and `http://twitter.com/#!/balupton`
	2. `http://mywebsite.com/page1` and `http://mywebsite.com/#/page1`
2. URLs get polluted if we did not start on the home page
	1. `http://www.facebook.com/balupton#!/balupton?sk=info`
	2. `http://mywebsite.com/page1#/page2`
3. If a user shares a hashed url with a js-disabled user - the user will not get the right page.
4. Performance and experience issues when a hashed url is loaded.
	1. When a user accesses `http://mywebsite.com/page1#/page2` the browser starts on `http://mywebsite.com/page1` then does the ajax request and loads in `page2` - causing two loads for the initial access instead of just one.
	2. This is an experience issue as it is annoying for the user as they are either stuck on a "loading" page, or they start scrolling the initial page only for it to disappear and change to another page.

### Issues Coupled with Over-Engineering

These issues are generally coupled with the use of hashes despite them just being a result of over-engineering and can be simply avoided.

1. Using the hashbang and inheriting its problems.
2. Having no support for the traditional url at all, users are forced to use the hashed url; disabling the site for non-js users and search engines.
	1. `http://twitter.com/balupton` forces a redirect to `http://twitter.com/#!/balupton`
3. Coding custom and separate AJAX controller actions the client and server side breaking DRY and graceful best practices


## The Solution

### Warning

_**Some pretty bold statements follow;** especially as the statements challenge the ways things have been done for a very long long time. So lets put our egos aside together and show some humility to be open to learning new ways of doing things. Feeling open to learning some awesome new ways of doing things? Great. Let's continue._

### Why The HashBang is Unnecessary

There is absolutely no need for the hashbang; it is credited to over-engineering on google's behalf. The following snippet of code is all that your traditional website needs to use hashes and provide rich ajax experiences, support search engines, js-disabled users and even google analytics:

[View the code snippet](https://gist.github.com/858093)

What does this code do?

1. When `http://mywebsite.com/page1` is accessed it works just as it would traditionally - so search engines and js-disabled users are naturally supported. This is without any tedious server-side routing, mapping or escaping. You've coded your website just as you would normally.
2. When `http://mywebsite.com/#/page1` is accessed it will perform an ajax request to our traditional url `http://mywebsite.com/page1` fetch the HTML of that page, and load in the page's content into our existing page.

So already we have a crawlable ajax solution accessible by search engines and js-disabled users without any server-side code. Take that google!


### AJAX Response Optimisation

So the above is great, but it still fetches the entire HTML of each page it does a AJAX request for - when really we just need the content of the page we want (the template without the layout). Let's utilise the following server side code in our page action:

[View the code snippet](https://gist.github.com/858091)

What we do here is if `http://mywebsite.com/page1` is requested normally treat it just as normal rendering it with the layout, if it is requested via AJAX then return just the rendered template in a JSON response. This can easily be extended so we can send JSON data variables along with the rendered content. In fact [jQuery Ajaxy](http://balupton.com/sandbox/jquery-ajaxy) has supported these solutions out of the box since July 2008, as well as having a [Zend Framework Action Helper](https://github.com/balupton/balphp/blob/master/lib/Bal/Controller/Action/Helper/Ajaxy.php) to make these server-side optimisations easier and more powerful (supporting sub-pages/sub-templates, data attaching, caching, etc).

So right now we have a crawlable ajax solution which is also incredibly optimised. Though it still suffers from the problems coupled with hashes - which are unavoidable as long we still use hashes.


### The HTML5 History API - Our Saviour

Recently the [HTML5 History API](https://developer.mozilla.org/en/DOM/Manipulating_the_browser_history) came out which is literally our saviour - it solves the issues coupled with hashes once and for all. The HTML5 History API allows users to modify the URL directly, attach data and titles to it, all without changing the page! Yay! So let's look at what our updated code example will look like:

[View the code snippet](https://gist.github.com/854622)

Though so far all the HTML5 Browsers handle the HTML5 History API a little bit differently; a pessimist could view this as a blocker and a call for defeat, though a optimist could come along and create a project called [History.js](https://github.com/balupton/history.js) which provides a cross-compatible experience between HTML5 and optionally HTML4 browsers fixing all the bugs and issues in the browsers. In fact, the code above already works perfectly with History.js - so bye bye learning curve you're all set to go already.


### Supporting HTML4 Browsers - The Ultimate Decision

Okay okay... So what about HTML4 browsers, wouldn't they miss out on all this awesome HTML5 History API awesomeness? Well no and yes - it depends. This is where you need to make a serious decision and a lot of consideration. The question you have to ask yourself is - what is more important to me; supporting the rich web 2.0 ajax experience in HTML5 and HTML4 browsers while incurring the issues that are coupled with hashes when the site is accessed by a HTML4 user, or not incurring those issues by not supporting a rich web 2.0 ajax experience in HTML4 browsers. That is a decision that only you can make based on your websites use cases and audience.


### Pulling it All Together

Great, so all I need to do is use History.js, that code above and I've solved life? _Yep._ And if I want to support HTML4 browsers as the issues coupled with hashes aren't a biggie for me I can? _Yep._ And if I want to further optimise the AJAX responses I now know how? _Yep._ Well blimey that's awesome. _Thanks :)_


### So what's next?

History.js is as stable as it gets right now. The future is now towards CMS and Framework plugins (like that Zend Framework Action Helper) mentioned before to make the process of server-side optimisation easier; as well as javascript helpers to allow you to do that javascript stuff in one line of code; while still supporting advanced use cases such as sub-pages. These are all under active development by Benjamin Lupton (his contact details are in the footer). If you'd like to speed some development up of the server-side plugins then get in contact with him and he'll be sure to help you out :)


## The End

Any comments, concerns, feedback, want to get in touch? Here are my details.

### Benjamin Lupton

- Website: [http://balupton.com](http://balupton.com)
- Email: contact@balupton.com
- Skype: balupton
- Twitter: [balupton](http://twitter.com/balupton)

### Like it. Share it.

Sharing is by far the most valuable exercise you can do! Here are some pre-made tweets for you:

- The hashbang, hashes and pushState all have issues; learn your options: [[http://j.mp/etU7q6]] (via [@balupton](http://twitter.com/balupton))
- Rich Internet Applications; Hello HTML5 History API, Goodbye Hashbang: [[http://j.mp/etU7q6]] (via [@balupton](http://twitter.com/balupton))
- Nice summary of state handling via the URL in modern web apps: [[http://j.mp/etU7q6]] (via [@balupton](http://twitter.com/balupton))

### Licensing

Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)
Licensed under the [Attribution-ShareAlike 3.0 Australia (CC BY-SA 3.0)](http://creativecommons.org/licenses/by-sa/3.0/au/deed.en)
