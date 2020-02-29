import React from 'react'
import { initConnection } from './message/child'
import { ChildConnection, ReqData } from './message/types'
import { encryptReadKeys, getWriteToken, Permission } from './ffs'
import keystore from 'keystore-idb'
import { KeyStore } from 'keystore-idb/dist/types/types'

class PermissionDialog extends React.Component<Props, State> {

  state: State = {
    ks: null,
    conn: null,
    req: null,
  }

  async componentDidMount() {
    const ks = await keystore.init({ readKeyName: 'child-read', writeKeyName: 'child-write' })
    this.setState({ ks })
    await this.connect()
  }

  connect = async () => {
    const conn = await initConnection()
    const req = conn.req
    this.setState({ conn, req })
  }

  encrypt = async (msg: string): Promise<string> => {
    const { ks, conn, req } = this.state
    if(!conn || !req){
      throw new Error("not connected")
    }
    if(!ks){
      throw new Error("could not load keystore")
    }
    return ks.encrypt(msg, req.readKey)
  }

  sign = async (msg: string): Promise<string> => {
    const { ks } = this.state
    if(!ks){
      throw new Error("could not load keystore")
    }
    return ks.sign(msg)
  }

  grant = async () => {
    const { ks, conn, req } = this.state
    if(!conn || !req){
      throw new Error("not connected")
    }
    if(!ks){
      throw new Error("could not load keystore")
    }
    const encryptedKeys = await encryptReadKeys(req.readPermissions, this.encrypt)
    const writeToken = await getWriteToken(req.writePermissions, this.sign)
    const [readKey, writeKey] = await Promise.all([
      ks.publicReadKey(),
      ks.publicWriteKey()
    ])
    const res = {
      encryptedKeys,
      writeToken,
      readKey,
      writeKey,
    }
    
    await conn.respond(res)
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
            <PermissionList 
              title="Read Permissions"
              permissions={this.state.req.readPermissions}
            />
            <PermissionList 
              title="Write Permissions"
              permissions={this.state.req.writePermissions}
            />
            <h3>Requesting Keys</h3>
            <h4>Read:</h4> {this.state.req.readKey}
            <h4>Write:</h4> { this.state.req.writeKey}
            <br />
            <button onClick={this.grant}>Grant Permission</button>
          </div>
        }
      </div>
    )
  }
}

const PermissionList = (props: {
  title: string
  permissions: Permission[]
}) => (
  <div>
    <h4>{props.title}</h4>
    <ul>
      {props.permissions.map(perm => <li key={perm}>{perm}</li>)}
    </ul>
  </div>
)

interface Props {}

interface State {
  conn: ChildConnection | null
  ks: KeyStore | null
  req: ReqData | null
}

export default PermissionDialog;
