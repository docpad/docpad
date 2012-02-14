test:
	./node_modules/.bin/mocha \
		--reporter spec \
		--ui bdd \
		--ignore-leaks \
		--growl

install:
	./bin/docpad install

.PHONY: test install