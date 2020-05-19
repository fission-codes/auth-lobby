export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

dist_dir := "./build"
node_bin := "./node_modules/.bin"
src_dir  := "./src"



# Tasks
# -----

@default: dev-build
	just dev-server & just watch


# ---


@clean:
	rm -rf {{dist_dir}}


@dev-build: clean css-large elm html js images


@dev-server:
	echo "🤵  Putting up a server for ya"
	devd --notfound=index.html --quiet build


@html:
	echo "📄  Copying static HTML files"
	cp {{src_dir}}/Static/Html/Main.html {{dist_dir}}/index.html


@images:
	echo "🌄  Copying images"
	cp -r node_modules/fission-kit/images/ {{dist_dir}}/images/


@install-deps:
	echo "🦕  Downloading dependencies"
	pnpm install
	mkdir -p web_modules
	curl https://unpkg.com/get-ipfs@1.2.0/dist/get-ipfs.umd.js -o web_modules/get-ipfs.js
	curl https://unpkg.com/keystore-idb@0.12.0-alpha/index.umd.js -o web_modules/keystore-idb.js


@js:
	echo "📄  Copying static JS files"
	cp -r web_modules {{dist_dir}}
	cp node_modules/fission-sdk/index.umd.js {{dist_dir}}/web_modules/fission-sdk.js
	cp {{src_dir}}/Javascript/Main.js {{dist_dir}}/index.js


@production-build: css-small production-elm html js images




# CSS
# ---

dist_css := dist_dir + "/stylesheet.css"
main_css := src_dir + "/Css/Main.css"


@css-large:
	echo "⚙️  Compiling CSS"
	pnpx etc {{main_css}} \
		--config tailwind.config.js \
		--elm-path src/Library/Tailwind.elm \
		--output {{dist_css}}
	echo ""


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production pnpx etc {{main_css}} \
		--config tailwind.config.js \
		--output {{dist_css}} \
		--purge-content ./build/javascript.js
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



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-elm & \
	just watch-html & \
	just watch-js


@watch-css:
	watchexec -p -w . -f "**/*.css" -f "*/tailwind.config.js" -i build -- just css-large


@watch-elm:
	watchexec -p -w src -e elm -- just elm


@watch-js:
	watchexec -p -w src -e js -- just js


@watch-html:
	watchexec -p -w src -e html -- just html
