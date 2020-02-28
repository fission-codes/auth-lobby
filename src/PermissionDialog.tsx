import React from 'react';
import { initConnection } from './messages';

class PermissionDialog extends React.Component<Props> {

  componentDidMount() {
    initConnection()
  }

  render() {
    return (
      <div>PERMISSIONS</div>
    )
  }
}

interface Props {}

export default PermissionDialog;
