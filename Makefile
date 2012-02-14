# If you change something here, be sure to change it in package.json's scripts as well

test:
	./node_modules/.bin/mocha --reporter spec --ui bdd --ignore-leaks --growl

install:
	./bin/docpad install

.PHONY: test install