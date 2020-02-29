export enum Permission {
  Music = 'music',
  Pictures = 'pictures',
  Document = 'documents'
}

export type KeyMap  = {
  [perm: string]: string
}

export async function encryptReadKeys(permissions: Permission[], encryptFn:(msg: string) => Promise<string>): Promise<KeyMap> {
  const encrypted = {} as KeyMap
  for(let i =0; i< permissions.length; i++){
    const perm = permissions[i]
    const key = await encryptFn(MockReadKeys[perm] || '')
    encrypted[perm] = key
  }
  return encrypted
}

export async function decryptKeyMap(keymap: KeyMap, decryptFn:(msg: string) => Promise<string>): Promise<KeyMap> {
  const decrypted = {} as KeyMap
  const permissions = Object.keys(keymap)
  for(let i =0; i< permissions.length; i++){
    const perm = permissions[i]
    const encrypted = keymap[perm]
    const key = await decryptFn(encrypted ||'')
    decrypted[perm] = key
  }
  return decrypted
}

export async function getWriteToken(permissions: Permission[], signFn: (msg: string) => Promise<string>): Promise<string> {
  const signature = await signFn(MockWriteToken)
  return MockWriteToken + "." + signature
}

export async function verifyWriteToken(token: string, verifyFn: (msg: string, sig: string) => Promise<boolean>): Promise<boolean> {
  const parts = token.split('.')
  if(parts.length !== 2){
    throw new Error("invalid token")
  }
  return verifyFn(parts[0], parts[1])
}

export const MockReadKeys = {
  [Permission.Music]: window.btoa('MusicReadKey'),
  [Permission.Pictures]: window.btoa('PicturesReadKey'),
  [Permission.Document]: window.btoa('DocumentReadKey')
}

export const MockWriteToken = window.btoa('Write token that grants various permissions')
