import * as Odd from "@oddjs/odd"
import { Links } from "@oddjs/odd/fs/types"
import { Link, SoftLink, UnixTree } from "@oddjs/odd/fs/types"
import { isSoftLink } from "@oddjs/odd/fs/types/check"


let sharing: {
  fs: Odd.FileSystem | null,
  share: UnixTree | null
} = {
  fs: null,
  share: null
}


export async function loadShare(program: Odd.Program, app, { shareId, senderUsername }) {
  const username = await program.auth.session().then(s => s?.username)
  if (!username) throw new Error("Not authenticated")

  sharing.fs = await program.fileSystem.load(username)

  // Load share
  app.ports.gotAcceptShareProgress.send("Loading")
  sharing.share = await sharing.fs.loadShare({ shareId, sharedBy: senderUsername })

  // List shared items
  const sharedLinks: SoftLink[] = softLinksOnly(
    await sharing.share.ls([])
  )

  const sharedItems = await Promise.all(sharedLinks.map(async item => {
    const resolvedItem = await sharing.fs?.resolveSymlink(item)

    return {
      name: item.name,

      // @ts-ignore
      isFile: resolvedItem.header.metadata.isFile
    }
  }))

  app.ports.listSharedItems.send(
    sharedItems
  )
}


export async function acceptShare(program: Odd.Program, app, { sharedBy }) {
  const fs = sharing.fs
  const share = sharing.share

  if (!share || !fs) {
    console.error("No share or file system loaded.")
    return
  }

  const softLinks = softLinksOnly(await share.ls([]))

  // Accept
  await fs.write(
    Odd.path.directory(Odd.path.RootBranch.Private, "Shared with me", sharedBy),
    softLinks
  )

  // Publish
  app.ports.gotAcceptShareProgress.send("Publishing")

  const issuer = await Odd.did.write(program.components.crypto)
  const fsUcan = await Odd.ucan.build({
    dependencies: { crypto: program.components.crypto },

    potency: "APPEND",
    resource: "*",
    proof: await program.components.storage
      .getItem(program.components.storage.KEYS.ACCOUNT_UCAN)
      .then(a => typeof a === "string" ? Odd.ucan.decode(a) : undefined),

    audience: issuer,
    issuer
  })

  const rootCid = await fs.root.put()
  const res = await program.components.reference.dataRoot.update(rootCid, fsUcan)

  if (!res.success) return reportShareError(app, "Failed to update data root 😰")

  // Fin
  app.ports.gotAcceptShareProgress.send("Published")
  sharing = { fs: null, share: null }
}



// 🛠


export function softLinksOnly(links: Links): SoftLink[] {
  return Object
    .values(links)
    .reduce((acc: SoftLink[], link: Link) => {
      if (isSoftLink(link)) return [ ...acc, link ]
      return acc
    }, [])
}


export function reportShareError(app, err) {
  app.ports.gotAcceptShareError.send(err.message || err)
  throw err
}