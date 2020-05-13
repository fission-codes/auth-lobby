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


@dev-build: clean css-large elm html js


@dev-server:
	echo "🤵  Putting up a server for ya"
	devd --livewatch --quiet build


@html:
	echo "📄  Copying static HTML files"
	cp {{src_dir}}/Main.html {{dist_dir}}/index.html


@js:
	echo "📄  Copying static JS files"
	cp {{src_dir}}/Main.js {{dist_dir}}/index.js


@production-build: css-small production-elm html js




# CSS
# ---

dist_css := dist_dir + "/stylesheet.css"
main_css := src_dir + "/Main.css"


@css-large:
	echo "⚙️  Compiling CSS"
	pnpx etc {{main_css}} \
		--config tailwind.config.js \
		--elm-path src/Tailwind.elm \
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
main_elm := src_dir + "/Main.elm"

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
