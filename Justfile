export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

dist_dir 					:= "./build"
node_bin 					:= "./node_modules/.bin"
src_dir  					:= "./src"

default_config 		:= "config/default.json"



# Tasks
# -----

@default: dev-build
	just dev-server & just watch


# ---


@apply-config config=default_config:
	echo "🎛  Apply config `{{config}}`"
	{{node_bin}}/mustache {{config}} {{dist_dir}}/index.html > {{dist_dir}}/index.applied.html
	rm {{dist_dir}}/index.html
	mv {{dist_dir}}/index.applied.html {{dist_dir}}/index.html


@clean:
	rm -rf {{dist_dir}}


@dev-build: clean css-large elm html js images static apply-config


@dev-server:
	echo "🤵  Putting up a server for ya"
	echo "http://localhost:8001"
	devd --quiet build --port=8001 --all


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
	curl https://wzrd.in/debug-standalone/copy-text-to-clipboard -o web_modules/copy-text-to-clipboard.js
	curl https://unpkg.com/ipfs@0.47.0/dist/index.min.js -o web_modules/ipfs.min.js


@js:
	echo "📄  Copying JS files"
	cp -r web_modules {{dist_dir}}
	# cp node_modules/fission-sdk/index.umd.js {{dist_dir}}/web_modules/fission-sdk.js
	cp ../ts-sdk/dist/index.umd.js {{dist_dir}}/web_modules/fission-sdk.js
	cp {{src_dir}}/Javascript/Main.js {{dist_dir}}/index.js


@production-build: clean css-large production-elm css-small html js images static (apply-config "config/production.json")
	echo "⚙️  Minifying Javascript Files"
	{{node_bin}}/terser-dir \
		{{dist_dir}} \
		--each --extension .js \
		--patterns "**/*.js, !**/*.min.js" \
		--pseparator ", " \
		--output {{dist_dir}} \
		-- --compress --mangle


@static:
	echo "⛰  Copying some more static files"
	cp -r {{src_dir}}/Static/Favicons/ {{dist_dir}}
	cp -r {{src_dir}}/Static/Manifests/ {{dist_dir}}



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
		--purge-content {{dist_elm}}
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
