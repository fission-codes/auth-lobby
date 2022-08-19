/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/


const wn = webnative

let app


// 🚀


wn.setup.endpoints({
  api: API_ENDPOINT,
  lobby: location.origin,
  user: DATA_ROOT_DOMAIN
})

wn.setup.debug({
  enabled: true
})

wn.setup.userMessages({
  versionMismatch: {
    newer: async version => alert(`Your auth lobby is outdated. It might be cached. Try reloading the page until this message disappears.\n\nIf this doesn't help, please contact support@fission.codes.\n\n(Filesystem version: ${version}. Webnative version: ${wn.VERSION})`),
    older: async version => alert(`Your filesystem is outdated.\n\nPlease upgrade your filesystem by running a miration (https://guide.fission.codes/accounts/account-signup/account-migration) or click on "remove this device" and create a new account.\n\n(Filesystem version: ${version}. Webnative version: ${wn.VERSION})`),
  }
})


;(async () => {
  const ucan = await localforage.getItem("ucan")

  if (ucan && !wn.ucan.isValid(wn.ucan.decode(ucan))) {
    alert("⚠️ Invalid authentication session.\n\nSorry for the inconvenience, we made some mistakes in September 2020 causing linked devices to have invalid sessions. You can recover your account by returning to the browser/device you originally signed up with (that would be the browser with the same account that doesn't give you this message).")

    await webnative.keystore.clear()
    await localforage.clear()
  }

  bootElm()
})()


// ELM
// ---

