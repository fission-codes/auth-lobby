import React from 'react';
import ParentApp from './ParentApp'
import PermissionDialog from './PermissionDialog'

class App extends React.Component {
  render() {
    // Placeholder
    // These will be on different domains
    const path = window.location.pathname
    if(path === '/login'){
      return <PermissionDialog />
    }else{
      return <ParentApp />
    }
  }
}

export default App;
