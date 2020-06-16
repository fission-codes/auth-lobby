/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

const apiEndpoint = "https://runfission.net"
const dataRootDomain = "fissionuser.net"

const sdk = fissionSdk

let app
let ipfs


// 🚀


bootElm().then(_ => {
  return sdk.ipfs.getIpfs({
    permissions: [
      "id",
      "swarm.connect",
      "version",
    ],

    jsIpfs: "./web_modules/ipfs.min.js"
  })

}).then(i => {
  ipfs = i

})



// ELM
// ===

async function bootElm() {
  const usedUsername = localStorage.getItem("usedUsername")

  app = Elm.Main.init({
    flags: {
      dataRootDomain,
      url: location.href,
      usedUsername
    }
  })

  ports()
}



// ELM PORTS
// ---------


function ports() {
  app.ports.checkIfUsernameIsAvailable.subscribe(checkIfUsernameIsAvailable)
  app.ports.createAccount.subscribe(createAccount)
  app.ports.linkApp.subscribe(linkApp)
}


async function checkIfUsernameIsAvailable(username) {
  if (sdk.lobby.isUsernameValid(username)) {
    const isAvailable = await sdk.lobby.isUsernameAvailable(username, dataRootDomain)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(args) {
  const { success } = await sdk.lobby.createAccount(args, { apiEndpoint })

  if (success) {
    localStorage.setItem("usedUsername", args.username)

    app.ports.gotCreateAccountSuccess.send(
      null
    )

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
}


async function linkApp({ did }) {
  app.ports.gotUcanForApplication.send(
    { ucan: await sdk.lobby.makeRootUcan(did) }
  )
}
