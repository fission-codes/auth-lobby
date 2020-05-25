__UI for [auth.fission.codes](https://auth.fission.codes)__


## How does it work?

🧙‍♀️ _This SPA allows you to:_
* Create a Fission account
* Link a Fission account from another device/browser
* Authorise an application

🌓 _For each of those, you have two options:_
* Redirecting back to a Fission-enabled application:
  ```
  https://auth.fission.codes
    ?did=USER_DID_KEY_FROM_APP
    &redirectTo=https://drive.fission.codes
  ```

  When redirecting back it'll add the query params:
  + `ucan`, a token authorising the application to perform actions
  + `username`, the username that was chosen by the user

  Note that you don't have to, and can't, define what action  
  the user is taking. The application knows if the user has  
  created an account or linked another account before. Based  
  on that it'll show either the screen to create/link an account,  
  or go straight to the authorise-this-application screen.

* When you don't provide the `redirectTo` query parameter,  
  the user will be redirect to `https://chosen_username.fission.app?ucan=…`.


✋ When the user decides to go back to the app for some reason (eg. not agreeing  
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
