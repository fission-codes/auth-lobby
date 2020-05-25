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
  // app.ports.linkApp.subscribe(linkApp)
}


async function checkIfUsernameIsAvailable(username) {
  if (sdk.user.isUsernameValid(username)) {
    const isAvailable = await sdk.user.isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(args) {
  let response

  try {
    response = await sdk.user.createAccount(args)
  } catch (err) {
    console.error(err)
    response = { status: 500 }
  }

  if (response.status < 300) {
    localStorage.setItem("usedUsername", args.username)

    app.ports.gotCreateAccountSuccess.send(
      { ucan: args.did ? await makeUcan(args.did) : null }
    )

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
}


async function linkApp({ did }) {
  app.ports.gotUcanForApplication.send(
    { ucan: await makeUcan(did) }
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
    // jsIpfs: "./web_modules/ipfs.js" (TODO)
  })

  sdk.ipfs.setIpfs(ipfs)

  return null
}



// UCAN
// ====

async function makeUcan(externalDID) {
  return await sdk.user.ucan({
    audience: externalDID,
    issuer: await sdk.user.didKey(),

    // User is signed into the app for 1 month
    lifetimeInSeconds: 60 * 60 * 24 * 30,
  })
}
