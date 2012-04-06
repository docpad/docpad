# Partials Plugin for DocPad

This plugin provides DocPad with Partials. Partials are documents which can be inserted into other documents, and are also passed by the docpad rendering engine.


## Usage

### Setup

To use, first create the `src/partials` directory, and place any partials you want to use in there.

Then in our templates we will be exposed with the `@partial(filename,data)` function. The `data` argument is optional, and can be used to send custom data to the partial's `templateData`.


### Example

For instance we could create the file `src/partials/hello.html.md` which contains `**Hello <%=@name or 'World'%>**`.

We could then render it by using `<%=@partial('hello.html.coffee')%>` to get back `<strong>Hello World</strong>` or with `<%=@partial('hello.html.coffee',{name:'Apprentice'})%>` to get back `<strong>Hello Apprentice</strong>`.



## History

You can discover the history inside the `History.md` file


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012 [Bevry Pty Ltd](http://bevry.me)