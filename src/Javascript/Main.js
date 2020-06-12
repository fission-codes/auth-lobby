/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

const PEER_WSS = "/dns4/node.fission.systems/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const PEER_TCP = "/ip4/3.215.160.238/tcp/4001/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const sdk = fissionSdk

let app
let ipfs
let ks


// 🚀


bootElm()



// ELM
// ===

async function bootElm() {
  const usedUsername = localStorage.getItem("usedUsername")

  app = Elm.Main.init({
    flags: {
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
    const isAvailable = await isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function isUsernameAvailable(username) {
  try {
    const resp = await fetch(
      `https://${username}.fission.name`,
      { method: "HEAD", mode: "no-cors" }
    )
    return resp.status >= 300
  } catch (_) {
    return true
  }
}


async function createAccount(args) {
  let response

  try {
    response = await sdk.lobby.createAccount(args)
  } catch (err) {
    console.error(err)
    response = { status: 500 }
  }

  if (response.status < 300) {
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



// IPFS
// ====

async function bootIpfs() {
  ipfs = await getIpfs.default({
    permissions: [
      "id",
      "swarm.connect",
      "version",
    ],

    browserPeers: [ PEER_WSS ],
    localPeers: [ PEER_TCP ],
    jsIpfs: "./web_modules/ipfs.min.js"
  })

  sdk.ipfs.setIpfs(ipfs)

  return null
}
