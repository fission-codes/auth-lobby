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
  const usedKeyPair = localStorage.getItem("usedKeyPair") === "t"

  app = Elm.Main.init({
    flags: { usedKeyPair }
  })

  ports()
}



// ELM PORTS
// ---------


function ports() {
  app.ports.checkIfUsernameIsAvailable.subscribe(checkIfUsernameIsAvailable)
  app.ports.createAccount.subscribe(createAccount)
}


async function checkIfUsernameIsAvailable(username) {
  if (sdk.user.isUsernameValid(username)) {
    const isAvailable = await sdk.user.isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(userProps) {
  let response

  try {
    response = await sdk.user.createAccount(userProps, api.endpoint)
  } catch (_) {
    response = { status: 500 }
  }

  if (response.status < 300) {
    const username = userProps.username

    localStorage.setItem("usedKeyPair", "t")

    app.ports.gotCreateAccountSuccess.send({
      username
    })

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
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
    // jsIpfs: "./web_modules/ipfs.js" (TODO)
  })

  sdk.ipfs.setIpfs(ipfs)

  return null
}
