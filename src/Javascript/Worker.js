/*

(づ￣ ³￣)づ

IPFS (Shared) Worker.
Pretty much copied from an example on https://github.com/ipfs/js-ipfs

*/

import localforage from "localforage"
import { Server, IPFSService } from "ipfs-message-port-server"


const KEEP_ALIVE_INTERVAL =
  1 * 60 * 1000 // 1 minute

const OPTIONS = {
  config: {
    Addresses: {
      Delegates: []
    },
    Bootstrap: [],
    Discovery: {
      webRTCStar: { enabled: false }
    }
  },
  preload: {
    enabled: false
  }
}

let peers = Promise.resolve(
  []
)


importScripts("web_modules/ipfs.min.js")


const main = async (port) => {
  const IPFS = self.Ipfs
  self.initiated = true

  // Start listening to all the incoming connections (browsing contexts that
  // which run new SharedWorker...)
  // Note: It is important to start listening before we do any await to ensure
  // that connections aren't missed while awaiting.
  const connections = listen(self, "connect")

  // Fetch the list of peers
  peers = await localforage.getItem("ipfsPeers")

  if (peers) {
    peers = peers.split(",")

    fetchPeers().then(list =>
      localforage.setItem("ipfsPeers", list.join(","))
    )

  } else {
    peers = await fetchPeers()
    localforage.setItem("ipfsPeers", peers.join(","))

  }

  if (peers.length === 0) {
    throw new Error("💥 Couldn't start IPFS node, peer list is empty")
  }

  // Start an IPFS node & create server that will expose it's API to all clients
  // over message channel.
  const ipfs = await IPFS.create(OPTIONS)
  const service = new IPFSService(ipfs)
  const server = new Server(service)

  self.ipfs = ipfs
  self.service = service
  self.server = server

  peers.forEach(peer => {
    ipfs.swarm
      .connect(peer)
      .then(() => console.log(`🪐 Connected to ${peer}`))
      .catch(() => {})
  })

  console.log("🚀 Started IPFS node")

  // Ensure permanent connection to Fission gateway
  // TODO: This is a temporary solution while we wait for
  //       https://github.com/libp2p/js-libp2p/issues/744
  //       (see "Keep alive" bit)
  peers.forEach(peer => {
    setTimeout(() => keepAlive(peer), KEEP_ALIVE_INTERVAL)
  })

  // Connect every queued and future connection to the server.
  if (port) {
    server.connect(port)
    return
  }

  for await (const event of connections) {
    const p = event.ports && event.ports[0]
    if (p) server.connect(p)
  }
}


function fetchPeers() {
  const peersUrl = location.hostname === "localhost" || location.hostname === "auth.runfission.net"
      ? "https://runfission.net/ipfs/peers"
      : "https://runfission.com/ipfs/peers"

  return fetch(peersUrl)
    .then(r => r.json())
    .then(r => r.filter(p => p.includes("/wss/")))
    .catch(e => { throw new Error("💥 Couldn't start IPFS node, failed to fetch peer list") })
}


async function keepAlive(peer) {
  const timeoutId = setTimeout(() => reconnect(peer), 30 * 1000)

  self.ipfs.libp2p.ping(peer).then(() => {
    clearTimeout(timeoutId)
  }).catch(() => {}).finally(() => {
    setTimeout(() => keepAlive(peer), KEEP_ALIVE_INTERVAL)
  })
}


async function reconnect(peer) {
  await self.ipfs.swarm.disconnect(peer)
  await self.ipfs.swarm.connect(peer)
}


self.reconnect = reconnect


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
  if (!self.initiated) main(event.ports && event.ports[0])
  self.removeEventListener("message", setup)
}


if (typeof SharedWorkerGlobalScope === "function") main()
