import React from 'react'
import { ReqQuery, parseReq, redirectRes } from './redirect/parent'
import keystore from 'keystore-idb'
import { KeyStore } from 'keystore-idb/dist/types/types'

class ChildApp extends React.Component<Props, State> {

  state: State = {
    ks: null,
    req: null
  }

  async componentDidMount() {
    const ks = await keystore.init({ readKeyName: 'child-read', writeKeyName: 'child-write' })
    const req = parseReq()
    this.setState({ ks, req })
  }

  grant = async () => {
    const { ks, req } = this.state
    redirectRes(ks, req)
  }

  render() {
    return (
      <div>
        <h2>Grant Permissions</h2>
        {!this.state.req &&
          <div>Loading.....</div>
        }
        {this.state.req && 
          <div>
            <strong>{this.state.req.redirect}</strong>
            <span> is requesting permission to view your private folder at </span>
            <strong>{this.state.req.folderCID}</strong>
            <br /> <br />
            <button onClick={this.grant}>Grant Permission</button>
          </div>
        }
      </div>
    )
  }
}

interface Props {}

interface State {
  ks: KeyStore | null
  req: ReqQuery | null
}

export default ChildApp;
