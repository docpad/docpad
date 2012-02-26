# If you change something here, be sure to change it in package.json's scripts as well

test:
	node ./node_modules/mocha/bin/mocha  --reporter spec  --ui bdd  --ignore-leaks  --growl

test-debug:
	node ./node_modules/mocha/bin/mocha  --reporter spec  --ui bdd  --ignore-leaks  --growl  -d

install:
	coffee ./bin/docpad install

clean:
	rm -Rf node_modules/ npm-debug.log lib/exchange/skeletons lib/exchange/plugins/*/node_modules lib/exchange/plugins/*/npm-debug.log
	npm install

.PHONY: test test-debug install clean