/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

const sdk = fissionSdk

const API_ENDPOINT = "https://runfission.net"
const DATA_ROOT_DOMAIN = "fissionuser.net"

let app
let ipfs


// 🚀


bootIpfs().then(bootElm)


// ELM
// ---

async function bootElm() {
  const usedUsername = localStorage.getItem("usedUsername")

  app = Elm.Main.init({
    flags: {
      dataRootDomain: DATA_ROOT_DOMAIN,
      url: location.href,
      usedUsername
    }
  })

  ports()
}


function ports() {
  app.ports.checkIfUsernameIsAvailable.subscribe(checkIfUsernameIsAvailable)
  app.ports.createAccount.subscribe(createAccount)
  app.ports.linkApp.subscribe(linkApp)
  app.ports.openSecureChannel.subscribe(openSecureChannel)
  app.ports.publishOnSecureChannel.subscribe(publishOnSecureChannel)
}


// IPFS
// ----

async function bootIpfs() {
  ipfs = await Ipfs.create({
    config: {
      Addresses: {
        Swarm: [
          "/ip4/0.0.0.0/tcp/9090/ws/p2p-webrtc-star/",
          // "/dns4/node.fission.systems/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
        ]
      }
    }
  })

  await sdk.ipfs.setIpfs(ipfs)
}



// ACCOUNT
// =======

let rootDidCache

/**
 * Get the root DID for a user.
 *
 * That might be the DID of this domain/device,
 * it could be another DID from a UCAN,
 * or it might be that we need to look this up.
 *
 * The only way we get a UCAN in this lobby,
 * is to link this domain/device to another one.
 */
async function rootDid(maybeUsername) {
  let ucan

  if (rootDidCache) {
    null
  } else if (maybeUsername) {
    rootDidCache = await sdk.dns.lookupTxtRecord(`_did.${maybeUsername}.${DATA_ROOT_DOMAIN}`)
  } else if (ucan = localStorage.getItem("ucan")) {
    rootDidCache = sdk.core.ucanRootIssuer(ucan)
  } else {
    rootDidCache = await sdk.core.did()
  }

  return rootDidCache
}


// CREATE
// ------

async function checkIfUsernameIsAvailable(username) {
  if (sdk.lobby.isUsernameValid(username)) {
    const isAvailable = await sdk.lobby.isUsernameAvailable(username, DATA_ROOT_DOMAIN)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(args) {
  const { success } = await sdk.lobby.createAccount(args, { apiEndpoint: API_ENDPOINT })

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


// LINK
// ----

async function linkApp({ did }) {
  const ucan = await core.ucan({
    audience: did,
    issuer: await rootDid(),
    lifetimeInSeconds: 60 * 60 * 24 * 30 // one month,
  })

  app.ports.gotUcanForApplication.send(
    { ucan }
  )
}



// SECURE CHANNEL
// ==============

let pingInterval


/**
 * Tries to subscribe to a pubsub channel
 * with the root DID as the topic.
 *
 * If it succeeds, it'll call the `secureChannelOpened` port,
 * otherwise the `secureChannelTimeout` port will called.
 */
async function openSecureChannel(maybeUsername) {
  const rootDid_ = await rootDid(maybeUsername)
  const ipfsId = (await ipfs.id()).id

  await ipfs.pubsub.subscribe(
    rootDid_,
    secureChannelMessage(rootDid_, ipfsId)
  )

  if (maybeUsername) {
    pingInterval = setInterval(
      () => ipfs.pubsub.publish(rootDid_, "PING"),
      500
    )
  }
}


function secureChannelMessage(rootDid_, ipfsId) { return async function({ from, data }) {
  const string = new TextDecoder().decode(data)

  if (from === ipfsId) {
    return

  } else if (string === "PING") {
    ipfs.pubsub.publish(rootDid_, "PONG")

  } else if (string === "PONG") {
    clearInterval(pingInterval)
    app.ports.secureChannelOpened.send(null)

  } else {
    try {
      const decodedJson = JSON.parse(string)

      app.ports.gotSecureChannelMessage.send({
        ...decodedJson,
        from,
        timestamp: Date.now(),
      })
    } catch (_) {
      // Invalid JSON
      // Ignore message
    }

  }
}}


async function publishOnSecureChannel([ maybeUsername, dataWithPlaceholders ]) {
  const payloadToSign = dataWithPlaceholders.signature
    ? { ...dataWithPlaceholders }
    : {}

  delete payloadToSign.signature

  // Replace placeholders
  const data = {
    ...dataWithPlaceholders,
    did: dataWithPlaceholders.did ? await sdk.core.did() : undefined,
    signature: dataWithPlaceholders.signature ? await ks.sign(payloadToSign) : undefined,
  }

  // Publish message
  await ipfs.pubsub.publish(
    await rootDid(maybeUsername),
    JSON.stringify(data)
  )
}