async function bootElm() {
  const usedUsername = await localforage.getItem("usedUsername")

  app = Elm.Main.init({
    flags: {
      apiDomain: API_ENDPOINT.replace(/^https?:\/\//, ""),
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

  // Sharing
  app.ports.acceptShare.subscribe(catchShareErrors(acceptShare))
  app.ports.loadShare.subscribe(catchShareErrors(loadShare))

  // Better error reporting for async things
  app.ports.publishOnChannel.subscribe(
    a => publishOnChannel(a).catch(console.error)
  )
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

  const readKey = await wn.crypto.aes.genKeyStr()
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
    const username = await localforage.getItem("usedUsername")
    const dataRoot = username && await wn.dataRoot.lookup(username)

    if (dataRoot) {
      // We want users to still be able to remove their account data, even if
      // they can't remove their exchange DID, even though that's unfortunate.
      // This is esp. important when the filesystem version doesn't match and
      // the user just wants to create/log in a new account on the same device.
      try {
        await wn.checkFileSystemVersion(dataRoot)
        const permissions = ROOT_ACCESS
        const fs = await wn.fs.fromCID(dataRoot, { localOnly: true, permissions })
        const publicDid = await wn.did.exchange()
        const path = wn.path.directory(wn.path.Branch.Public, ".well-known", "exchange", publicDid)

        if (await fs.exists(path)) {
          await fs.rm(path)
          await updateDataRoot(fs)
        }
      } catch (e) {
        console.error(`Error while trying to remove DID form public/.well-known/exchange/`, e)
      }
    }

    await webnative.leave({ withoutRedirect: true })
    await localforage.clear()

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

    // Add public exchange key to filesystem
    const fs = await freshFileSystemWithPublicExchangeKey()
    const { success } = await updateDataRoot(fs)

    if (!success) {
      return app.ports.gotCreateAccountFailure.send(
        "Failed to update data root"
      )
    }

    // Fin
    if (!navigator.storage || !navigator.storage.persist) {
      app.ports.gotCreateAccountSuccess.send(
        null
      )
    } else if (await navigator.storage.persist()) {
      app.ports.gotCreateAccountSuccess.send(
        null
      )
    } else {
      // Ideally we should do:
      // app.ports.gotCreateAccountFailure.send(
      //   "I need permission from you to store data in your browser."
      // )
      //
      // But currently there's a bug in incognito Chromium
      // where `navigator.storage.persist()` doesn't show the popup.
      app.ports.gotCreateAccountSuccess.send(
        null
      )
    }

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
}


// LINK
// ----

const ROOT_ACCESS = { fs: { private: [ wn.path.root() ], public: [ wn.path.root() ] }}
const SESSION_PATH = wn.path.file("public", "Apps", "Fission", "Lobby", "Session")


async function linkApp({
  canPermissionFiles,
  didWrite,
  didExchange,
  attenuation,
  lifetimeInSeconds,

  // Webnative version-specific feature flags
  oldFlow,
  sharedRepo,
  keyInSessionStorage,
  raw
}) {
  const audience = didWrite
  const issuer = await wn.did.write()

  // Proof
  const proof = await localforage.getItem("ucan")

  // Build UCAN
  const att = attenuation.map(a => {
    const [key, value] = a.resource
    return { [key]: value, "cap": a.capability }
  })

  const parsedRaw = raw && raw !== null ? JSON.parse(raw) : []

  // TODO: Waiting on API changes
  // const ucanPromise = wn.ucan.build({
  //   attenuations: att,
  //   proofs: proof ? [ proof ] : [],
  //
  //   audience,
  //   issuer,
  //   lifetimeInSeconds
  // })


  let ucans = att.map(async a => {
    const { cap, ...resource } = { ...a }
    const ucan = await wn.ucan.build({
      potency: "APPEND",
      resource,
      proof,

      audience,
      issuer,
      lifetimeInSeconds
    })

    // Backwards compatibility for UCAN encoding issue with proof with SDK version < 0.24
    if (!canPermissionFiles) await backwardsCompatUcan(ucan)

    return wn.ucan.encode(ucan)
  })
  .concat(
    parsedRaw.map(async a => {
      const ucan = await wn.ucan.build({
        potency: a.ptc,
        resource: a.rsc,
        expiration: a.exp,
        proof,
        audience,
        issuer,
      })
      return wn.ucan.encode(ucan)
    })
  )

  ucans = await Promise.all(ucans)
  ucans = ucans.filter(a => a)

  // Load, or create, filesystem
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Resolving"
  })

  const username = await localforage.getItem("usedUsername")
  const dataRoot = await wn.dataRoot.lookup(username)

  const publicPaths = []
  const privatePaths = []

  att.forEach(a => {
    let posixPath = a.wnfs || a.floofs
    if (!posixPath) return

    // Before webnative v0.24.0 we assumed all permission paths to be directory paths
    if (!posixPath.endsWith("/") && !canPermissionFiles) {
      posixPath += "/"
    }

    const path = wn.path.fromPosix(posixPath)

    if (wn.path.isBranch(wn.path.Branch.Public, path)) {
      publicPaths.push(path)
    } else if (wn.path.isBranch(wn.path.Branch.Private, path)) {
      privatePaths.push(path)
    }
  })

  const permissions = ROOT_ACCESS

  let fs
  let madeFsChanges = false

  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Loading"
  })

  if (dataRoot) {
    await wn.checkFileSystemVersion(dataRoot)
    await wn.lobby.storeFileSystemRootKey(await myReadKey())
    fs = await wn.fs.fromCID(dataRoot, { localOnly: true, permissions })
  } else {
    fs = await freshFileSystem({ permissions })
    madeFsChanges = true
  }

  // Ensure all necessary filesystem parts
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Identifying"
  })

  if (await fs.hasPublicExchangeKey() === false) {
    await fs.addPublicExchangeKey()
    madeFsChanges = true
  }

  const fsUcan = await wn.ucan.build({
    potency: "APPEND",
    resource: "*",
    proof,

    audience: issuer,
    issuer
  })

  const paths = [...publicPaths, ...privatePaths]
  if (paths.length) app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Checking"
  })

  await paths.reduce(async (promise, path) => {
    const acc = await promise
    const pathExists = await fs.exists(path)

    if (!pathExists) {
      if (wn.path.isDirectory(path)) {
        await fs.mkdir(path, { localOnly: true })
      } else {
        await fs.write(path, "", { localOnly: true })
      }
      madeFsChanges = true
    }

  }, Promise.resolve())

  // Backwards compatibility for UCAN encoding issue with proof with SDK version < 0.24
  if (!canPermissionFiles) await backwardsCompatUcan(fsUcan)

  // Filesystem secrets
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Gathering"
  })

  let fsSecrets = await privatePaths.reduce(async (promise, path) => {
    const acc = await promise
    const posixPath = wn.path.toPosix(path, { absolute: true })
    const adjustedPath = canPermissionFiles
      ? posixPath
      : posixPath.replace(/\/$/, "")

    return {
      ...acc,
      [adjustedPath]: await fs.get(path).then(f => {
        return {
          key: f.key,
          bareNameFilter: f.header.bareNameFilter
        }
      })
    }

  }, Promise.resolve({}))

  // Session key
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Encrypting"
  })

  const sessionKey = await crypto.subtle.generateKey(
    {
      name: "AES-GCM",
      length: 256
    },
    true,
    [ "encrypt", "decrypt" ]
  )

  const sessionKeyBuffer = await crypto.subtle.exportKey("raw", sessionKey)
  const sessionKeyBase64 = arrayBufferToBase64(sessionKeyBuffer)

  // Classified
  const iv = crypto.getRandomValues(
    new Uint8Array(16)
  )

  const encryptedSecrets = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: iv
    },
    sessionKey,
    stringToArrayBuffer(JSON.stringify({
      fs: fsSecrets,
      ucans: ucans
    }))
  )

  const { publicKey } = wn.did.didToPublicKey(didExchange)
  const ks = await wn.keystore.get()
  const classified = JSON.stringify({
    iv: arrayBufferToBase64(iv),
    secrets: arrayBufferToBase64(encryptedSecrets),
    sessionKey: await ks.encrypt(sessionKeyBase64, publicKey)
  })

  // Store classified data
  let cid = null

  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Storing"
  })

  if (keyInSessionStorage) {
    sessionStorage.setItem("encrypted-secrets", classified) // backwards compatibility
    sessionStorage.setItem(`encrypted-secrets-for-${didExchange}`, classified)
  } else if (sharedRepo) {
    cid = await webnative.ipfs.add(classified).then(r => r.cid)
  } else {
    await fs.write(SESSION_PATH, classified)

    cid = await fs.root.prettyTree
      .get(wn.path.unwrap(SESSION_PATH).slice(1))
      .then(f => f.put())

    madeFsChanges = true
  }

  // Update user's data root if need be
  if (madeFsChanges) {
    app.ports.gotLinkAppProgress.send({
      time: Date.now(),
      progress: "Updating"
    })

    const rootCid = await fs.root.put()
    const res = await wn.dataRoot.update(rootCid, wn.ucan.encode(fsUcan))
    if (!res.success) return app.ports.gotLinkAppError.send("Failed to update data root 😰")
  }

  // TODO: Remove backwards compatibility
  if (oldFlow) {
    const oldUcan = await wn.ucan.build({
      potency: "APPEND",
      resource: "*",

      audience,
      issuer,
      lifetimeInSeconds,
      proof
    })

    const plainTextReadKey = await myReadKey()
    const readKey = await ks.encrypt(plainTextReadKey, publicKey).then(makeBase64UrlSafe)

    app.ports.gotLinkAppParams.send({ cid: null, readKey, ucan: wn.ucan.encode(oldUcan) })

  } else {
    // Send everything back to Elm
    app.ports.gotLinkAppParams.send({ cid, readKey: null, ucan: null })

  }
}


