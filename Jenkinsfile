properties([pipelineTriggers([githubPush()])])

pipeline {
  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 30, unit: 'MINUTES')
  }

  agent {
    kubernetes {
      label 'worker-aws-credentials-broker'
      inheritFrom 'default'

      containerTemplates([
        containerTemplate(name: 'helm', image: "lachlanevenson/k8s-helm:v2.12.0", command: 'cat', ttyEnabled: true),
        containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true)
      ])
    }
  }

  environment {
    ORG      = 'flowcommerce'
    APP_NAME = 'aws-credentials-broker'
  }

  stages {
    stage('Checkout') {
      steps {
        checkoutWithTags scm
        script {
          APP_TAG = sh(returnStdout: true, script: 'git describe --tags --dirty --always').trim()
        }
      }
    }

    stage('Build and push docker image release') {
      when { branch 'master' }
      steps {
        container('docker') {
          script {

            docker.withRegistry('', 'docker-hub-credentials') {
              aws-credentials-broker = docker.build("$ORG/aws-credentials-broker:$APP_TAG", '-f Dockerfile .')
              aws-credentials-broker.push()
            }

          }
        }
      }
    }

    stage('Deploy Helm chart') {
      when { branch 'master' }
      steps {
        container('helm') {
          sh('helm init --client-only')
          sh('helm plugin install https://github.com/futuresimple/helm-secrets')
          sh("helm secrets upgrade --wait --install --namespace production --set deployments.live.version=$APP_TAG aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")

        }
      }
    }
  }
}