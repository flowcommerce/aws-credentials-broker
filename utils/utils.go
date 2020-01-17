package utils

import (
	"crypto/rand"
	"encoding/json"
	"io/ioutil"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"golang.org/x/oauth2/jwt"
	admin "google.golang.org/api/admin/directory/v1"
)

type User struct {
	Email string `json:"email"`
}

type RoleValue struct {
	Value string `json:"value"`
}

type Roles struct {
	SessionDuration string      `json:"SessionDuration"`
	Roles           []RoleValue `json:"IAM_role"`
}

type UserRoles struct {
	User  User  `json:"user"`
	Roles Roles `json:"roles"`
}

type AdminUserConfig struct {
	Email      string
	PrivateKey []byte
	AdminEmail string
}

func RandToken(l int) []byte {
	b := make([]byte, l)
	rand.Read(b)
	return b
}

func getGoogleAdminUserRoles(usrKey string, config *AdminUserConfig) (*Roles, error) {
	var customSchemaKey = os.Getenv("CUSTOM_SCHEMA_KEY")
	if customSchemaKey == "" {
		customSchemaKey = "AWS_SAML"
	}

	c := &jwt.Config{
		Email:      config.Email,
		PrivateKey: config.PrivateKey,
		Scopes:     []string{"https://www.googleapis.com/auth/admin.directory.user.readonly"},
		TokenURL:   google.JWTTokenURL,
		Subject:    config.AdminEmail,
	}

	adminClient := c.Client(oauth2.NoContext)
	srv, err := admin.New(adminClient)
	if err != nil {
		return nil, err
	}

	response, err := srv.Users.Get(usrKey).
		CustomFieldMask(customSchemaKey).
		Projection("custom").
		Do()
	if err != nil {
		return nil, err
	}

	var rls Roles
	err = json.Unmarshal(response.CustomSchemas[customSchemaKey], &rls)
	if err != nil {
		return nil, err
	}

	return &rls, nil
}

func GetUserRoles(accessToken string, conf *oauth2.Config, config *AdminUserConfig) (*UserRoles, error) {
	tok := &oauth2.Token{AccessToken: accessToken}
	client := conf.Client(oauth2.NoContext, tok)
	email, err := client.Get("https://www.googleapis.com/oauth2/v3/userinfo")
	if err != nil {
		return nil, err
	}
	defer email.Body.Close()
	data, _ := ioutil.ReadAll(email.Body)

	var usr User
	if err = json.Unmarshal(data, &usr); err != nil {
		return nil, err
	}

	rls, err := getGoogleAdminUserRoles(usr.Email, config)
	if err != nil {
		return nil, err
	}

	return &UserRoles{usr, *rls}, nil
}
