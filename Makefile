# If you change something here, be sure to change it in package.json's scripts as well

dev:
	./node_modules/.bin/coffee -w -o out/ -c src/

compile:
	./node_modules/.bin/coffee -o out/ -c src/

debug:
	cd test; node --debug-brk ../bin/docpad run

test-clean:
	rm -Rf test/node_modules test/out

test-prepare:
	make test-clean
	make compile

test:
	make test-prepare
	npm test

install:
	node ./bin/docpad install

clean:
	rm -Rf lib node_modules/ npm-debug.log
	make test-clean
	npm install

publish:
	make clean
	npm publish

.PHONY: dev compile test-clean test-prepare test install clean publish