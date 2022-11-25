import localforage from "localforage"


export async function backwardsCompatibility() {
  // Let webnative handle this properly
  const usedUsername = await localforage.getItem("usedUsername")
  if (usedUsername) await localforage.setItem("webnative.auth_username", usedUsername)
}