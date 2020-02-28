import { Permission, KeyMap } from '../ffs'

export interface Message {
  convoID: string
  type: MessageType
  data: ReqData | ResData | undefined
}

export interface Req extends Message {
  convoID: string
  type: MessageType.Req
  data: ReqData
}

export interface Res extends Message {
  convoID: string
  type: MessageType.Res
  data: ResData
}

export interface ReqData {
  readPermissions: Permission[]
  writePermissions: Permission[]
  readKey: string
  writeKey: string
}

export interface ResData {
  encryptedKeys: KeyMap
  readKey: string
}

export interface ChildConnection {
  respond: (res: ResData) => void
  req: ReqData
}

export enum MessageType {
  Init = 1,
  Req = 2,
  Res = 3,
  Close = 4,
}
