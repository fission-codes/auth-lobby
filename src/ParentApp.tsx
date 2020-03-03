import React from 'react'
import { redirectReq, parseKeyFromRes } from './redirect/parent'
import keystore from 'keystore-idb'
import { KeyStore } from 'keystore-idb/dist/types/types'

class ParentApp extends React.Component<Props, State> {

  state: State = {
    ks: null,
    readKey: null,
    symmKey: null,
  }

  async componentDidMount() {
    const ks = await keystore.init({ readKeyName: 'parent-read', writeKeyName: 'parent-write' })
    const symmKey = await parseKeyFromRes(ks)
    if(symmKey){
      return this.setState({ symmKey })
    }
    const readKey = await ks.publicReadKey()
    this.setState({ 
      ks,
      readKey,
    })
  }

  redirect = async () => {
    const folderCID = 'abcdefg'
    const { readKey } = this.state
    if(!readKey){
      throw new Error("Could not retrieve read key")
    }
    redirectReq(folderCID, readKey)
  }

  render() {
    const { symmKey } = this.state
    if(!symmKey){
      return(
        <button onClick={this.redirect}>
          Login
        </button>
      )
    } else{
      return (
        <div>
          <h2>Logged In!</h2>
          <h4>SymmKey</h4>
          {symmKey}
        </div>
      )
    }
  }
}

interface Props {}

interface State {
  ks: KeyStore | null
  readKey: string | null
  symmKey: string | null
}

export default ParentApp;
