import React from 'react';
import ReactDOM from "react-dom";
import { map } from 'lodash';

import {
  Error,
  RoleRow,
  RoleAssumed,
  AccountRoleGroup,
  RoleSelectionForm
} from './components';

class App extends React.Component {
  render() {
    const accountsMap = JSON.parse(document.getElementById("roles").textContent);

    let content;
    if(accountsMap.success) {
      content = <RoleAssumed />
    } else if(accountsMap.error) {
      content = <Error message={accountsMap.error} />
    } else {
      content = (
        <RoleSelectionForm>
          {map(Object.keys(accountsMap), account => (
            <AccountRoleGroup account={account}>
              {map(accountsMap[account], (props) => (<RoleRow {...props} />))}
            </AccountRoleGroup>
          ))}
        </RoleSelectionForm>
      );
    }

    return (
      <div id="container">
        <div id="header">
          <img src="/dist/img/aws_logo_smile.png" alt="AWS logo" width="84" height="50" />
        </div>
        <div id="content">{content}</div>
        <div id="footer">
          <small>Made by</small>
          <div>
            <a href="https://flow.io"><img src="/dist/img/flow-logo-icon-only-color.png" width="30px" alt="Flow Commerce" /></a>
          </div>
        </div>
      </div>
    );
  }
}

ReactDOM.render(<App />, document.getElementById("app"));
