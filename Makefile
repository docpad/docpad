test:
	./node_modules/.bin/mocha \
		--reporter spec \
		--ui bdd \
		--ignore-leaks \
		--growl

.PHONY: test