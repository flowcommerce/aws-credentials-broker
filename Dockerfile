FROM golang:1.10.3-alpine3.7 AS builder

RUN apk update && \
  apk add --no-cache --update alpine-sdk git && \
  go get -u github.com/golang/dep/cmd/dep

ARG VERSION

COPY . /go/src/github.com/flowcommerce/aws-credentials-broker
RUN cd /go/src/github.com/flowcommerce/aws-credentials-broker && make release-binary VERSION=${VERSION}

FROM flowdocker/play:0.1.3

WORKDIR /usr/local/bin

COPY --from=builder /go/bin/aws-credentials-broker /usr/local/bin/aws-credentials-broker

EXPOSE 8234

ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "aws-credentials-broker", "/usr/local/bin/aws-credentials-broker"]
