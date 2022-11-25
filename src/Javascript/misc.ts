import localforage from "localforage"
import { namespace } from "webnative"

import { CONFIG } from "./webnative.js"


export async function backwardsCompatibility(): Promise<void> {
  const newDB = localforage.createInstance({ name: namespace(CONFIG) })
  if (await newDB.getItem("migrated") === "true") return

  // Let webnative handle this properly
  const usedUsername = await localforage.getItem("usedUsername")
  if (usedUsername) await localforage.setItem("webnative.auth_username", usedUsername)
}