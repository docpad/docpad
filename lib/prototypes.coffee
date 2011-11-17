Array::hasCount or= (arr) ->
	count = 0
	for a in this
		for b in arr
			if a is b
				++count
				break
	return count

Array::has or= (thing) ->
	for value in @
		if thing is value
			return true
	return false

Date::toShortDateString or= ->
	return @toDateString().replace(/^[^\s]+\s/,'')

Date::toISODateString or= Date::toIsoDateString = ->
	pad = (n) ->
		if n < 10 then ('0'+n) else n

	# Return
	@getUTCFullYear()+'-'+
		pad(@getUTCMonth()+1)+'-'+
		pad(@getUTCDate())+'T'+
		pad(@getUTCHours())+':'+
		pad(@getUTCMinutes())+':'+
		pad(@getUTCSeconds())+'Z'

String::startsWith or= (prefix) ->
	return @indexOf(prefix) is 0

String::finishesWith or= (suffix) ->
	return @indexOf(suffix) is @length-1
