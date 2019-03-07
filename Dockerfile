# Build the Go App
FROM golang:1.11 AS go-builder

RUN apt-get update && \
  apt-get install git && \
  go get -u github.com/golang/dep/cmd/dep

ARG VERSION

COPY . /go/src/github.com/flowcommerce/aws-credentials-broker
RUN cd /go/src/github.com/flowcommerce/aws-credentials-broker && make release-binary VERSION=${VERSION}

# Build the React frontend
FROM node:lts-alpine AS fe-builder

COPY public /go/src/github.com/flowcommerce/aws-credentials-broker/public
COPY .babelrc /go/src/github.com/flowcommerce/aws-credentials-broker/.babelrc
COPY package.json /go/src/github.com/flowcommerce/aws-credentials-broker/package.json
COPY package-lock.json /go/src/github.com/flowcommerce/aws-credentials-broker/package-lock.json
COPY templates/img /go/src/github.com/flowcommerce/aws-credentials-broker/templates/img
RUN cd /go/src/github.com/flowcommerce/aws-credentials-broker && npm install && npm run build

# Put it all together for a runtime app
FROM golang:1.11

WORKDIR /usr/local/bin

COPY --from=go-builder /go/bin/aws-credentials-broker /usr/local/bin/aws-credentials-broker
COPY --from=fe-builder /go/src/github.com/flowcommerce/aws-credentials-broker/templates /usr/local/bin/templates

EXPOSE 8234

ENTRYPOINT ["/usr/local/bin/aws-credentials-broker"]
