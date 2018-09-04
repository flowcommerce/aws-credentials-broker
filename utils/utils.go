package utils

import (
	"crypto/rand"
	"encoding/json"
	"io/ioutil"

	"golang.org/x/oauth2"
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

func RandToken(l int) []byte {
	b := make([]byte, l)
	rand.Read(b)
	return b
}

func GetUserRoles(accessToken string, conf *oauth2.Config) (*UserRoles, error) {
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

	srv, err := admin.New(client)
	if err != nil {
		return nil, err
	}

	response, err := srv.Users.Get(usr.Email).CustomFieldMask("AWS_SAML").Projection("custom").Do()
	if err != nil {
		return nil, err
	}

	var rls Roles
	err = json.Unmarshal(response.CustomSchemas["AWS_SAML"], &rls)
	if err != nil {
		return nil, err
	}

	return &UserRoles{usr, rls}, nil
}
