$ ->
	editMode = false

	unless window.jQuery?
		console.log 'DocPad Administratio plugin requires jQuery...'  if console.log?
		return
	
	$ = window.jQuery

	$('[contenteditable]')
		.live 'focus', ->
			$this = $(this)
			$this.data 'before', $this.html()
			$this
		.live 'blur paste', ->
			$this = $(this)
			before = $this.data('before')
			if $this.data('before') isnt $this.html()
				$this.data 'before', $this.html()
				$this.trigger('change')
			$this
	
	$(document).bind 'keypress', (event) ->
		if event.which is 180 and event.shiftKey and (event.ctrlKey or event.altKey)
			editMode = !editMode
			console.log 'DocPad edit mode '+(if editMode then 'enabled' else 'disabled')  if console.log?
		$('[property]').attr('contenteditable',editMode)

	$('[property]').live 'change', ->
		$field = $(this)
		
		$article = $field.parents('[typeof="sioc:Post"]:first')
		return  unless $article.length
		url = $article.attr('about')
		
		key = $field.attr('property')
		value = $field.html()
		
		data = {}
		data[key] = value
		
		$.ajax(
			url: url
			type: 'POST'
			data: data
			success: (data, textStatus, jqXHR) ->
				console.log('success:',arguments)
			error: (jqXHR, textStatus, errorThrown) ->
				console.log('error:',arguments)
		)