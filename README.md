# aws-credentials-broker
AWS Credentials Broker - Manages temporary AWS credentials for Google

# Getting Started

## Google Setup

1. Create Google OAuth 2.0 client ID
2. Create Google Service Account
3. Setup Google Admin API Access - To read user SAML roles
    - Enable the Admin SDK in Google Develper Console
    - Enable Domain-wide Delegation for our service account user
    - Enable API access in Google Admin
    - In Google Admin > Manage API client access. Grant our service account client id the scope `https://www.googleapis.com/auth/admin.directory.user.readonly`

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

