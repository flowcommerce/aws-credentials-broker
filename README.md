# aws-credentials-broker

AWS Credentials Broker - Grants temporary AWS credentials for Google federated users

This app when deployed in your AWS account can grant STS credentials to Google SAML federated users for use in the AWS CLI.
The flow is as follows:

- CLI directs users to the broker, for example https://aws-credentials-broker.example.org?callback_uri=http://localhost:1234.
- The aws-credentials-broker uses its Google OAuth2 client credentials to initiate the OpenID Connect (OIDC) credentials flow.
- Once a user has authenticated with Google, aws-credentials-broker uses its Google Admin Serive Account User to list the SAML roles associated with the authenticated user.
- If the user has more than one account/role pair, a UI allows them to choose the account & role to assume.
- When a user picks an account & role to assume the OIDC token granted by Google for the user is used with AWS to grant temporary credentials to the federated user.
- The `callback_uri` is called with the STS credentials to store in the users' `~/.aws/credentials` file.

# Getting Started

## Google Setup

1. Create Google OAuth 2.0 client ID
2. Create Google Service Account
3. Setup Google Admin API Access - To read user SAML roles
    - Enable the Admin SDK in Google Develper Console
    - Enable Domain-wide Delegation for our service account user
    - Enable API access in Google Admin
    - In Google Admin > Manage API client access. Grant our service account client id the scope `https://www.googleapis.com/auth/admin.directory.user.readonly`

### OAuth client (Flow production)

The live OAuth 2.0 client lives in GCP project number `636048119203`. Manage
it (including authorized redirect URIs) at:

https://console.cloud.google.com/apis/credentials?project=636048119203

The "Authorized redirect URIs" list must contain one entry per region we
serve, matching `GOOGLE_CLIENT_REDIRECT` in `deploy/aws-credentials-broker/values.yaml`:

- `https://aws-credentials-broker.flow.io/oauth/google/callback` (us-east-1)
- `https://aws-credentials-broker.us-east-2.flow.io/oauth/google/callback` (us-east-2 failover)

The client ID and secret are stored in the `aws-credentials-broker` Kubernetes
secret in the `production` namespace (keys `google_client_id` and
`google_client_secret`).

#### Who can edit it

The project has no direct IAM bindings — access is inherited from its parent,
GCP organization `321690732161` (the flow.io org). To see (or grant) who can
edit the OAuth client, use the org-level IAM pages, making sure the console
org picker is set to flow.io rather than to the project:

- Members and their roles: https://console.cloud.google.com/iam-admin/iam?organizationId=321690732161
  — switch the table to "View by roles" and look for `roles/resourcemanager.organizationAdmin`,
  `roles/iam.securityAdmin`, and any project-scoped grants of `roles/oauthconfig.editor`
  on project `636048119203`.
- Custom and predefined role definitions: https://console.cloud.google.com/iam-admin/roles?organizationId=321690732161

A Google Workspace Super Admin does *not* automatically have access here;
Workspace and GCP IAM are separate systems. A Super Admin can bootstrap
themselves into `roles/resourcemanager.organizationAdmin` on the linked Cloud
org by following the
[organization setup guide](https://cloud.google.com/resource-manager/docs/creating-managing-organization#setting-up),
after which they can grant `roles/oauthconfig.editor` on project
`636048119203` to whoever needs to edit redirect URIs.

## AWS Setup

Assuming you already have a SAML provider & roles setup for Google federated users. You need to add a trust relationship for out Google Client ID.

In our role we want to give to users, we need to edit the trust relationship policy document to add the following:

```
{
  "Version": "2012-10-17",
  "Statement": [
    ...
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:aud": "<our new google client id>"
        }
      }
    }
    ...
  ]
}
```

## Environment variables

| Key                    | Description                                                                                                |
|------------------------|------------------------------------------------------------------------------------------------------------|
| ALLOWED_ORIGIN         | The URL of our broker app (e.g. https://aws-credentials-broker.example.org)                                |
| GOOGLE_ADMIN_EMAIL     | The email address of a Google Apps admin user (e.g. administrator@example.org)                             |
| GOOGLE_CLIENT_ID       | The Google OAuth2 client ID                                                                                |
| GOOGLE_CLIENT_REDIRECT | The callback URL of our broker app (e.g. https://aws-credentials-broker.example.org/oauth/google/callback) |
| GOOGLE_CLIENT_SECRET   | The Google OAuth2 client secret                                                                            |
| GOOGLE_SA_EMAIL        | The Google Service Account User email                                                                      |
| GOOGLE_SA_PK           | The Google Service Account User private key, base64 encoded                                                |
| HOSTED_DOMAIN          | The Google domain to filter users for, ignored if left blank (Optional)                                    |

