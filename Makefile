# If you change something here, be sure to change it in package.json's scripts as well

test:
	node ./node_modules/mocha/bin/mocha  --reporter spec  --ui bdd  --ignore-leaks  --growl

install:
	coffee ./bin/docpad install

clean:
	rm -Rf node_modules/ npm-debug.log lib/exchange/plugins/*/node_modules lib/exchange/plugins/*/npm-debug.log

.PHONY: test install clean