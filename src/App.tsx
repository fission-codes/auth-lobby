import React from 'react'
import ParentApp from './ParentApp'
import ChildApp from './ChildApp'

class App extends React.Component {
  render() {
    const path = window.location.pathname
    if(path === '/login'){
      return <ChildApp />
    }else{
      return <ParentApp />
    }
  }
}

export default App;
