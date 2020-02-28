import React from 'react';
import FissionLoginButton from './FissionLoginButton'
import { Permission, KeyMap } from './ffs'

class App extends React.Component<Props, State> {

  state: State = {
    keys: null
  }

  onGrant = (keys: KeyMap) => {
    this.setState({ keys })
  }

  render() {
    const { keys } = this.state

    return (
      <div>
        <FissionLoginButton 
          readPermissions={[Permission.Document, Permission.Music]}
          writePermissions={[Permission.Document]}
          onGrant={this.onGrant}
        />
        {keys &&
          <div>
            <h4>Read Keys</h4>
            <ul>
              { Object.keys(keys).map(perm => <li key={perm}>{perm}: {keys[perm]}</li>)}
            </ul>
          </div>
        }
      </div>
    )
  }
}

interface Props {}

interface State {
  keys: KeyMap | null
}


export default App;
