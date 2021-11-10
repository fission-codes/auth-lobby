__UI for [auth.fission.codes](https://auth.fission.codes)__



## How does it work?

⚗️ _This SPA allows you to:_

* Create a Fission account
* Link a Fission account from another device/browser
* Authorise an application


🔑 _For each of those, you have to pass the required query parameters:_

* `didExchange`, the exchange-key did of the user on the domain you'll be redirect to
* `didWrite`, the write-key did of the user on the domain you'll be redirect to
* `redirectTo`, the url the user will redirected to

After that, you need at least one of these resources:
* `app`, ask if the user wants to grant access to a specific Fission app (you may pass this param multiple times). You can also ask the user for access to all their apps (not their data), by setting it to `*`, this will show a warning to the user.
* `appFolder`, ask if the user wants to grant access to the private application folder.
* `privatePath`, request access to a private path (you may pass this param multiple times).
* `publicPath`, request access to a public path (you may pass this param multiple times).
* `raw`, raw UCAN resources.
* `shared`, request access to the shared section of the filesystem.

You can define some optional parameters as well:
* `lifetimeInSeconds`, how long an action should be authorised for. The default is one month.
* `newUser`, `t` or `f`, if this parameter is given and the user has not signed in before, this will pre-select the appropriate screen for the user. If `newUser` is set to `t`, it'll show the create-account screen, and if set to `f`, it'll show the sign-in (aka. link) screen. If this parameter is not given at all, the user will be able to chose themselves.
* `sdk`, the sdk version used. This is temporarily optional for backwards compatibility.
* `theme`, path or ipfs cid to a theme json file. See the [theming](#theming) section below for more info.

```shell
https://auth.fission.codes

& did=did:key:z13V3Sog2YaUKhd...
& redirectTo=https://my.app/
& sdk=0.23.0

& appFolder=Creator/My App              # `private/Apps/Creator/My App`
& privatePath=Documents/Invoices        # `private/Documents/Invoices`
& publicPath=Blog/Posts                 # `public/Blog/Posts`

& lifetimeInSeconds=86400
```


🎒 _When redirecting back it'll add the query params:_

* `username`, the username that was chosen by the user.
* `newUser`, `t` or `f`, whether the user has just created an account or not.
* `authorised`, an IPFS CID pointing to a JSON file with the following data:
  * `iv`, initialisation vector used during the AES encryption.
  * `secrets.fs`, AES encrypted json object containing private filesystem information.
  * `secrets.ucans`, AES encrypted list of tokens authorising the application to perform actions.
  * `sessionKey`, RSA encrypted AES key using [keystore-idb](https://github.com/fission-suite/keystore-idb/).

When the user decides to go back to the app for some reason (eg. not agreeing  
with the authorisation), the query parameter `cancelled=reason` will be added.

Possible cancellation reasons:
* `DENIED`, user chose to cancel the authorization



## Theming

By passing a `theme` query parameter you can adjust the look and text of the lobby. Note that when setting a custom logo, there will be a subtle reference to Fission added, to indicate that this is still a Fission service. The `theme` query param should be a URL or IPFS CID pointing to a JSON file with the following format:

```json
{
  "introduction": "MARKDOWN",
  "logo": {
    "dark-scheme": "URL_TO_IMAGE_OR_CID",
    "light-scheme": "URL_TO_IMAGE_OR_CID",
    "styles": "OPTIONAL_CSS"
  }
}
```

So for example:

```json
{
  "introduction": "Learn more about Fission on our [website](https://fission.codes).",
  "logo": {
    "dark-scheme": "https://auth.fission.codes/images/logo-light-colored.svg",
    "light-scheme": "https://auth.fission.codes/images/logo-dark-colored.svg",
    "styles": "width: 120px; padding-bottom: 10px"
  }
}
```



## Shared IPFS Worker

An IPFS worker is built along side this auth lobby.  
You can use it as follows:

```js
import IpfsMessagePortClient from "ipfs-message-port-client"

const worker = new SharedWorker("http://auth.fission.codes/worker.min.js", { type: "module" })
const ipfs = IpfsMessagePortClient.from(worker.port)
```



## Development

This project uses Nix to manage the project's environment. If you'd like to build this project without Nix, check out the dependencies in the `shell.nix` file (most are available through Homebrew as well).

```shell
# Install javascript dependencies
just install-deps

# Build, serve, watch
just

# Production build
# (see Justfile for details)
just production-build

# Use a different config
just config=production
```
