/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

import * as Uint8Arrays from "uint8arrays"
import * as Odd from "@oddjs/odd"

import { CID } from "@oddjs/odd/common/cid"
import { Crypto } from "@oddjs/odd"
import { DistinctivePath, Partition, PartitionedNonEmpty, Segments } from "@oddjs/odd/path/index"
import PrivateFile from "@oddjs/odd/fs/v1/PrivateFile"
import localforage from "localforage"

import * as WN from "./odd.js"
import { backwardsCompatibility } from "./misc.js"
import { acceptShare, loadShare, reportShareError } from "./sharing.js"


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
app.ports.createAccountConsumer.subscribe(createAccountConsumer)
app.ports.createAccountProducer.subscribe(createAccountProducer)
app.ports.destroyAccountProducer.subscribe(destroyAccountProducer)
app.ports.leave.subscribe(leave)
app.ports.linkApp.subscribe(linkApp)

// Sharing
app.ports.acceptShare.subscribe(catchShareErrors(a => acceptShare(program, app, a)))
app.ports.loadShare.subscribe(catchShareErrors(a => loadShare(program, app, a)))



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
        const fs = await program.fileSystem.load(username)
        const publicDid = await Odd.did.exchange(crypto)
        const path = Odd.path.directory(Odd.path.RootBranch.Public, ".well-known", "exchange", publicDid)

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

    // Ensure existence of read key by loading the file system
    if (program.session) {
      program.session.fs = program.session.fs || await program.fileSystem.load(program.session.username)
    }

    // 🚀
    app.ports.gotCreateAccountSuccess.send(null)

  } else {
    app.ports.gotCreateAccountFailure.send(
      "Unable to create an account, maybe you have one already?"
    )

  }
}


// LINKING
// -------

const SESSION_PATH = Odd.path.file("public", "Apps", "Fission", "Lobby", "Session")


let accountProducer: Odd.AccountLinkingProducer | null = null


async function createAccountConsumer(username: string) {
  const consumer = await program.auth.accountConsumer(username)

  consumer.on("challenge", ({ pin }) => {
    app.ports.gotLinkAccountPin.send(pin)
  })

  consumer.on("link", async ({ approved, username }) => {
    if (approved) {
      app.ports.gotLinkAccountSuccess.send({ username })
      program.session = await program.auth.session()
    } else {
      app.ports.gotLinkAccountCancellation.send(null)
    }
  })
}


async function createAccountProducer() {
  if (!program.session) throw new Error("Cannot create an account producer, no user session found.")
  const producer = await program.auth.accountProducer(program.session.username)

  producer.on("challenge", challenge => {
    app.ports.gotLinkAccountPin.send(challenge.pin)
    app.ports.confirmLinkAccountPin.subscribe(() => {
      challenge.confirmPin()
      app.ports.confirmLinkAccountPin.unsubscribe()
    })

    app.ports.rejectLinkAccountPin.subscribe(() => {
      challenge.rejectPin()
      app.ports.rejectLinkAccountPin.unsubscribe()
    })
  })

  producer.on("link", ({ approved }) => {
    if (approved) app.ports.gotLinkAccountSuccess.send({ username: program.session?.username })
  })

  accountProducer = producer
}


async function destroyAccountProducer() {
  accountProducer?.cancel()
}


