pipeline {
  agent any

  stages {
    stage('Build') {
      steps {
        lock(resource: "janus_${env.NODE_NAME}") {
          ansiColor('xterm') {
            sh './jenkins-build.sh'
          }
        }
      }
    }
  }
}
