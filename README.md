__UI for [auth.fission.codes](https://auth.fission.codes)__



## How does it work?

⚗️ _This SPA allows you to:_

* Create a Fission account
* Link a Fission account from another device/browser
* Authorise an application


🔑 _For each of those, you have to pass the required query parameters:_

* `did`, the did of the user on the domain you'll be redirect to
* `redirectTo`, the url the user will redirected to

You can define some optional parameters as well:
* `preferredPage`, `create` or `link`, only works when user is not "signed in"


🎒_When redirecting back it'll add the query params:_

* `newUser`, `t` or `f`, whether the user has just created an account or not
* `ucan`, a token authorising the application to perform actions
* `username`, the username that was chosen by the user

When the user decides to go back to the app for some reason (eg. not agreeing  
with the authorisation), the query parameter `cancelled=reason` will be added.



## Development

* [Node v14+](https://nodejs.org/)
* [PNPM](https://pnpm.js.org/)

```shell
just install-deps
just dev-build

# Build, serve & watch
# (requires watchexec & devd)
just
```