async function linkApp({
  canPermissionFiles,
  didWrite,
  didExchange,
  attenuation,
  lifetimeInSeconds,

  // Odd version-specific feature flags
  oldFlow,
  sharedRepo,
  keyInSessionStorage,
  raw,
  utf16SessionKey
}) {
  const audience = didWrite
  const issuer = await Odd.did.write(crypto)
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

    const ucan = await Odd.ucan.build({
      dependencies: { crypto },

      potency: "APPEND",
      resource,
      proof,

      audience,
      issuer,
      lifetimeInSeconds
    })

    return Odd.ucan.encode(ucan)
  })
    .concat(
      parsedRaw.map(async a => {
        const ucan = await Odd.ucan.build({
          dependencies: { crypto },

          potency: a.ptc,
          resource: a.rsc,
          expiration: a.exp,
          proof,

          audience,
          issuer,
        })
        return Odd.ucan.encode(ucan)
      })
    )

  ucans = await Promise.all(ucans)
  ucans = ucans.filter(a => a)

  // Load, or create, filesystem
  app.ports.gotLinkAppProgress.send({
    time: Date.now(),
    progress: "Resolving"
  })

  const publicPaths: DistinctivePath<PartitionedNonEmpty<Partition>>[] = []
  const privatePaths: DistinctivePath<PartitionedNonEmpty<Partition>>[] = []

  att.forEach(a => {
    let posixPath = a.wnfs || a.floofs
    if (!posixPath) return

    // Before webnative v0.24.0 we assumed all permission paths to be directory paths
    if (!posixPath.endsWith("/") && !canPermissionFiles) {
      posixPath += "/"
    }

    const path = Odd.path.fromPosix(posixPath) as DistinctivePath<PartitionedNonEmpty<Partition>>

    if (Odd.path.isOnRootBranch(Odd.path.RootBranch.Public, path)) {
      publicPaths.push(path)
    } else if (Odd.path.isOnRootBranch(Odd.path.RootBranch.Private, path)) {
      privatePaths.push(path)
    }
  })

  const fs = await program.fileSystem.load(username)

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
      if (Odd.path.isDirectory(path)) {
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
    const posixPath = Odd.path.toPosix(path, { absolute: true })
    const adjustedPath = canPermissionFiles
      ? posixPath
      : posixPath.replace(/\/$/, "")

    return {
      ...acc,
      [ adjustedPath ]: await fs.get(path).then(f => {
        return {
          key: Uint8Arrays.toString((f as PrivateFile).key, "base64pad"),
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

  const { publicKey } = Odd.did.didToPublicKey(crypto, didExchange)

  const classified = JSON.stringify({
    iv: Uint8Arrays.toString(iv, "base64pad"),
    secrets: Uint8Arrays.toString(encryptedSecrets, "base64pad"),
    sessionKey: Uint8Arrays.toString(
      utf16SessionKey
        ? await legacyUtf16SessionKeyEncryption(sessionKeyBuffer, publicKey)
        : await crypto.rsa.encrypt(sessionKeyBuffer, publicKey),
      "base64pad"
    )
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
      .get(Odd.path.unwrap(SESSION_PATH).slice(1))
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
  app.ports.gotLinkAppParams.send({ cid: cid?.toString() || null, readKey: null, ucan: null })
}


async function legacyUtf16SessionKeyEncryption(sessionKeyBuffer: Uint8Array, publicKey: Uint8Array): Promise<Uint8Array> {
  const base64 = btoa(
    Array
      .from(new Uint8Array(sessionKeyBuffer))
      .map(c => String.fromCharCode(c))
      .join("")
  )

  const view = new Uint16Array(base64.length)

  for (let i = 0, strLen = base64.length; i < strLen; i++) {
    view[ i ] = base64.charCodeAt(i)
  }

  return crypto.rsa.encrypt(new Uint8Array(view.buffer), publicKey)
}



// OTHER
// =====

function copyToClipboard(text) {
  if (navigator.clipboard) navigator.clipboard.writeText(text)
  else console.log(`Missing clipboard api, tried to copy: "${text}"`)
}


async function updateDataRoot(fs: Odd.FileSystem): Promise<{ success: boolean }> {
  const fsUcan = await reference.repositories.ucans.lookupFilesystemUcan("*")
  if (!fsUcan) throw new Error("Couldn't find an appropriate UCAN")
  return reference.dataRoot.update(await fs.root.put(), fsUcan)
}


function catchShareErrors(fn) {
  return (...args) => fn.apply(null, args).catch(err => reportShareError(app, err))
}
