FROM golang:1.10.3-alpine3.7 AS builder

RUN apk update && \
  apk add --no-cache --update alpine-sdk git && \
  go get -u github.com/golang/dep/cmd/dep

ARG VERSION

COPY . /go/src/github.com/flowcommerce/aws-credentials-broker
RUN cd /go/src/github.com/flowcommerce/aws-credentials-broker && make release-binary VERSION=${VERSION}

FROM alpine:3.7
# OIDC connectors require root certificates.
# Proper installations should manage those certificates, but it's a bad user
# experience when this doesn't work out of the box.
#
# OpenSSL is required so wget can query HTTPS endpoints for health checking.
RUN apk add --update ca-certificates openssl

WORKDIR /usr/local/bin

COPY --from=builder /go/bin/aws-credentials-broker /usr/local/bin/aws-credentials-broker

EXPOSE 8234

ENTRYPOINT ["aws-credentials-broker"]
