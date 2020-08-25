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
* `appFolder`, ask if the user wants to grant access to the application folders (private and public).
* `privatePath`, request access to a private path (you may pass multiple).
* `publicPath`, request access to a public path (you may pass multiple).

You can define some optional parameters as well:
* `lifetimeInSeconds`, how long an action should be authorised for. The default is one month.
* `newUser`, `t` or `f`, if this parameter is given and the user has not signed in before, this will pre-select the appropriate screen for the user. If `newUser` is set to `t`, it'll show the create-account screen, and if set to `f`, it'll show the sign-in (aka. link) screen. If this parameter is not given at all, the user will be able to chose themselves.

```shell
https://auth.fission.codes

& did=did:key:z13V3Sog2YaUKhd...
& redirectTo=https://my.app/

& appFolder=Creator/My App              # `private/Apps/Creator/My App`
& privatePath=Documents/Invoices        # `private/Documents/Invoices`
& publicPath=Blog/Posts                 # `public/Blog/Posts`

& lifetimeInSeconds=86400
```


🎒 _When redirecting back it'll add the query params:_

* `newUser`, `t` or `f`, whether the user has just created an account or not.
* `readKey`, the aes key to use with the user's file system (encrypted in url-safe base64)
* `ucans`, a list of tokens authorising the application to perform actions.  
  The tokens are separated by a comma, but make sure to decode the query parameter first.
* `username`, the username that was chosen by the user.

When the user decides to go back to the app for some reason (eg. not agreeing  
with the authorisation), the query parameter `cancelled=reason` will be added.

Possible cancellation reasons:
* `DENIED`, user chose to cancel the authorization



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
