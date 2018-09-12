import React from 'react';
import ReactDOM from "react-dom";
import { map } from 'lodash';

class App extends React.Component {
  render() {
    const accountsMap = JSON.parse(document.getElementById("roles").textContent);

    let content;
    if(accountsMap.success) {
      content = <div style={{ textAlign: 'center', width: '100%' }}>Successfully assumed role! You can close this window now.</div>
    } else {
      const accounts = map(Object.keys(accountsMap), account => (
        <div className="account flex-item">
          <h2>Account: {account}</h2>
          <hr />
          <div className="flex-container">
            {map(accountsMap[account], ({ arn, name }) => (
              <div className="role flex-item">
                <input type="radio" name="role" value={arn} /> {name}
              </div>
            ))}
          </div>
        </div>
      ));

      content = (
        <form method="POST" action="/login">
          <h2>Select a role:</h2>
          <div className="flex-container">{accounts}</div>
          <div className="flex-container">
            <button className="flex-item signIn" type="submit">Sign In</button>
          </div>
        </form>
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
