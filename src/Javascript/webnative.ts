import * as FissionAuthWithWnfs from "webnative/components/auth/implementation/fission-wnfs"
import * as FissionReference from "webnative/components/reference/implementation/fission-base"
import * as IpfsDefaultPkg from "webnative/components/depot/implementation/ipfs-default-pkg"

import * as FileSystem from "webnative/fs/types"
import * as Webnative from "webnative"

import { Configuration, namespace } from "webnative"
import { DataComponents } from "webnative/components/manners/implementation"
import { Endpoints } from "webnative/common/fission"
import { addSampleData, addPublicExchangeKey, hasPublicExchangeKey } from "webnative/fs/data"


// 🏔


export const CONFIG: Configuration = {
  namespace: `lobby-${globalThis.DATA_ROOT_DOMAIN}`,
  debug: true,

  fileSystem: {
    loadImmediately: false,
  },

  userMessages: {
    versionMismatch: {
      newer: async version => alert(`Your auth lobby is outdated. It might be cached. Try reloading the page until this message disappears.\n\nIf this doesn't help, please contact support@fission.codes.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
      older: async version => alert(`Your filesystem is outdated.\n\nPlease upgrade your filesystem by running a miration (https://guide.fission.codes/accounts/account-signup/account-migration) or click on "remove this device" and create a new account.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
    }
  }
}


export const ENDPOINTS: Endpoints = {
  apiPath: "/v2/api",
  lobby: location.origin,
  server: globalThis.API_ENDPOINT,
  userDomain: globalThis.DATA_ROOT_DOMAIN
}



// 🛠


export async function program(): Promise<Webnative.Program> {
  const crypto = await Webnative.defaultCryptoComponent(CONFIG)
  const storage = Webnative.defaultStorageComponent(CONFIG)

  // Depot
  const depot = await IpfsDefaultPkg.implementation(
    { storage },
    `${ENDPOINTS.server}/ipfs/peers`,
    `${namespace(CONFIG)}/ipfs`
  )

  // Manners
  const defaultManners = Webnative.defaultMannersComponent(CONFIG)

  const manners = {
    ...defaultManners,
    fileSystem: {
      ...defaultManners.fileSystem,
      hooks: {
        ...defaultManners.fileSystem.hooks,
        afterLoadNew: async (fs: FileSystem.API, _account: FileSystem.AssociatedIdentity, dataComponents: DataComponents) => {
          await addSampleData(fs)
          await addPublicExchangeKey(dataComponents.crypto, fs)
          await fs.publish()
        },
        afterLoadExisting: async (fs: FileSystem.API, _account: FileSystem.AssociatedIdentity, dataComponents: DataComponents) => {
          if (await hasPublicExchangeKey(dataComponents.crypto, fs) === false) {
            await addPublicExchangeKey(dataComponents.crypto, fs)
            await fs.publish()
          }
        }
      }
    }
  }

  // Remaining
  const capabilities = Webnative.defaultCapabilitiesComponent({ crypto, depot })
  const reference = await FissionReference.implementation(ENDPOINTS, { crypto, manners, storage })
  const auth = FissionAuthWithWnfs.implementation(ENDPOINTS, { crypto, reference, storage })

  // Fin
  const components = {
    auth,
    capabilities,
    crypto,
    depot,
    manners,
    reference,
    storage,
  }

  return Webnative.assemble(CONFIG, components)
}