/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

import * as Uint8Arrays from "uint8arrays"
import * as Webnative from "webnative"

import { CID } from "webnative/common/cid.js"
import { Crypto } from "webnative"
import { DistinctivePath } from "webnative/path/index.js"
import localforage from "localforage"

import * as WN from "./webnative.js"
import { backwardsCompatibility } from "./misc.js"
import PrivateFile from "webnative/fs/v1/PrivateFile.js"


// 🚀


await backwardsCompatibility()


const program = await WN.program()
const { crypto, depot, reference, storage } = program.components

// Elm
const app = globalThis.Elm.Main.init({
  flags: {
    apiDomain: globalThis.API_ENDPOINT.replace(/^https?:\/\//, ""),
    dataRootDomain: globalThis.DATA_ROOT_DOMAIN,
    url: location.href,
    usedUsername: program.session?.username || null,
    version: globalThis.VERSION
  }
})

// Ports
app.ports.checkIfUsernameIsAvailable.subscribe(checkIfUsernameIsAvailable)
app.ports.copyToClipboard.subscribe(copyToClipboard)
app.ports.createAccount.subscribe(createAccount)
app.ports.leave.subscribe(leave)
app.ports.linkApp.subscribe(linkApp)

// Sharing
// app.ports.acceptShare.subscribe(catchShareErrors(acceptShare))
// app.ports.loadShare.subscribe(catchShareErrors(loadShare))



// ACCOUNT
// =======

/**
 * Remove all traces of the user.
 */
async function leave() {
  if (window.confirm("Are you sure you want to remove this device? If you're not authenticated on any other devices, you will lose access to your account!")) {
    const username = await localforage.getItem("usedUsername")
    if (typeof username !== "string") return

    const dataRoot = username && await reference.dataRoot.lookup(username)

    if (dataRoot) {
      // We want users to still be able to remove their account data, even if
      // they can't remove their exchange DID, even though that's unfortunate.
      // This is esp. important when the filesystem version doesn't match and
      // the user just wants to create/log in a new account on the same device.
      try {
        const fs = await program.loadRootFileSystem(username)
        const publicDid = await Webnative.did.exchange(crypto)
        const path = Webnative.path.directory(Webnative.path.Branch.Public, ".well-known", "exchange", publicDid)

        if (await fs.exists(path)) {
          await fs.rm(path)
          await updateDataRoot(fs)
        }
      } catch (e) {
        console.error(`Error while trying to remove DID form public/.well-known/exchange/`, e)
      }
    }

    await localforage.createInstance({ name: "keystore" })
    await localforage.clear()

    location.reload()
  }
}


// CREATE
// ------

async function checkIfUsernameIsAvailable(username: string): Promise<void> {
  if (await program.auth.isUsernameValid(username)) {
    const isAvailable = await program.auth.isUsernameAvailable(username)
    app.ports.gotUsernameAvailability.send({ available: isAvailable, valid: true })

  } else {
    app.ports.gotUsernameAvailability.send({ available: false, valid: false })

  }
}


async function createAccount(args) {
  const { success } = await program.auth.register(
    { email: args.email, username: args.username }
  )

  if (success) {
    program.session = await program.auth.session()

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

const SESSION_PATH = Webnative.path.file("public", "Apps", "Fission", "Lobby", "Session")


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
  const issuer = await Webnative.did.write(crypto)
  const username = program.session?.username
  if (!username) throw new Error("No session was set")

  // Proof
  const unknownProof = await storage.getItem(storage.KEYS.ACCOUNT_UCAN)
  const proof = typeof unknownProof === "string" ? unknownProof : undefined

  // Build UCAN
  const att = attenuation.map(a => {
    const [ key, value ] = a.resource
    return { [ key ]: value, "cap": a.capability }
  })

  const parsedRaw = raw && raw !== null ? JSON.parse(raw) : []

  let ucans = att.map(async a => {
    // @ts-ignore
    const { cap, ...resource } = { ...a }

    const ucan = await Webnative.ucan.build({
      dependencies: { crypto },

      potency: "APPEND",
      resource,
      proof,

      audience,
      issuer,
      lifetimeInSeconds
    })

    return Webnative.ucan.encode(ucan)
  })
    .concat(
      parsedRaw.map(async a => {
        const ucan = await Webnative.ucan.build({
          dependencies: { crypto },

          potency: a.ptc,
          resource: a.rsc,
          expiration: a.exp,
          proof,

          audience,
          issuer,
        })
        return Webnative.ucan.encode(ucan)
      })
    )

  ucans = await Promise.all(ucans)
  ucans = ucans.filter(a => a)

  // Load, or create, filesystem
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Resolving"
  })

  const publicPaths: DistinctivePath[] = []
  const privatePaths: DistinctivePath[] = []

  att.forEach(a => {
    let posixPath = a.wnfs || a.floofs
    if (!posixPath) return

    // Before webnative v0.24.0 we assumed all permission paths to be directory paths
    if (!posixPath.endsWith("/") && !canPermissionFiles) {
      posixPath += "/"
    }

    const path = Webnative.path.fromPosix(posixPath)

    if (Webnative.path.isBranch(Webnative.path.Branch.Public, path)) {
      publicPaths.push(path)
    } else if (Webnative.path.isBranch(Webnative.path.Branch.Private, path)) {
      privatePaths.push(path)
    }
  })

  const fs = await program.loadRootFileSystem(username)

  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Loading"
  })

  // Ensure all necessary filesystem parts
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Identifying"
  })

  const paths = [ ...publicPaths, ...privatePaths ]
  if (paths.length) app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Checking"
  })

  await paths.reduce(async (promise, path) => {
    await promise
    const pathExists = await fs.exists(path)

    if (!pathExists) {
      if (Webnative.path.isDirectory(path)) {
        await fs.mkdir(path)
      } else {
        await fs.write(path, new Uint8Array())
      }
    }
  }, Promise.resolve())

  // Filesystem secrets
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Gathering"
  })

  let fsSecrets = await privatePaths.reduce(async (promise, path) => {
    const acc = await promise
    const posixPath = Webnative.path.toPosix(path, { absolute: true })
    const adjustedPath = canPermissionFiles
      ? posixPath
      : posixPath.replace(/\/$/, "")

    return {
      ...acc,
      [ adjustedPath ]: await fs.get(path).then(f => {
        return {
          key: (f as PrivateFile).key,
          bareNameFilter: (f as PrivateFile).header.bareNameFilter
        }
      })
    }

  }, Promise.resolve({}))

  // Session key
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Encrypting"
  })

  const sessionKey = await crypto.aes.genKey(Crypto.SymmAlg.AES_GCM)
  const sessionKeyBuffer = await crypto.aes.exportKey(sessionKey)

  // Classified
  const iv = crypto.misc.randomNumbers({ amount: 16 })
  const encryptedSecrets = await crypto.aes.encrypt(
    Uint8Arrays.fromString(JSON.stringify({
      fs: fsSecrets,
      ucans: ucans
    }), "utf8"),
    sessionKey,
    Crypto.SymmAlg.AES_GCM,
    iv
  )

  const { publicKey } = Webnative.did.didToPublicKey(crypto, didExchange)

  const classified = JSON.stringify({
    iv: Uint8Arrays.toString(iv, "base64pad"),
    secrets: Uint8Arrays.toString(encryptedSecrets, "base64pad"),
    sessionKey: await crypto.rsa.encrypt(sessionKeyBuffer, publicKey)
  })

  // Store classified data
  let cid: CID | null = null

  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Storing"
  })

  if (keyInSessionStorage) {
    sessionStorage.setItem("encrypted-secrets", classified) // backwards compatibility
    sessionStorage.setItem(`encrypted-secrets-for-${didExchange}`, classified)
  } else if (sharedRepo) {
    cid = await depot.putChunked(
      Uint8Arrays.fromString(classified, "utf8")
    ).then(
      r => r.cid
    )
  } else {
    await fs.write(SESSION_PATH, Uint8Arrays.fromString(classified, "utf8"))

    cid = await fs.root.prettyTree
      .get(Webnative.path.unwrap(SESSION_PATH).slice(1))
      .then(f => f ? f.put() : null)
  }

  // Update user's data root
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Updating"
  })

  const res = await updateDataRoot(fs)
  if (!res.success) return app.ports.gotLinkAppError.send("Failed to update data root 😰")

  // Send everything back to Elm
  app.ports.gotLinkAppParams.send({ cid: cid?.toString(), readKey: null, ucan: null })
}


