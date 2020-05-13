/*

| (• ◡•)| (❍ᴥ❍ʋ)

*/

const PEER_WSS = "/dns4/node.fission.systems/tcp/4003/wss/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"
const PEER_TCP = "/ip4/3.215.160.238/tcp/4001/ipfs/QmVLEz2SxoNiFnuyLpbXsH6SvjPTrHNMU88vCQZyhgBzgw"

let ipfs


// 🚀


getIpfs.default().then(i => {
  ipfs = i

  bootElm()
  bootIpfs()
})



// ELM


function bootElm() {
  Elm.Main.init()
}



// IPFS

function bootIpfs() {
  console.log(ipfs)
}
