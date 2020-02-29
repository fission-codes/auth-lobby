import { MessageType, ResData, ChildConnection } from './types'


function getConvoID(): string {
  const url = window.location.href
  return url.split('convoid=')[1].split('&')[0]
} 

export async function initConnection(): Promise<ChildConnection> {
  const convoID = getConvoID()
  const opener = window.opener

  return new Promise(resolve => {
    opener.postMessage({ 
      type: MessageType.Init,
      convoID
    }, "*")
    window.addEventListener('message', (evt) => {
      if(evt.data.convoID !== convoID){
        return
      }
      const { type } = evt.data
      if ( type === MessageType.Req){
        resolve({
          respond: getResFn(convoID, opener),
          req: evt.data.data
        })
      }
      if(type === MessageType.Close){
        window.close()
      }
    })
  })
}

function getResFn(convoID: string, opener: any) {
  return (res: ResData) => {
    const msg = {
      convoID,
      type: MessageType.Res,
      data: res
    }
    opener.postMessage(msg, '*')
  }
}

export default {
  initConnection
}