/**
 * You got linked 🎢
 */
async function linkedDevice({ readKey, ucan, username }) {
  if (!navigator.storage || !navigator.storage.persist) {
    app.ports.gotLinked.send({ username })
  } else if (await navigator.storage.persist()) {
    app.ports.gotLinked.send({ username })
  } else {
    // Ideally we should do:
    // alert("I need permission to store data on this browser. Refresh the page to try again.")
    // return
    //
    // But currently there's a bug in incognito Chromium
    // where `navigator.storage.persist()` doesn't show the popup.
    app.ports.gotLinked.send({ username })
  }

  await localforage.setItem("readKey", readKey)
  await localforage.setItem("ucan", ucan)
  await localforage.setItem("usedUsername", username)
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
  const ipfsId = "doesntmatteratthemoment" // await ipfs.id().then(a => a.id)
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

  const endpoint = API_ENDPOINT.replace(/^https?:\/\//, "wss://")

  cs.socket = new WebSocket(`${endpoint}/user/link/${rootDid}`)
  cs.socket.onmessage = channelMessage(rootDid, ipfsId)
}


/**
 * 📢 Outgoing channel message
 */
async function publishOnChannel([ maybeUsername, subject, data ]) {
  const rootDid = await lookupRootDid(maybeUsername)
  const topic = `deviceLink#${rootDid}`
  // const publish = a => ipfs.pubsub.publish(topic, a)
  const publish = a => {
    logGeneric("Outgoing message (encrypted if needed):", a)

    const binary = typeof a === "string"
      ? stringToArrayBuffer(a)
      : a

    logGeneric("Outgoing message (raw):", binary)

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
      const ucan = await wn.ucan.build({
        issuer: await wn.did.ucan(),
        audience: data.didThrowaway,
        lifetimeInSeconds: 60 * 5, // 5 minutes
        facts: [{ sessionKey }],
        potency: null
      })

      // Encode & encrypt UCAN
      //
      // TODO: Waiting for API changes
      // const encodedUcan = wn.ucan.encode(ucan)

      const { iv, msg } = await encryptWithAes(
        stringToArrayBuffer(wn.ucan.encode(ucan))
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

      // Proof
      let proof = await localforage.getItem("ucan")

      // UCAN
      const ucan = await wn.ucan.build({
        audience: data.didInquirer,
        issuer: await wn.did.write(),
        lifetimeInSeconds: 60 * 60 * 24 * 30 * 12 * 1000, // 1000 years
        potency: "SUPER_USER",
        proof,

        // TODO: UCAN v0.5
        // proofs: [ await localforage.getItem("ucan") ]
      })

      // TODO: Remove when people aren't using webnative version < 0.24 anymore
      await backwardsCompatUcan(ucan)

      // Encode & encrypt
      const { iv, msg } = await encryptWithAes(
        // TODO: Waiting for API changes
        // wn.ucan.encode(ucan)
        jsonBuffer({ readKey, ucan: wn.ucan.encode(ucan) })
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
  }

  logGeneric("Incoming message (raw):", data)
  logGeneric("Incoming message (transformed):", string)

  // Stop interval for broadcast
  if (cs.pingIntervalId) {
    clearInterval(cs.pingIntervalId)
    cs.pingIntervalId = null
  }

  const decryptedMessagePromise = (async () => {
    ////////////////////////////////////////////
    // 🔏 (Linking, Pt. 3)
    ////////////////////////////////////////////

    logDebug("🔏 Linking, Pt. 3")

    if (cs.temporaryRsaPair) {
      const json = JSON.parse(string)
      const iv = base64ToArrayBuffer(json.iv)

      // Already did this?
      if (cs.sessionKey) {
        throw new Error("Already got a session key")
      }

      logDebug("Extract session key")
      const rawSessionKey = await crypto.subtle.decrypt(
        {
          name: "RSA-OAEP"
        },
        cs.temporaryRsaPair.privateKey,
        base64ToArrayBuffer(json.sessionKey)
      )

      logDebug("Import session key")
      const sessionKey = await crypto.subtle.importKey(
        "raw",
        rawSessionKey,
        "AES-GCM",
        false,
        [ "encrypt", "decrypt" ]
      )

      cs.sessionKey = sessionKey
      cs.temporaryRsaPair = null

      logDebug("Extract UCAN")
      const encodedUcan = arrayBufferToString(await crypto.subtle.decrypt(
        {
          name: "AES-GCM",
          iv: iv
        },
        cs.sessionKey,
        base64ToArrayBuffer(json.msg)
      ))

      const ucan = wn.ucan.decode(encodedUcan)

      if (await wn.ucan.isValid(ucan) === false) {
        throw new Error("Invalid closed UCAN")
      }

      // TODO: (next UCAN version) Proof of closed ucan
      // if (ucan.payload.prf.length > 0 || ucan.payload.prf[0].payload.att.length === 0) {
      //   throw new Error("Invalid closed UCAN")
      // }

      if (ucan.payload.ptc) {
        throw new Error("Invalid closed UCAN: must not have any potency")
      }

      logDebug("Extract session key")
      const sessionKeyFromFact = ucan.payload.fct[0] && ucan.payload.fct[0].sessionKey

      if (!sessionKeyFromFact) {
        throw new Error("Session key is missing from closed UCAN")
      }

      logDebug("Compare session keys")
      const sessionKeyWeAlreadyGot = arrayBufferToBase64(rawSessionKey)

      if (sessionKeyFromFact !== sessionKeyWeAlreadyGot) {
        throw new Error("Closed UCAN session key does not match the one we already have")
      }

      logDebug("Carry on with challenge")
      return Array.from(crypto.getRandomValues(
        new Uint8Array(6)
      )).map(n => {
        return n % 10
      })

    ////////////////////////////////////////////
    // 🔐 (Linking, Pt. 4+)
    ////////////////////////////////////////////
    } else if (cs.sessionKey) {
      logDebug("🔐 Linking, Pt. 4+")
      const { iv, msg } = JSON.parse(string)

      logDebug("msg: " + msg)

      if (!iv) {
        throw new Error("I tried to decrypt some data (with AES) but the `iv` was missing from the message")
      }

      logDebug("decrypting msg")
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

    logWarn(err)
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
  logDebug("Closing channel")
  // await ipfs.pubsub.unsubscribe(cs.topic)

  if (cs.socket) {
    cs.socket.close(1000)
    cs.socket.closed = true
  }

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

async function backwardsCompatUcan(ucan) {
  ucan.payload.prf = ucan.payload.prf === null
    ? undefined
    : ucan.payload.prf

  ucan.signature = await wn.ucan.sign(ucan.header, ucan.payload)
}

function copyToClipboard(text) {
  if (navigator.clipboard) navigator.clipboard.writeText(text)
  else console.log(`Missing clipboard api, tried to copy: "${text}"`)
}

async function freshFileSystem({ permissions }) {
  const fs = await wn.fs.empty({
    permissions,
    rootKey: await myReadKey(),
    localOnly: true
  })

  await fs.mkdir(wn.path.directory("private", "Apps"))
  await fs.mkdir(wn.path.directory("private", "Audio"))
  await fs.mkdir(wn.path.directory("private", "Documents"))
  await fs.mkdir(wn.path.directory("private", "Photos"))
  await fs.mkdir(wn.path.directory("private", "Video"))
  return fs
}

async function freshFileSystemWithPublicExchangeKey() {
  const fs = await freshFileSystem({ permissions: ROOT_ACCESS })
  await fs.addPublicExchangeKey()
  return fs
}

function makeBase64UrlSafe(base64) {
  return base64.replace(/\//g, "_").replace(/\+/g, "-").replace(/=+$/, "")
}

async function updateDataRoot(fs) {
  const proof = await localforage.getItem("ucan")
  const issuer = await wn.did.write()
  const fsUcan = await wn.ucan.build({
    potency: "APPEND",
    resource: "*",
    proof,

    audience: issuer,
    issuer
  })

  return wn.dataRoot.update(
    await fs.root.put(),
    wn.ucan.encode(fsUcan)
  )
}



// LOGGING
// =======

function logGeneric(...args) {
  if (cs.debug) console.log.apply(this, args)
}

function logDebug(...args) {
  if (cs.debug) console.debug.apply(this, args)
}

function logInfo(...args) {
  if (cs.debug) console.info.apply(this, args)
}

function logWarn(...args) {
  if (cs.debug) console.warn.apply(this, args)
}



// SHARING
// =======

let sharing = {}


async function loadShare({ shareId, senderUsername }) {
  const permissions = ROOT_ACCESS

  // Load filesystem
  const username = await localforage.getItem("usedUsername")
  const dataRoot = await wn.dataRoot.lookup(username)

  if (dataRoot) {
    sharing.fs = await wn.fs.fromCID(dataRoot, { localOnly: true, permissions })
  } else {
    sharing.fs = await freshFileSystem({ permissions })
  }

  // Load share
  app.ports.gotAcceptShareProgress.send("Loading")
  sharing.share = await sharing.fs.loadShare({ shareId, sharedBy: senderUsername })

  // List shared items
  const sharedLinks = Object.values(await sharing.share.ls([]))
  const sharedItems = await Promise.all(sharedLinks.map(async item => {
    const resolvedItem = await sharing.fs.resolveSymlink(item)
    return {
      name: item.name,
      isFile: resolvedItem.header.metadata.isFile
    }
  }))

  app.ports.listSharedItems.send(
    sharedItems
  )
}


async function acceptShare({ sharedBy }) {
  const fs = sharing.fs
  const share = sharing.share

  if (!share) return

  // Accept
  await fs.add(
    wn.path.directory(wn.path.Branch.Private, "Shared with me", sharedBy),
    await share.ls([])
  )

  // Publish
  app.ports.gotAcceptShareProgress.send("Publishing")

  const issuer = await wn.did.write()
  const fsUcan = await wn.ucan.build({
    potency: "APPEND",
    resource: "*",
    proof: await localforage.getItem("ucan"),

    audience: issuer,
    issuer
  })

  const rootCid = await fs.root.put()
  const res = await wn.dataRoot.update(rootCid, wn.ucan.encode(fsUcan))

  if (!res.success) return reportShareError("Failed to update data root 😰")

  // Fin
  app.ports.gotAcceptShareProgress.send("Published")
  sharing = {}
}


function catchShareErrors(fn) {
  return (...args) => fn.apply(null, args).catch(reportShareError)
}


function reportShareError(err) {
  app.ports.gotAcceptShareError.send(err.message || err)
  throw err
}
