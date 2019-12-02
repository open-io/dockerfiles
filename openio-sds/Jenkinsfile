pipeline {
  agent any
  parameters {
    choice(name: 'SDS_RELEASE', choices: ['19.10','19.04','18.10', '18.04'], description: 'Openio release')
    booleanParam(name: 'LATEST', defaultValue: false, description: 'Latest version ?')
  }
  environment {
    PYTHONUNBUFFERED = '1'
    ANSIBLE_FORCE_COLOR = 'true'
  }
  triggers {
        parameterizedCron('''
45 13 * * 2 %SDS_RELEASE=19.10;LATEST=true
0 14 * * 2 %SDS_RELEASE=19.04;LATEST=false
15 14 * * 2 %SDS_RELEASE=18.10;LATEST=false
30 14 * * 2 %SDS_RELEASE=18.04;LATEST=false
        ''')
  }
  stages {
    stage('build') {
      steps {
        dir(path: "openio-sds/${SDS_RELEASE}/centos/7") {
          sh 'pwd'
          sh "echo ${SDS_RELEASE}"
          sh './build.sh'
        }

      }
    }
    stage('run & check') {
      steps {
        script {
          SUT_ID = sh(returnStdout: true, script: "docker run -d openio/sds:${SDS_RELEASE}").trim()
          SUT_IP = sh(returnStdout: true, script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${SUT_ID}").trim()

        }
        retry(5) {
          sh "SUT_ID=${SUT_ID} SUT_IP=${SUT_IP} bats openio-sds/checks.bats"
        }
      }
    }
    stage('docker push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'ID_HUB_DOCKER', usernameVariable: 'docker_user', passwordVariable: 'docker_pass')]) {
              sh "echo \${docker_pass} | docker login --password-stdin -u \${docker_user}"
            }
        script {
          sh "docker push openio/sds:${SDS_RELEASE}"

          if (params.LATEST) {
            sh "docker tag openio/sds:${SDS_RELEASE} openio/sds:latest"
            sh "docker push openio/sds:latest"

          }
        }
      }
    }
  }
  post {
    always {
      cleanWs()
      script {
        if (env.SUT_ID) { sh "docker stop ${SUT_ID} && docker rm ${SUT_ID} && docker rmi openio/sds:${SDS_RELEASE}" }
      }
    }
  }
}
