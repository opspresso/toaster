#!groovy

//echo "JOB_NAME    ${env.JOB_NAME}"
//echo "BRANCH_NAME ${env.BRANCH_NAME}"

properties([
        buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '10')),
        pipelineTriggers([[$class: 'SCMTrigger', scmpoll_spec: 'H/5 * * * *']])
])

node {
    stage('Checkout') {
        checkout scm
    }

    stage('Build') {
        try {
            sh './package.sh'
            sh './publish.sh'
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
    slackSend(color: color, message: "${status}: ${env.JOB_NAME} <${env.BUILD_URL}|#${env.BUILD_NUMBER}>")
}
