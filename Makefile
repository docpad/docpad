# If you change something here, be sure to change it in package.json's scripts as well

test:
	node ./node_modules/mocha/bin/mocha  --reporter spec  --ui bdd  --ignore-leaks  --growl

install:
	coffee ./bin/docpad install

.PHONY: test install