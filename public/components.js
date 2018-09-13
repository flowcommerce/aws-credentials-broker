import React from 'react';

export const RoleRow = ({ arn, name }) => (
  <div className="role flex-item">
    <input type="radio" name="role" value={arn} /> {name}
  </div>
);

export const AccountRoleGroup = ({ account, children }) => (
  <div className="account flex-item">
    <h2>Account: {account}</h2>
    <hr />
    <div className="flex-container">
      {children}
    </div>
  </div>
);

export const RoleSelectionForm = ({ children }) => (
  <form method="POST" action="/login">
    <h2>Select a role:</h2>
    <div className="flex-container">{children}</div>
    <div className="flex-container">
      <button className="flex-item signIn" type="submit">Sign In</button>
    </div>
  </form>
);

export const RoleAssumed = () => <div style={{ textAlign: 'center', width: '100%' }}>Successfully assumed role! You can close this window now.</div>

export const Error = ({ message }) => (
  <div>
    <h2>Error:</h2>
    <div className="flex-container">{message}</div>
  </div>
);
