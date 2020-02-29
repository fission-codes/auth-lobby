import React from 'react';
import FissionLoginButton from './FissionLoginButton'
import { Permission, KeyMap } from './ffs'

class ParentApp extends React.Component<Props, State> {

  state: State = {
    keys: null,
    writeToken: null
  }

  onGrant = (keys: KeyMap, writeToken: string) => {
    this.setState({ keys, writeToken })
  }

  render() {
    const { keys } = this.state
    if(!keys){
      return(
        <FissionLoginButton 
          readPermissions={[Permission.Document, Permission.Music]}
          writePermissions={[Permission.Document]}
          onGrant={this.onGrant}
        />
      )
    } else{
      return (
        <div>
          <h2>Logged In!</h2>
          <h4>Read Keys</h4>
          <ul>
            { Object.keys(keys).map(perm => <li key={perm}>{perm}: {keys[perm]}</li>)}
          </ul>
          <h4>Write Token</h4>
          {this.state.writeToken}
        </div>
      )
    }
  }
}

interface Props {}

interface State {
  keys: KeyMap | null
  writeToken: string | null
}

export default ParentApp;