/**
 * You got linked 🎢
 */
// TODO: Should be handled by webnative
//
// async function linkedDevice({ readKey, ucan, username }) {
//   if (!navigator.storage || !navigator.storage.persist) {
//     app.ports.gotLinked.send({ username })
//   } else if (await navigator.storage.persist()) {
//     app.ports.gotLinked.send({ username })
//   } else {
//     // Ideally we should do:
//     // alert("I need permission to store data on this browser. Refresh the page to try again.")
//     // return
//     //
//     // But currently there's a bug in incognito Chromium
//     // where `navigator.storage.persist()` doesn't show the popup.
//     app.ports.gotLinked.send({ username })
//   }

//   await localforage.setItem("readKey", readKey)
//   await localforage.setItem("ucan", ucan)
//   await localforage.setItem("usedUsername", username)
// }



// OTHER
// =====

function copyToClipboard(text) {
  if (navigator.clipboard) navigator.clipboard.writeText(text)
  else console.log(`Missing clipboard api, tried to copy: "${text}"`)
}


async function updateDataRoot(fs: Webnative.FileSystem): Promise<{ success: boolean }> {
  const fsUcan = await reference.repositories.ucans.lookupFilesystemUcan("*")
  if (!fsUcan) throw new Error("Couldn't find an appropriate UCAN")
  return reference.dataRoot.update(await fs.root.put(), fsUcan)
}
