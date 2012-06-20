# If you change something here, be sure to change it in package.json's scripts as well

dev:
	./node_modules/.bin/coffee -w -o out/ -c src/

compile:
	./node_modules/.bin/coffee -o out/ -c src/

debug:
	cd test; node --debug-brk ../bin/docpad run

test:
	make clean
	make compile
	npm test

install:
	node ./bin/docpad install

clean:
	rm -Rf lib node_modules/ npm-debug.log test/node_modules test/out
	npm install

publish:
	make clean
	npm publish

.PHONY: dev compile test install clean publish