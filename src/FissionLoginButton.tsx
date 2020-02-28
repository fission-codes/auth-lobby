import React from 'react'
import { requestPermissions } from './message/parent'
import { ResData } from './message/types'
import { Permission, KeyMap, decryptKeyMap } from './ffs'
import keystore from 'keystore-idb'
import { KeyStore } from 'keystore-idb/dist/types/types'

class FissionLoginButton extends React.Component<Props, State> {

  state: State = { 
    ks: null,
    readKey: null,
    writeKey: null,
    res: null,
    readKeys: null
  }

  async componentDidMount() {
    const ks = await keystore.init({ readKeyName: 'parent-read', writeKeyName: 'parent-write' })
    const readKey = await ks.publicReadKey()
    const writeKey = await ks.publicWriteKey()
    this.setState({ 
      ks,
      readKey,
      writeKey,
    })
  }

  decrypt = async (msg: string) => {
    const { ks, res } = this.state
    if(!res){
      throw new Error("cannot decrypt without read key")
    }
    if(!ks){
      throw new Error("no keystore")
    }
    return ks.decrypt(msg, res.readKey)
  }

  openPopup = async () => {
    const { readPermissions = [], writePermissions = [] } = this.props
    const { readKey, writeKey } = this.state
    if(!readKey || !writeKey){
      return
    }
    const req = { readPermissions, writePermissions, readKey, writeKey }
    const res = await requestPermissions(req)
    this.setState({ res })
    const keys = await decryptKeyMap(res.encryptedKeys, this.decrypt)
    this.props.onGrant(keys)
  }

  render() {
    return (
      <button onClick={this.openPopup}>
        Login
      </button>
    )
  }
}

interface Props {
  readPermissions?: Permission []
  writePermissions?: Permission []
  readKeyName?: string
  writeKeyName?: string
  onGrant: (keys: KeyMap) => any
}

interface State {
  ks: KeyStore | null
  readKey: string | null
  writeKey: string | null
  res: ResData | null
  readKeys: KeyMap | null
}

export default FissionLoginButton;
