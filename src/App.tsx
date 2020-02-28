import React from 'react';
import FissionLoginButton from './FissionLoginButton'
import PermissionDialog from './PermissionDialog'
import { Permission } from './message/types'

function App() {
  // Placerholder
  // These will be on different domains
  const path = window.location.pathname
  console.log(window.location)
  if(path === '/login'){
    return(
      <div>
        <PermissionDialog />
      </div>
    )
  }else{
    return(
      <div>
        <FissionLoginButton 
          readPermissions={[Permission.Document, Permission.Music]}
          writePermissions={[Permission.Document]}
        />
      </div>
    )
  }
}

export default App;
