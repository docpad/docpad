String::explode or= ->
	@.split(/[,\s]+/g)

Date::toShortDateString or= ->
	return @toDateString().replace(/^[^\s]+\s/,'')

Date::toISODateString or= Date::toISOString