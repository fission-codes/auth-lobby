let sharing = {}


async function loadShare({ shareId, senderUsername }) {
  const permissions = ROOT_PERMISSIONS

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
