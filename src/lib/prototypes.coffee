String::explode or= ->
	@.split(/[,\s]+/g)

Array::remove or= (from, to) ->
	rest = @slice((to or from) + 1 or @length)
	@length = (if from < 0 then @length + from else from)
	@push.apply(this,rest)

Date::toShortDateString or= ->
	return @toDateString().replace(/^[^\s]+\s/,'')

Date::toISODateString or= Date::toISOString