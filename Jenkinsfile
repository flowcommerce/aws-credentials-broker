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
        containerTemplate(name: 'helm', image: "grahamar/k8s-helm-secrets:v2.13.0", command: 'cat', ttyEnabled: true),
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
          VERSION = new flowSemver().calculateSemver()
        }
      }
    }

    stage('Commit SemVer tag') {
       when { branch 'master' }
       steps {
        script {
          new flowSemver().commitSemver(VERSION)
        }
      }
    }

    stage('Build and push docker image release') {
      when { branch 'master' }
      steps {
        container('docker') {
          script {
            semver = VERSION.printable()

            docker.withRegistry('https://index.docker.io/v1/', 'jenkins-dockerhub') {
              db = docker.build("$ORG/$APP_NAME:$semver", '--network=host -f Dockerfile .')
              db.push()
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
          sh('helm plugin install https://github.com/futuresimple/helm-secrets || true')
          withAWS(role: 'arn:aws:iam::479720515435:role/cicd20181011095611663000000001', roleAccount: '479720515435') {
            sh("helm secrets upgrade --wait --install --namespace production --set deployments.live.version=${VERSION.printable()} aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")
          }
        }
      }
    }
  }
}
