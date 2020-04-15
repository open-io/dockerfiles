pipeline {
  agent none
  options {
    // Cleanup build older than 10 previous ones
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
    // Let's measure time
    timestamps()
    // Fail build if more than 10 minutes
    timeout(activity: true, time: 600, unit: 'SECONDS')
  }
  parameters {
    booleanParam(name: 'LATEST', defaultValue: false, description: 'Latest version ?')
  }
  environment {
    PYTHONUNBUFFERED = '1'
    ANSIBLE_FORCE_COLOR = 'true'
  }
  triggers {
    cron('@weekly')
  }
  stages {
    stage('Build a SDS Release Docker Image') {
      matrix {
        axes {
          axis {
            name 'SDS_RELEASE'
            values '19.10','19.04','18.10', '18.04'
          }
        }
        agent {
          dockerfile {
            label 'docker'
            dir './openio-sds/jenkins-agent/'
            filename 'Dockerfile'
            args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
          }
        }
        stages {
          stage('build') {
            steps {
              echo "SDS_RELEASE=${SDS_RELEASE}"
              dir(path: "openio-sds/${SDS_RELEASE}/centos/7") {
                sh 'bash ./build.sh'
              }
            }
          } // stage('build')
          stage('run & check') {
            environment {
              SUT_ID = "${GIT_COMMIT.substring(0,6)}-${SDS_RELEASE}"
            }
            options {
              retry(5)
            }
            steps {
              sh '''
                docker run -d --name "${SUT_ID}" "openio/sds:${SDS_RELEASE}"
                SUT_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${SUT_ID})"
                SUT_ID=${SUT_ID} SUT_IP=${SUT_IP} bats "${WORKSPACE}"/openio-sds/checks.bats
              '''
              post {
                always {
                  script {
                    sh '''
                    docker kill ${SUT_ID}
                    docker rm ${SUT_ID}
                    docker rmi openio/sds:${SDS_RELEASE}
                    '''
                  }
                }
              }
            }
          } // stage('run & check')
          // stage('docker push') {
          //   steps {
          //     withCredentials([usernamePassword(credentialsId: 'ID_HUB_DOCKER', usernameVariable: 'docker_user', passwordVariable: 'docker_pass')]) {
          //           sh "echo \${docker_pass} | docker login --password-stdin -u \${docker_user}"
          //         }
          //     script {
          //       sh "docker push openio/sds:${SDS_RELEASE}"

          //       if (params.LATEST) {
          //         sh "docker tag openio/sds:${SDS_RELEASE} openio/sds:latest"
          //         sh "docker push openio/sds:latest"

          //       }
          //     }
          //   }
          // } // stage('docker push')
        } // stages
        post {
          always {
            sh 'chmod -R 777 ${WORKSPACE}'
            cleanWs()
          }
        } // post
      } // matrix
    } // stage('Build a SDS Release Docker Image')
  } // stages
  post {
    failure {
      slackMessageUserMention("Build Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.RUN_DISPLAY_URL}|Open>) is ${currentBuild.result}", '#AA0000')
    }
    success {
      slackMessageUserMention("Build Success - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.RUN_DISPLAY_URL}|Open>) is ${currentBuild.result}", '#008800')
    }
  }
}
