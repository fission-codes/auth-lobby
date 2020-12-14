/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

const wn = webnative

let app
let ipfs


// 🚀


wn.setup.endpoints({
  api: API_ENDPOINT,
  lobby: location.origin,
  user: DATA_ROOT_DOMAIN
})


bootIpfs().then(bootElm)


// ELM
// ---

async function bootElm() {
  const usedUsername = await localforage.getItem("usedUsername")

  app = Elm.Main.init({
    flags: {
      dataRootDomain: DATA_ROOT_DOMAIN,
      url: location.href,
      usedUsername,
      version: VERSION
    }
  })

  ports()
}


function ports() {
  app.ports.checkIfUsernameIsAvailable.subscribe(checkIfUsernameIsAvailable)
  app.ports.closeChannel.subscribe(closeChannel)
  app.ports.copyToClipboard.subscribe(copyToClipboard)
  app.ports.createAccount.subscribe(createAccount)
  app.ports.leave.subscribe(leave)
  app.ports.linkApp.subscribe(linkApp)
  app.ports.linkedDevice.subscribe(linkedDevice)
  app.ports.openChannel.subscribe(openChannel)

  // Better error reporting for async things
  app.ports.publishOnChannel.subscribe(
    a => publishOnChannel(a).catch(console.error)
  )
}


// IPFS
// ----

async function bootIpfs() {
  ipfs = await Ipfs.create({
    config: {
      Bootstrap: [
        RELAY
      ],
      Addresses: {
        Swarm: [
          SIGNALING_ADDR
        ]
      }
    },
    preload: {
      enabled: false,
      addresses: []
    },
    relay: {
      enabled: true,
      hop: {
        enabled: true,
        active: true
      }
    },
    init: {
      repo: "ipfs-1594230086172",
      repoAutoMigrate: true
    }
  })

  wn.ipfs.set(ipfs)

  // ipfs.libp2p.connectionManager.on("peer:connect", (connection) => {
  //   console.log("Connected to peer", connection.remotePeer._idB58String)
  // })
  //
  // ipfs.libp2p.connectionManager.on("peer:disconnect", (connection) => {
  //   console.log("Disconnected from peer", connection.remotePeer._idB58String)
  // })

  window.i = ipfs
}



// ACCOUNT
// =======

const rootDidCache = {}

/**
 * Get the read key (aka. AES key)
 */
async function myReadKey() {
  const maybeReadKey = await localforage.getItem("readKey")
  if (maybeReadKey) return maybeReadKey

  const readKey = await wn.keystore.genKeyStr()
  await localforage.setItem("readKey", readKey)
  return readKey
}

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
async function lookupRootDid(maybeUsername) {
  let ucan, x, y

  if (maybeUsername) {
    x = maybeUsername
    y = rootDidCache[x] || (await wn.did.root(x))

  } else if (ucan = await localforage.getItem("ucan")) {
    x = "ucan"
    y = rootDidCache[x] || wn.ucan.rootIssuer(ucan)

  } else {
    x = "local"
    y = rootDidCache[x] || (await wn.did.write())

  }

  return y
}

/**
 * Remove all traces of the user.
 */
async function leave() {
  if (window.confirm("Are you sure you want to remove this device? If you're not authenticated on any other devices, you will lose access to your account!")) {
    await localforage.removeItem("readKey")
    await localforage.removeItem("ucan")
    await localforage.removeItem("usedUsername")
    await webnative.keystore.clear()

    location.reload()
  }
}


// CREATE
// ------

