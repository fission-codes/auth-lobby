import { ReqData, ResData, MessageType } from './types'

const WINDOW_SETTINGS = 'toolbar=no, menubar=no, width=600, height=700, top=100, left=100';

function generateConvoID(){
  return Date.now()
} 

export async function requestPermissions(req: ReqData): Promise<ResData> {
  return new Promise((resolve, reject) => {
    const convoID = generateConvoID()
    const w = window.open(
      `http://localhost:3000/login?convoid=${convoID}`,
      "Fission Login",
      WINDOW_SETTINGS
    )
    if(!w){
      return reject(new Error("Could not open window"))
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
        resolve(res)
      }
    })
  })
}

export default {
  requestPermissions
}
