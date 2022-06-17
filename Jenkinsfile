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
        containerTemplate(name: 'helm', image: "lachlanevenson/k8s-helm:v2.17.0", command: 'cat', ttyEnabled: true),
        containerTemplate(name: 'docker', image: 'docker:18', command: 'cat', ttyEnabled: true)
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
       when { branch 'main' }
       steps {
        script {
          new flowSemver().commitSemver(VERSION)
        }
      }
    }

    stage('Build and push docker image release') {
      when { branch 'main' }
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
      when { branch 'main' }
      steps {
        container('helm') {
          sh(script: """sed -i 's/^appVersion:.*\$/appVersion: "${VERSION.printable()}"/' deploy/aws-credentials-broker/Chart.yaml""") //XXX: This is the only way to actually set the app version with today's helm

          sh('helm init --client-only')
          withCredentials([usernamePassword(credentialsId: 'jenkins-x-jfrog', passwordVariable: 'JFROG_PASSWORD', usernameVariable: 'JFROG_USERNAME')]) {
            sh('helm repo add generic-charts-helm https://flow.jfrog.io/artifactory/api/helm/generic-charts-helm --username ${JFROG_USERNAME} --password ${JFROG_PASSWORD}')
          }
          sh("helm dep build deploy/aws-credentials-broker/")
          sh("tar -zxvf deploy/aws-credentials-broker/charts/* -C deploy/aws-credentials-broker/charts/ && rm -rf deploy/aws-credentials-broker/charts/*.tgz" )
          sh('helm plugin install https://github.com/futuresimple/helm-secrets || true')

          sh("helm secrets upgrade --dry-run --wait --install --debug  --namespace production --set deployments.live.version=${VERSION.printable()} aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")
          sh("helm secrets upgrade --wait --install --debug  --namespace production --set deployments.live.version=${VERSION.printable()} aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")
        }
      }
    }
  }
}
