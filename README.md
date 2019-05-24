# aws-credentials-broker

[![Build Status](https://travis-ci.com/flowcommerce/aws-credentials-broker.svg?token=ehYmhiZsnqWFWAoybfVc&branch=master)](https://travis-ci.com/flowcommerce/aws-credentials-broker)

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

NOTE: By default the custom schema in Google directory should be in the following format

```
"customSchemas": {
  "AWS_SAML": {
    "SessionDuration": "3600",
    "IAM_role": [
      {
        "value": "arn:aws:iam::xxx:role/admin,arn:aws:iam::xxx:saml-provider/gsuite"
      }
    ]
  }
}
```

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
