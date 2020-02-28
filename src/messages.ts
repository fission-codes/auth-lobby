const WINDOW_SETTINGS = 'toolbar=no, menubar=no, width=600, height=700, top=100, left=100';

export type Message = {
  convoID: string
  type: MessageType
  data: PermissionReq | PermissionRes | undefined
}

export type PermissionReq = {
  readPermissions: Permission[]
  writePermissions: Permission[]
  readKey: string
  writeKey: string
}

export type PermissionRes = {
  readPermissions: Permission[]
  writePermissions: Permission[]
  readKey: string
  writeKey: string
}

export enum MessageType {
  Init = 1,
  Req = 2,
  Res = 3,
  Close = 4,
}

export enum Permission {
  Music = 'music',
  Pictures = 'pictures',
  Document = 'documents'
}

const generateConvoID = () => Date.now()
const convoIDFromURL = (url: string) => url.split('convoid=')[1].split('&')[0]

export const initConnection = () => {
  const convoID = convoIDFromURL(window.location.href)
  const opener = window.opener
  opener.postMessage({ 
    type: MessageType.Init,
    convoID
  }, "*")
  window.addEventListener('message', (evt) => {
    const { type, convoID } = evt.data
    if(convoID !== convoID){
      return
    }
    if ( type === MessageType.Req){
      const { readPermissions, writePermissions, readKey, writeKey } = evt.data.data
      const res = {
        readPermissions,
        writePermissions,
        readKey: readKey + 'asdfasdf',
        writeKey: writeKey + 'asdfasdf'
      }
      const msg = {
        convoID,
        type: MessageType.Res,
        data: res
      }
      opener.postMessage(msg, '*')
    }
    if(type === MessageType.Close){
      window.close()
    }
  })
}

export const requestPermissions = (req: PermissionReq, cb: (res: PermissionRes) => any) => {
  const convoID = generateConvoID()
  const w = window.open(`http://localhost:3000/login?convoid=${convoID}`, "Fission Login", WINDOW_SETTINGS)
  if(!w){
    throw new Error("Could not open window")
  }
  window.addEventListener('message', (evt) => {
    const { type, convoID } = evt.data
    if(convoID !== convoID){
      return
    }
    if( type === MessageType.Init) {
      const msg = {
        convoID,
        type: MessageType.Req,
        data: req
      }
      w.postMessage(msg, '*')
    }
    if( type === MessageType.Res) {
      const res = evt.data.data
      const msg = {
        convoID,
        type: MessageType.Close
      }
      w.postMessage(msg, '*')
      cb(res)
    }
  })
}

export default {
  requestPermissions
}
