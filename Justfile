export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

config         := "default"
dist_dir       := "./build"
fission_cmd    := "fission"
node_bin       := "./node_modules/.bin"
src_dir        := "./src"
workbox_config := "workbox.config.cjs"


# Tasks
# -----

@default: dev-build
	just dev-server & just watch


# ---


@apply-config: insert-variables
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
	simple-http-server --port 8001 --try-file build/index.html --cors --index --nocache --silent -- build


@html:
	echo "📄  Copying static HTML files"
	mkdir -p {{dist_dir}}/ipfs/
	mkdir -p {{dist_dir}}/reset/

	cp {{src_dir}}/Static/Html/Main.html {{dist_dir}}/index.html
	cp {{src_dir}}/Static/Html/Exchange.html {{dist_dir}}/exchange.html
	cp {{src_dir}}/Static/Html/Reset.html {{dist_dir}}/reset/index.html


@images:
	echo "🌄  Copying images"
	npx copy-fission-images {{dist_dir}}/images/
	rsync -r {{src_dir}}/Static/Images/ {{dist_dir}}/images/


insert-variables:
	#!/usr/bin/env node
	console.log("🎛  Inserting variables")

	const fs = require("fs")

	// Version
	const html = fs.readFileSync("{{dist_dir}}/index.html", { encoding: "utf8" })
	const work = fs.readFileSync("{{workbox_config}}", { encoding: "utf8" })
	const timestamp = Math.floor(Date.now() / 1000).toString()

	fs.writeFileSync("{{dist_dir}}/index.html", html.replace("UNIX_TIMESTAMP", timestamp))
	fs.writeFileSync("{{dist_dir}}/{{workbox_config}}", work.replace("UNIX_TIMESTAMP", timestamp))


@install-deps:
	echo "🦕  Downloading dependencies"
	npm install


@js:
	echo "📄  Copying JS files"

	{{node_bin}}/esbuild \
		--bundle \
		--format=esm \
		--outfile={{dist_dir}}/index.min.js \
		{{src_dir}}/Javascript/main.ts

	{{node_bin}}/esbuild \
		--bundle \
		--format=esm \
		--outfile={{dist_dir}}/reset.min.js \
		{{src_dir}}/Javascript/reset.ts


@minify-js:
	echo "⚙️  Minifying Javascript Files"
	{{node_bin}}/terser-dir \
		{{dist_dir}} \
		--each --extension .js \
		--pattern "*.js, !**/*.min.js" \
		--pseparator ", " \
		--output {{dist_dir}} \
		-- --compress --mangle


@production-build:
	just config=production build


@staging-build:
	just config=default build


@build:
	just config={{config}} clean css-large translate-schemas production-elm html css-small js images static minify-js
	just config={{config}} apply-config production-service-worker


@static:
	echo "⛰  Copying some more static files"
	rsync -r {{src_dir}}/Static/Favicons/ {{dist_dir}}/
	rsync -r {{src_dir}}/Static/Manifests/ {{dist_dir}}/
	rsync -r {{src_dir}}/Static/Themes/ {{dist_dir}}/themes/

	npx copy-fission-fonts {{dist_dir}}/fonts/ --woff2


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
	npx etc {{main_css}} \
		--config tailwind.config.js \
		--elm-path src/Library/Tailwind.elm \
		--output {{dist_css}} \
		--post-plugin-before postcss-import
	echo ""


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production npx etc {{main_css}} \
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
	elm make {{main_elm}} --output={{dist_elm}} --debug


@production-elm:
	echo "🌳  Compiling Elm"
	elm make {{main_elm}} --output={{dist_elm}} --optimize



# Service worker
# --------------

@service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=development npx workbox generateSW {{dist_dir}}/{{workbox_config}}


@production-service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=production npx workbox generateSW {{dist_dir}}/{{workbox_config}}



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
	watchexec -p -w src -e js,ts -- just js


@watch-schemas:
	watchexec -p -w src/Schemas -e json -- just translate-schemas
