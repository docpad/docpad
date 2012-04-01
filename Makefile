# If you change something here, be sure to change it in package.json's scripts as well

test:
	make clean
	node ./node_modules/mocha/bin/mocha

install:
	coffee ./bin/docpad install

clean:
	rm -Rf node_modules/ npm-debug.log lib/exchange/skeletons lib/exchange/plugins/*/node_modules lib/exchange/plugins/*/npm-debug.log
	npm install

publish:
	make clean
	npm publish

.PHONY: test install clean publish