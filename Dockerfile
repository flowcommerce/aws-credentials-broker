# Build the Go App
FROM golang:1.24 AS go-builder

COPY . /usr/src/aws-credentials-broker
WORKDIR /usr/src/aws-credentials-broker
RUN GOBIN=/usr/bin go install -v

# Build the React frontend
FROM node:lts-alpine AS fe-builder

COPY public /usr/src/aws-credentials-broker/public
COPY .babelrc /usr/src/aws-credentials-broker/.babelrc
COPY package.json /usr/src/aws-credentials-broker/package.json
COPY package-lock.json /usr/src/aws-credentials-broker/package-lock.json
COPY templates/img /usr/src/aws-credentials-broker/templates/img
WORKDIR /usr/src/aws-credentials-broker
RUN apk add --no-cache --virtual .gyp \
        python3 \
        make \
        g++ && \ 
  npm install && \
  npm run build 

# Put it all together for a runtime app
# The binary is at /usr/bin/aws-credentials-broker and the runtime data is at /var, per FHS.
FROM golang:1.24

COPY --from=go-builder /usr/bin/aws-credentials-broker /usr/bin/aws-credentials-broker
COPY --from=fe-builder /usr/src/aws-credentials-broker/templates /var/lib/aws-credentials-broker/templates

EXPOSE 8234

WORKDIR /var/lib/aws-credentials-broker
ENTRYPOINT ["/usr/bin/aws-credentials-broker"]
