dist:
	@mkdir dist
	@coffee -o dist -c lib/collector.coffee lib/client.coffee lib/applyOp.coffee lib/normalizePayload.coffee lib/util.coffee lib/main.coffee
	@node_modules/.bin/lodash exports=commonjs include=find,extend,clone,without,pick,keys -o dist/lodash.js
	@cp node_modules/minimatch/minimatch.js dist/minimatch.js

build: components dist
	@component build --standalone Particle
	@mv build/build.js particle.js
	@rm -rf build
	@node_modules/.bin/uglifyjs -nc --unsafe -mt -o particle.min.js particle.js
	@echo "File size (minified): " && cat particle.min.js | wc -c
	@echo "File size (gzipped): " && cat particle.min.js | gzip -9f  | wc -c

components: component.json
	@component install --dev

clean:
	rm -rf build components dist

.PHONY: clean
