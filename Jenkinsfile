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
      inheritFrom 'kaniko-slim'

      containerTemplates([
        containerTemplate(name: 'helm', image: "flowcommerce/k8s-build-helm2:0.0.48", command: 'cat', ttyEnabled: true)
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
        container('kaniko') {
          script {
            semver = VERSION.printable()

            sh """
              /kaniko/executor -f `pwd`/Dockerfile -c `pwd` \
              --snapshot-mode=redo --use-new-run  \
              --destination ${env.ORG}/aws-credentials-broker:$semver
            """

          }
        }
      }
    }

    stage('Deploy Helm chart') {
      when { branch 'main' }
      steps {
        container('helm') {
          sh(script: """sed -i 's/^appVersion:.*\$/appVersion: "${VERSION.printable()}"/' deploy/aws-credentials-broker*/Chart.yaml""") //XXX: This is the only way to actually set the app version with today's helm

          sh('helm init --client-only')
          sh('helm plugin install https://github.com/futuresimple/helm-secrets || true')

          sh("helm secrets upgrade --dry-run --wait --install --debug  --namespace production --set deployments.live.version=${VERSION.printable()} aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")
          sh("helm secrets upgrade --wait --install --debug  --namespace production --set deployments.live.version=${VERSION.printable()} aws-credentials-broker -f deploy/aws-credentials-broker/secrets.yaml ./deploy/aws-credentials-broker")
        }
      }
    }
  }
}
