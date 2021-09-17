export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

config						:= "default"
dist_dir 					:= "./build"
fission_cmd       := "fission"
node_bin 					:= "./node_modules/.bin"
src_dir  					:= "./src"
workbox_config 		:= "workbox.config.cjs"


# Tasks
# -----

@default: dev-build
	just dev-server & just watch


# ---


@apply-config: insert-version
	echo "🎛  Applying config \`config/{{config}}.json\`"
	{{node_bin}}/mustache config/{{config}}.json {{dist_dir}}/index.html > {{dist_dir}}/index.applied.html
	rm {{dist_dir}}/index.html
	mv {{dist_dir}}/index.applied.html {{dist_dir}}/index.html


@clean:
	rm -rf {{dist_dir}}
	mkdir -p {{dist_dir}}


@dev-build: clean css-large translate-schemas elm html js images static apply-config service-worker
	echo {{config}} &> /dev/null


@dev-server:
	echo "🤵  Putting up a server for ya"
	echo "http://localhost:8001"
	devd --quiet build --port=8001 --all


@download-web-module filename url:
	curl --silent --show-error --fail -o web_modules/{{filename}} {{url}}


@html:
	echo "📄  Copying static HTML files"
	mkdir -p {{dist_dir}}/reset/

	cp {{src_dir}}/Static/Html/Main.html {{dist_dir}}/index.html
	cp {{src_dir}}/Static/Html/Ipfs.html {{dist_dir}}/ipfs.html
	cp {{src_dir}}/Static/Html/Exchange.html {{dist_dir}}/exchange.html
	cp {{src_dir}}/Static/Html/Reset.html {{dist_dir}}/reset/index.html


@images:
	echo "🌄  Copying images"
	pnpx copy-fission-images {{dist_dir}}/images/
	cp -RT {{src_dir}}/Static/Images/ {{dist_dir}}/images/


insert-version:
	#!/usr/bin/env node
	const fs = require("fs")
	const html = fs.readFileSync("{{dist_dir}}/index.html", { encoding: "utf8" })
	const work = fs.readFileSync("{{workbox_config}}", { encoding: "utf8" })
	const timestamp = Math.floor(Date.now() / 1000).toString()

	fs.writeFileSync("{{dist_dir}}/index.html", html.replace("UNIX_TIMESTAMP", timestamp))
	fs.writeFileSync("{{dist_dir}}/{{workbox_config}}", work.replace("UNIX_TIMESTAMP", timestamp))


@install-deps:
	echo "🦕  Downloading dependencies"
	pnpm install
	rm -rf web_modules
	mkdir -p web_modules
	cp ./node_modules/webnative/dist/index.umd.min.js web_modules/webnative.min.js

	just download-web-module localforage.min.js https://cdnjs.cloudflare.com/ajax/libs/localforage/1.9.0/localforage.min.js
	just download-web-module ipfs.min.js https://unpkg.com/ipfs@0.54.4/dist/index.min.js


@js:
	echo "📄  Copying JS files"
	rm -rf {{dist_dir}}/web_modules
	cp -rf web_modules {{dist_dir}}/web_modules
	cp {{src_dir}}/Javascript/Main.js {{dist_dir}}/index.js
	{{node_bin}}/esbuild \
		--bundle \
		--define:API_ENDPOINT="$(jq .API_ENDPOINT config/{{config}}.json)" \
		--outfile={{dist_dir}}/worker.min.js \
		{{src_dir}}/Javascript/Worker.js


@minify-js:
	echo "⚙️  Minifying Javascript Files"
	{{node_bin}}/terser-dir \
		{{dist_dir}} \
		--each --extension .js \
		--pattern "**/*.js, !**/*.min.js" \
		--pseparator ", " \
		--output {{dist_dir}} \
		-- --compress --mangle


@production-build:
	just config=production clean css-large translate-schemas production-elm html css-small js images static minify-js
	just config=production apply-config production-service-worker


@staging-build:
	just config=default clean css-large translate-schemas production-elm html css-small js images static minify-js
	just config=default apply-config production-service-worker


@static:
	echo "⛰  Copying some more static files"
	cp -RT {{src_dir}}/Static/Favicons/ {{dist_dir}}/
	cp -RT {{src_dir}}/Static/Manifests/ {{dist_dir}}/
	cp -RT {{src_dir}}/Static/Themes/ {{dist_dir}}/themes/

	pnpx copy-fission-fonts {{dist_dir}}/fonts/ --woff2


@translate-schemas:
	echo "🔮  Translating schemas into Elm code"
	./node_modules/quicktype/dist/cli/index.js -s schema -o src/Library/Theme.elm --module Theme src/Schemas/Dawn/Theme.json
	elm-format src/Library/Theme.elm --yes



# CSS
# ---

dist_css := dist_dir + "/stylesheet.css"
main_css := src_dir + "/Css/Main.css"


@css-large:
	echo "⚙️  Compiling CSS"
	pnpx etc {{main_css}} \
		--config tailwind.config.js \
		--elm-path src/Library/Tailwind.elm \
		--output {{dist_css}} \
		--post-plugin-before postcss-import
	echo ""


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production pnpx etc {{main_css}} \
		--config tailwind.config.js \
		--output {{dist_css}} \
		--purge-content={{dist_elm}} \
		--purge-content={{dist_dir}}/index.html \
		--purge-content={{dist_dir}}/reset/index.html \
		--post-plugin-before postcss-import
	echo ""



# Elm
# ---

dist_elm := dist_dir + "/elm.js"
main_elm := src_dir + "/Application/Main.elm"

@elm:
	echo "🌳  Compiling Elm"
	elm make {{main_elm}} --output={{dist_elm}}


@production-elm:
	echo "🌳  Compiling Elm"
	elm make {{main_elm}} --output={{dist_elm}} --optimize



# Service worker
# --------------

@service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=development pnpx workbox generateSW {{dist_dir}}/{{workbox_config}}


@production-service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=production pnpx workbox generateSW {{dist_dir}}/{{workbox_config}}



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-elm & \
	just watch-html & \
	just watch-js & \
	just watch-schemas


@watch-css:
	watchexec -p -w . -f "**/*.css" -f "*/tailwind.config.js" -i build -- just css-large


@watch-elm:
	watchexec -p -w src -e elm -- just elm


@watch-html:
	watchexec -p -w src -e html -- just html apply-config


@watch-js:
	watchexec -p -w src -e js -- just js


@watch-schemas:
	watchexec -p -w src/Schemas -e json -- just translate-schemas
