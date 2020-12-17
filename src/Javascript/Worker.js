/*

(づ￣ ³￣)づ

IPFS (Shared) Worker.
Pretty much copied from an example on https://github.com/ipfs/js-ipfs

*/

import { Server, IPFSService } from "ipfs-message-port-server"


const PEER_WSS = "/dns4/node.fission.systems/tcp/4003/wss/p2p/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const DELEGATE_ADDR = "/dns4/ipfs.runfission.com/tcp/443/https"


const OPTIONS = {
  config: {
    Addresses: {
      Delegates: [ DELEGATE_ADDR ]
    },
    Bootstrap: [ PEER_WSS ],
    Discovery: {
      webRTCStar: { enabled: false }
    }
  },
  preload: {
    enabled: false
  }
}


importScripts("web_modules/ipfs.min.js")


const main = async (port) => {
  const IPFS = self.Ipfs
  self.initiated = true

  // Start listening to all the incoming connections (browsing contexts that
  // which run new SharedWorker...)
  // Note: It is important to start listening before we do any await to ensure
  // that connections aren't missed while awaiting.
  const connections = listen(self, "connect")

  // Start an IPFS node & create server that will expose it's API to all clients
  // over message channel.
  const ipfs = await IPFS.create(OPTIONS)
  const service = new IPFSService(ipfs)
  const server = new Server(service)

  console.log("🚀 Started IPFS node")

  self.ipfs = ipfs
  self.service = service
  self.server = server

  // Connect every queued and future connection to the server.
  if (port) {
    server.connect(port)
    return
  }

  for await (const event of connections) {
    const p = event.ports[0]
    if (p) server.connect(p)
  }
}


/**
 * Creates an AsyncIterable<Event> for all the events on the given `target` for
 * the given event `type`. It is like `target.addEventListener(type, listener, options)`
 * but instead of passing listener you get `AsyncIterable<Event>` instead.
 * @param {EventTarget} target
 * @param {string} type
 * @param {AddEventListenerOptions} options
 */
const listen = function (target, type, options) {
  const events = []
  let resume
  let ready = new Promise(resolve => (resume = resolve))

  const write = event => {
    events.push(event)
    resume()
  }

  const read = async () => {
    await ready
    ready = new Promise(resolve => (resume = resolve))
    return events.splice(0)
  }

  const reader = async function * () {
    try {
      while (true) {
        yield * await read()
      }
    } finally {
      target.removeEventListener(type, write, options)
    }
  }

  target.addEventListener(type, write, options)
  return reader()
}


self.addEventListener("message", setup)


function setup(event) {
  if (!self.initiated) main(event.ports[0])
  self.removeEventListener("message", setup)
}


if (typeof SharedWorkerGlobalScope === "function") main()
