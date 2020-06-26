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
  app.ports.linkedDevice.subscribe(linkedDevice)
  app.ports.openSecureChannel.subscribe(openSecureChannel)
  app.ports.publishOnSecureChannel.subscribe(publishOnSecureChannel)
  app.ports.publishEncryptedOnSecureChannel.subscribe(publishEncryptedOnSecureChannel)
}


// IPFS
// ----

async function bootIpfs() {
  ipfs = await Ipfs.create({
    config: {
      Addresses: {
        Swarm: [
          // https://wrtc-star1.par.dwebops.pub/
          // https://wrtc-star2.sjc.dwebops.pub/
          // "/dns4/wrtc-star1.par.dwebops.pub/tcp/443/wss/p2p-webrtc-star/",

          // Our server
          "/dns4/frozen-wave-01607.herokuapp.com/tcp/443/wss/p2p-webrtc-star/",

          // "/ip4/127.0.0.1/tcp/9090/ws/p2p-webrtc-star/",
          // "/ip4/127.0.0.1/tcp/0"
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
  const ucan = await sdk.core.ucan({
    audience: did,
    issuer: await rootDid(),
    lifetimeInSeconds: 60 * 60 * 24 * 30 // one month,
  })

  app.ports.gotUcanForApplication.send(
    { ucan }
  )
}


/**
 * You got linked 🎢
 */
function linkedDevice({ ucan, username }) {
  localStorage.setItem("ucan", ucan)
  localStorage.setItem("usedUsername", username)

  app.ports.gotLinked.send({ username })
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

  if (!rootDid_) {
    app.ports.gotInvalidRootDid.send(null)
    return
  }

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


async function publishOnSecureChannel([ maybeUsername, dataWithPlaceholders ]) {
  ipfs.pubsub.publish(
    await rootDid(maybeUsername),
    await prepareData(dataWithPlaceholders)
  )
}


async function publishEncryptedOnSecureChannel([ maybeUsername, didKeyOtherSide, dataWithPlaceholders ]) {
  ipfs.pubsub.publish(
    await rootDid(maybeUsername),
    await encrypt(
      await prepareData(
        dataWithPlaceholders,
        maybeUsername,
        didKeyOtherSide
      ),
      didKeyOtherSide
    )
  )
}


  async function prepareData(dataWithPlaceholders, maybeUsername, didKeyOtherSide) {
    let ks

    // Check
    if (typeof dataWithPlaceholders === "string") {
      return dataWithPlaceholders
    }

    // Placeholders
    let plaDid        = dataWithPlaceholders.did !== undefined
    let plaSignature  = dataWithPlaceholders.signature !== undefined
    let plaUcan       = dataWithPlaceholders.ucan !== undefined

    // Payload
    const payload = {
      ...dataWithPlaceholders,

      // DID
      did: plaDid
        ? await sdk.core.did()
        : undefined,

      // UCAN
      ucan: plaUcan
        ? await sdk.core.ucan({
            audience: didKeyOtherSide,
            issuer: await sdk.core.did(),
            lifetimeInSeconds: 60 * 60 * 24 * 30 * 12, // one year
            proof: localStorage.getItem("ucan")
          })
        : undefined
    }

    // Load keystore if needed
    if (plaSignature) {
      delete payload.signature
      ks = await sdk.keystore.get()
    }

    // Put signature in place if needed
    const data = {
      ...payload,

      signature: plaSignature ? await ks.sign(payload) : undefined,
    }

    // Return
    return JSON.stringify(data)
  }


function secureChannelMessage(rootDid_, ipfsId) { return async function({ from, data }) {
  const string = data.toString()

  if (from === ipfsId) {
    return

  } else if (string === "CANCEL") {
    ipfs.pubsub.unsubscribe(rootDid_)
    app.ports.cancelLink.send(null)

  } else if (string === "PING") {
    ipfs.pubsub.publish(rootDid_, "PONG")

  } else if (string === "PONG") {
    clearInterval(pingInterval)
    app.ports.secureChannelOpened.send(null)

  } else if (string[0] === "{") {
    gotSecureChannelMessage(from, string)

  } else {
    const decryptedString = await decrypt(string, await sdk.core.did())
    gotSecureChannelMessage(from, decryptedString)

  }
}}


  function gotSecureChannelMessage(from, string) {
    const obj = JSON.parse(string)

    if (obj.did && obj.signature) {
      // TODO: Confirm signature
    }

    app.ports.gotSecureChannelMessage.send({
      ...obj,
      from,
      timestamp: Date.now(),
    })
  }



// CRYPTO
// ------

async function encrypt(string, passphrase) {
  const key = await keyFromPassphrase(passphrase)

  const iv = crypto.getRandomValues(new Uint8Array(12)).buffer
  const buf = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: iv,
      tagLength: 128
    },
    key,
    stringToArrayBuffer(string)
  )

  const iv_b64 = arrayBufferToBase64(iv)
  const buf_b64 = arrayBufferToBase64(buf)

  return iv_b64 + buf_b64
}


async function decrypt(string, passphrase) {
  const key = await keyFromPassphrase(passphrase)

  const iv_b64 = string.substring(0, 16)
  const buf_b64 = string.substring(16)

  const iv = base64ToArrayBuffer(iv_b64)
  const buf = base64ToArrayBuffer(buf_b64)

  const decryptedBuf = await crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv: iv,
      tagLength: 128
    },
    key,
    buf
  )

  return arrayBufferToString(
    decryptedBuf
  )
}


function keyFromPassphrase(passphrase) {
  return crypto.subtle.importKey(
    "raw",
    stringToArrayBuffer(passphrase),
    {
      name: "PBKDF2"
    },
    false,
    [ "deriveKey" ]

  ).then(baseKey => crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: stringToArrayBuffer("fission"),
      iterations: 10000,
      hash: "SHA-512"
    },
    baseKey,
    {
      name: "AES-GCM",
      length: 256
    },
    false,
    [ "encrypt", "decrypt" ]

  ))
}


function arrayBufferToBase64(buf) {
  return btoa(
    Array
      .from(new Uint8Array(buf))
      .map(c => String.fromCharCode(c))
      .join("")
  )
}


function arrayBufferToString(buf) {
  return new TextDecoder().decode(buf)
}


function base64ToArrayBuffer(b64) {
  return new Uint8Array(
    atob(b64)
      .split("")
      .map(c => c.charCodeAt(0))
  ).buffer
}


function stringToArrayBuffer(str) {
  return new TextEncoder().encode(str).buffer
}
