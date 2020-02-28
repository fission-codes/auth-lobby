import React from 'react';
import { initConnection } from './message/child';

class PermissionDialog extends React.Component<Props> {

  async componentDidMount() {
    const conn = await initConnection()
    console.log("CONN: ", conn)

    const { readPermissions, writePermissions, readKey, writeKey } = conn.req
    const res = {
      readPermissions,
      writePermissions,
      readKey: readKey + 'asdfasdf',
      writeKey: writeKey + 'asdfasdf'
    }
    conn.respond(res)
  }

  render() {
    return (
      <div>PERMISSIONS</div>
    )
  }
}

interface Props {}

export default PermissionDialog;
