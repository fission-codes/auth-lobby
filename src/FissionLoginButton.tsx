import React from 'react'
import { requestPermissions, Permission } from './messages'

class FissionLoginButton extends React.Component<Props> {
  constructor(props: Props){
    super(props)
  }

  openPopup = () => {
    const { readPermissions = [], writePermissions = [] } = this.props
    const req = {
      readPermissions,
      writePermissions,
      readKey: '',
      writeKey: '',
    }
    requestPermissions(req, (res) => {
      console.log("RES: ", res)
    })
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
}

export default FissionLoginButton;
