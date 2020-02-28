const WINDOW_SETTINGS = 'toolbar=no, menubar=no, width=600, height=700, top=100, left=100';

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
  readPermissions: Permission[]
  writePermissions: Permission[]
  readKey: string
  writeKey: string
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

export enum Permission {
  Music = 'music',
  Pictures = 'pictures',
  Document = 'documents'
}
