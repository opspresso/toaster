#!groovy

echo "JOB_NAME    ${env.JOB_NAME}"
echo "BRANCH_NAME ${env.BRANCH_NAME}"
echo "GIT_COMMIT  ${env.GIT_COMMIT}"

properties([buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '10')), pipelineTriggers([])])

node {
    stage('Checkout') {
        checkout scm
    }

    stage('Build') {
        try {
            sh './package.sh'
            notify('Build Passed', 'good')
        } catch (e) {
            notify('Build Failed', 'danger')
            throw e
        }
    }

    stage('Publish') {
        archive 'target/*.zip'
    }
}

def notify(status, color) {
    if (color == 'danger' || env.BRANCH_NAME == 'master') {
        slackSend(color: color, message: "${status}: ${env.JOB_NAME} <${env.BUILD_URL}|#${env.BUILD_NUMBER}>")
    }
}
