import * as WN from "./odd.js"
import { backwardsCompatibility } from "./misc.js"


// 🚀


await backwardsCompatibility()


let program = await WN.program()


export async function clearData() {
  const { crypto, storage } = program.components

  await storage.removeItem(storage.KEYS.ACCOUNT_UCAN)
  await storage.removeItem(storage.KEYS.CID_LOG)
  await storage.removeItem(storage.KEYS.SESSION)
  await storage.removeItem(storage.KEYS.UCANS)

  await crypto.keystore.clearStore()

  const button = document.body.querySelector("button")
  if (button) {
    button.className = "cursor-default inline-flex p-3 text-green"
    button.querySelectorAll("span")[ 1 ].innerHTML = "Cleared all traces"
    button.blur()
  }

  program = await WN.program()

  await renderDid()
}


export async function renderDid() {
  const did = await program.agentDID()
  const didEl = document.querySelector("#did")
  if (didEl) didEl.innerHTML = did
}