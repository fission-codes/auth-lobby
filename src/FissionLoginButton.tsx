import React from 'react'
import { requestPermissions } from './message/parent'
import { Permission } from './message/types'

class FissionLoginButton extends React.Component<Props> {
  constructor(props: Props){
    super(props)
  }

  openPopup = async () => {
    const { readPermissions = [], writePermissions = [] } = this.props
    const req = {
      readPermissions,
      writePermissions,
      readKey: '',
      writeKey: '',
    }
    const res = await requestPermissions(req)
    console.log('RES: ', res)
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
