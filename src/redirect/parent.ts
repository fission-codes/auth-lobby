import queryString from 'query-string'
import { KeyStore } from 'keystore-idb/dist/types/types'

const DEFAULT_URL = 'http://localhost:3000/login'

export type ReqQuery = {
  redirect: string
  folderCID: string
  readKey: string
}

export type ResQuery = {
  encryptedKey: string
  readKey: string
}

// PARENT
export async function redirectReq(folderCID: string, readKey: string, url: string = DEFAULT_URL): Promise<void> {
  const redirect = window.location.origin + window.location.pathname
  const query = queryString.stringify({
    redirect,
    folderCID,
    readKey
  })
  window.location.replace(`${url}?${query}`)
}

export async function parseKeyFromRes(ks: KeyStore): Promise<string> {
  const { encryptedKey, readKey } = queryString.parse(window.location.search)
  if ( typeof encryptedKey !== 'string'
    || typeof readKey !== 'string'
    ){
    throw new Error("Invalid query params")
  }
  return ks.decrypt(encryptedKey, readKey)
}

// CHILD
export function parseReq(): ReqQuery {
  const { redirect, folderCID, readKey } = queryString.parse(window.location.search)
  if ( typeof redirect !== 'string'
    || typeof folderCID !== 'string'
    || typeof readKey !== 'string'
    ){
    throw new Error("Invalid query params")
  }
  return { redirect, folderCID, readKey }
}

export async function redirectRes(ks: KeyStore | null, req: ReqQuery | null) {
  if(!ks) {
    throw new Error("Could not load keystore")
  }
  if(!req) {
    throw new Error("Could not determine request from querystring")
  }

  const encryptedKey = await ks.encrypt(req.folderCID, req.readKey)
  const readKey = await ks.publicReadKey()
  const query = queryString.stringify({
    encryptedKey,
    readKey,
  })
  window.location.replace(`${req.redirect}?${query}`)
}