async function checkIfUsernameIsAvailable(username) {
  if (wn.lobby.isUsernameValid(username)) {
    const isAvailable = await wn.lobby.isUsernameAvailable(username, DATA_ROOT_DOMAIN)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(args) {
  const { success } = await wn.lobby.createAccount(
    { email: args.email, username: args.username },
    { apiEndpoint: API_ENDPOINT }
  )

  if (success) {
    await localforage.setItem("usedUsername", args.username)

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

async function linkApp({ didWrite, didExchange, attenuation, lifetimeInSeconds }) {
  const audience = didWrite
  const issuer = await wn.did.write()
  const proof = await localforage.getItem("ucan")

  const att = attenuation.map(a => {
    const [key, value] = a.resource
    return { [key]: value, "cap": a.capability }
  })

  // TODO: Waiting on API changes
  // const ucanPromise = wn.ucan.build({
  //   attenuations: [ att ],
  //   proofs: proof ? [ proof ] : [],
  //
  //   audience,
  //   issuer,
  //   lifetimeInSeconds
  // })

  const ucanPromise = wn.ucan.build({
    potency: "APPEND",
    resource: "*",

    proof: proof ? proof : undefined,

    audience,
    issuer,
    lifetimeInSeconds,
  })

  const ucans = [ await ucanPromise ]

  // encrypt symmetric key (url-safe base64)
  const plainTextReadKey = await myReadKey()
  const ks = await wn.keystore.get()
  const { publicKey } = wn.did.didToPublicKey(didExchange)
  const readKey = await ks.encrypt(plainTextReadKey, publicKey).then(makeBase64UrlSafe)

  app.ports.gotUcansForApplication.send(
    { readKey, ucans }
  )
}


/**
 * You got linked 🎢
 */
async function linkedDevice({ readKey, ucan, username }) {
  await localforage.setItem("readKey", readKey)
  await localforage.setItem("ucan", ucan)
  await localforage.setItem("usedUsername", username)

  app.ports.gotLinked.send({ username })
}



// CHANNEL
// =======

/**
 * Channel State.
 */
let cs = {}


/**
 * Tries to subscribe to a pubsub channel
 * with the root DID as the topic.
 */
async function openChannel(maybeUsername) {
  resetChannelState()

  const rootDid = await lookupRootDid(maybeUsername).catch(_ => null)
  const ipfsId = await ipfs.id().then(a => a.id)
  const topic = `deviceLink#${rootDid}`

  if (!rootDid) {
    app.ports.gotInvalidRootDid.send(null)
    return
  }

  console.log("Opening channel", topic)
  cs.topic = topic

  // Replace the following with the socket code below
  // to switch to IPFS pubsub instead of a web socket.
  // Also change the `publishOnChannel` and `closeChannel` functions.
  // ---
  // await ipfs.pubsub.subscribe(
  //   topic,
  //   channelMessage(rootDid, ipfsId)
  // )

  cs.socket = new WebSocket(`wss://runfission.net/user/link/${rootDid}`)
  cs.socket.onmessage = channelMessage(rootDid, ipfsId)
  cs.socket.onerror = () => {
    if (cs.socket.closed) return
    alert("Couldn't establish web socket")
  }
}


/**
 * 📢 Outgoing channel message
 */
async function publishOnChannel([ maybeUsername, subject, data ]) {
  const rootDid = await lookupRootDid(maybeUsername)
  const topic = `deviceLink#${rootDid}`
  // const publish = a => ipfs.pubsub.publish(topic, a)
  const publish = a => {
    if (cs.debug) console.log("Outgoing message (encrypted if needed):", a)

    const binary = typeof a === "string"
      ? stringToArrayBuffer(a)
      : a

    if (cs.debug) console.log("Outgoing message (raw):", binary)

    cs.socket.send(binary)
  }

  switch (subject) {

    ////////////////////////////////////////////
    // 🔗 INQUIRER, Pt. 2
    ////////////////////////////////////////////
    case "TEMPORARY_EXCHANGE_KEY": return await (async () => {
      cs.temporaryRsaPair = await crypto.subtle.generateKey(
        RSA_KEY_ALGO,
        true,
        [ "encrypt", "decrypt" ]
      )

      const didThrowaway = await crypto.subtle
        .exportKey("spki", cs.temporaryRsaPair.publicKey)
        .then(arrayBufferToBase64)
        .then(k => wn.did.publicKeyToDid(k, "rsa"))

      cs.pingIntervalId = setInterval(
        () => publish(didThrowaway),
        2000
      )
    })()

    ////////////////////////////////////////////
    // 🔗 AUTHORISER, Pt. 3
    ////////////////////////////////////////////
    case "SESSION_KEY": return await (async () => {
      cs.sessionKey = await crypto.subtle.generateKey(
        {
          name: "AES-GCM",
          length: 256
        },
        true,
        [ "encrypt", "decrypt" ]
      )

      const sessionKeyBuffer = await crypto.subtle.exportKey("raw", cs.sessionKey)
      const sessionKey = arrayBufferToBase64(sessionKeyBuffer)

      // Transform throwaway DID into public RSA key
      const { publicKey } = wn.did.didToPublicKey(data.didThrowaway)
      const publicCryptoKey = await crypto.subtle.importKey(
        "spki",
        base64ToArrayBuffer(publicKey),
        RSA_KEY_ALGO,
        false,
        [ "encrypt" ]
      )

      // Encode & encrypt session key
      const encryptedSessionKey = await crypto.subtle.encrypt(
        { name: "RSA-OAEP" },
        publicCryptoKey,
        sessionKeyBuffer
      )

      // Make UCAN
      const proof = await localforage.getItem("ucan")
      const ucan = await wn.ucan.build({
        issuer: await wn.did.ucan(),
        audience: data.didThrowaway,
        lifetimeInSeconds: 60 * 5, // 5 minutes
        facts: [{ sessionKey }],
        proofs: proof ? [ proof ] : []
      })

      // Encode & encrypt UCAN
      //
      // TODO: Waiting for API changes
      // const encodedUcan = wn.ucan.encode(ucan)

      const { iv, msg } = await encryptWithAes(
        stringToArrayBuffer(ucan)
      )

      // Publish
      publish(
        JSON.stringify({
          iv: arrayBufferToBase64(iv),
          msg: arrayBufferToBase64(msg),
          sessionKey: arrayBufferToBase64(encryptedSessionKey)
        })
      )
    })()

    ////////////////////////////////////////////
    // 🔗 INQUIRER, Pt. 4
    ////////////////////////////////////////////
    case "USER_CHALLENGE": return await (async () => {
      const { iv, msg } = await encryptWithAes(
        jsonBuffer({
          did: await wn.did.ucan(),
          pin: data.pin
        })
      )

      // Publish
      publish(
        JSON.stringify({
          iv: arrayBufferToBase64(iv),
          msg: arrayBufferToBase64(msg)
        })
      )
    })()

    ////////////////////////////////////////////
    // 🔗 AUTHORISER, Pt. 5
    ////////////////////////////////////////////
    case "READ_KEY_&_UCAN": return await (async () => {
      const readKey = await myReadKey()

      // UCAN
      const ucan = await wn.ucan.build({
        audience: data.didInquirer,
        issuer: await wn.did.write(),
        lifetimeInSeconds: 60 * 60 * 24 * 30 * 12 * 1000, // 1000 years
        proofs: [ await localforage.getItem("ucan") ]
      })

      // Encode & encrypt
      const { iv, msg } = await encryptWithAes(
        // TODO: Waiting for API changes
        // wn.ucan.encode(ucan)
        jsonBuffer({ readKey, ucan: ucan })
      )

      // Publish
      publish(
        JSON.stringify({
          iv: arrayBufferToBase64(iv),
          msg: arrayBufferToBase64(msg)
        })
      )

      // Reset channel state
      resetChannelState()
    })()

    ////////////////////////////////////////////
    // 🦉
    ////////////////////////////////////////////
    default:
      if (cs.sessionKey) {
        const { iv, msg } = await encryptWithAes(
          jsonBuffer(data)
        )

        publish(
          JSON.stringify({
            iv: arrayBufferToBase64(iv),
            msg: arrayBufferToBase64(msg)
          })
        )

      } else {
        publish(
          JSON.stringify(data)
        )

      }

      // Reset channel state when cancelling
      if (data.linkStatus === "DENIED") {
        resetChannelState()
      }

  }
}


/**
 * 👂 Incoming channel message
 */
function channelMessage(rootDid, ipfsId) { return async function({ from, data }) {
  const string = arrayBufferToString(data.arrayBuffer ? await data.arrayBuffer() : data)

  // Ignore our own messages, so stop here
  if (from === ipfsId) {
    return
  } else if (cs.debug) {
    console.log("Incoming message (raw):", data)
    console.log("Incoming message (transformed):", string)
  }

  // Stop interval for broadcast
  if (cs.pingIntervalId) {
    clearInterval(cs.pingIntervalId)
    cs.pingIntervalId = null
  }

  const decryptedMessagePromise = (async () => {
    ////////////////////////////////////////////
    // 🔏 (Linking, Pt. 3)
    ////////////////////////////////////////////
    if (cs.temporaryRsaPair) {
      const json = JSON.parse(string)
      const iv = base64ToArrayBuffer(json.iv)

      // Already did this?
      if (cs.sessionKey) {
        throw new Error("Already got a session key")
      }

      // Extract session key
      const rawSessionKey = await crypto.subtle.decrypt(
        {
          name: "RSA-OAEP"
        },
        cs.temporaryRsaPair.privateKey,
        base64ToArrayBuffer(json.sessionKey)
      )

      // Import session key
      const sessionKey = await crypto.subtle.importKey(
        "raw",
        rawSessionKey,
        "AES-GCM",
        false,
        [ "encrypt", "decrypt" ]
      )

      cs.sessionKey = sessionKey
      cs.temporaryRsaPair = null

      // Extract UCAN
      const encodedUcan = arrayBufferToString(await crypto.subtle.decrypt(
        {
          name: "AES-GCM",
          iv: iv
        },
        cs.sessionKey,
        base64ToArrayBuffer(json.msg)
      ))

      const ucan = wn.ucan.decode(encodedUcan)

      // TODO: (next UCAN version)
      // if (await wn.ucan.isValid(ucan) === false) {
      //   throw new Error("Invalid closed UCAN")
      // }

      if (!isValidUcan(encodedUcan)) {
        throw new Error("Invalid closed UCAN")
      }

      // TODO: (next UCAN version) Proof of closed ucan
      // if (ucan.payload.prf.length > 0 || ucan.payload.prf[0].payload.att.length === 0) {
      //   throw new Error("Invalid closed UCAN")
      // }

      if (ucan.payload.prf) {
        throw new Error("Invalid closed UCAN")
      }

      // Extract session key
      const sessionKeyFromFact = ucan.payload.fct[0] && ucan.payload.fct[0].sessionKey

      if (!sessionKeyFromFact) {
        throw new Error("Session key is missing from closed UCAN")
      }

      // Compare session keys
      const sessionKeyWeAlreadyGot = arrayBufferToBase64(rawSessionKey)

      if (sessionKeyFromFact !== sessionKeyWeAlreadyGot) {
        throw new Error("Closed UCAN session key does not match the one we already have")
      }

      // Carry on with challenge
      return Array.from(crypto.getRandomValues(
        new Uint8Array(6)
      )).map(n => {
        return n % 10
      })

    ////////////////////////////////////////////
    // 🔐 (Linking, Pt. 4+)
    ////////////////////////////////////////////
    } else if (cs.sessionKey) {
      const { iv, msg } = JSON.parse(string)

      if (!iv) {
        throw new Error("I tried to decrypt some data (with AES) but the `iv` was missing from the message")
      }

      const buffer = await crypto.subtle.decrypt(
        {
          name: "AES-GCM",
          iv: base64ToArrayBuffer(iv)
        },
        cs.sessionKey,
        base64ToArrayBuffer(msg)
      )

      return arrayBufferToString(buffer)

    ////////////////////////////////////////////
    // 🦉
    ////////////////////////////////////////////
    } else {
      return string

    }
  })()

  let decryptedMessage

  try {
    decryptedMessage = await decryptedMessagePromise
  } catch (err) {
    if (err.message.indexOf("DOMException")) {
      console.warn("Couldn't decrypt message, probably not intended for this device")
    } else {
      console.warn("Got invalid channel message")
    }

    if (cs.debug) console.warn(err)
  }

  if (!decryptedMessage) return
  else if (cs.debug) console.log("Incoming message (decrypted):", decryptedMessage)

  // Determine message structure
  const probablyJson = (
    typeof decryptedMessage === "string" && decryptedMessage.indexOf("{") === 0
  )

  const obj = probablyJson
    ? JSON.parse(decryptedMessage)
    : { msg: decryptedMessage }

  // ACT ON MESSAGE
  // Either:
  // * Cancel the device link
  // * Ignore encrypted messages if we don't have any keys to decrypt them
  // * Pass the message to the Elm app
  if (obj.linkStatus === "DENIED") {
    closeChannel()
    app.ports.cancelLink.send({ onBothSides: false })

  } else if (obj.iv && !cs.sessionKey) {
    return

  } else {
    app.ports.gotChannelMessage.send({
      ...obj,
      from,
      timestamp: Date.now(),
    })

  }
}}


/**
 * Close the channel.
 */
async function closeChannel() {
  console.log("Closing channel")
  // await ipfs.pubsub.unsubscribe(cs.topic)
  cs.socket.close(1000)
  cs.socket.closed = true
  resetChannelState()
}


/**
 * Reset the channel state.
 */
function resetChannelState() {
  cs.sessionKey = null
  cs.temporaryRsaPair = null
  cs.debug = ["auth.runfission.net", "localhost"].includes(location.hostname)
}



// CRYPTO
// ======

const RSA_KEY_ALGO = {
  name: "RSA-OAEP",
  modulusLength: 2048,
  publicExponent: new Uint8Array([0x01, 0x00, 0x01]),
  hash: { name: "SHA-256" }
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


async function encryptWithAes(buffer) {
  const iv = crypto.getRandomValues(
    new Uint8Array(16)
  )

  const msg = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: iv
    },
    cs.sessionKey,
    buffer
  )

  return { iv, msg }
}


function jsonBuffer(j) {
  return stringToArrayBuffer(JSON.stringify(j))
}


function stringToArrayBuffer(str) {
  return new TextEncoder().encode(str).buffer
}



// OTHER
// =====

function copyToClipboard(text) {
  if (navigator.clipboard) navigator.clipboard.writeText(text)
  else console.log(`Missing clipboard api, tried to copy: "${text}"`)
}


async function isValidUcan(encodedUcan) {
  const [encodedHeader, encodedPayload] = encodedUcan.split(".")
  const ucan = wn.ucan.decode(encodedUcan)

  const a = await wn.did.verifySignedData({
    charSize: 8,
    data: `${encodedHeader}.${encodedPayload}`,
    did: ucan.payload.iss,
    signature: ucan.signature || ""
  })

  if (!a) return a

  // Verify proofs
  if (!ucan.payload.prf) return a

  const decodedProof = wn.ucan.decode(ucan.payload.prf)
  const b = decodedProof.payload.aud === ucan.payload.iss

  if (!b) return b

  const c = await isValidUcan(ucan.payload.prf)
  return c
}


function makeBase64UrlSafe(base64) {
  return base64.replace(/\//g, "_").replace(/\+/g, "-").replace(/=+$/, "")
}
