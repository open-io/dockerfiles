pipeline {
  agent any
  options {
    // Cleanup build older than 10 previous ones
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
    // Let's measure time
    timestamps()
    // Fail build if more than 10 minutes
    timeout(activity: true, time: 600, unit: 'SECONDS')
  }
  parameters {
    booleanParam(name: 'LATEST', defaultValue: false, description: 'Update tag "latest" to this version?')
    booleanParam(name: 'FORCE_DEPLOY', defaultValue: false, description: 'Force deployment step even if not on master branch?')
  }
  environment {
    PYTHONUNBUFFERED = '1'
    ANSIBLE_FORCE_COLOR = 'true'
  }
  triggers {
    cron('@weekly')
  }
  stages {
    stage('Shell Lint') {
      agent {
        label 'docker && small'
      }
      steps {
        sh '''
        docker run --rm -t -v ${WORKSPACE}:${WORKSPACE}:ro koalaman/shellcheck-alpine \
          sh -x -c "find ${WORKSPACE}/openio-sds -type f -name *.bats -or -name build.sh -or -name test.sh | grep -v ansible-playbook-openio-deployment \
          | xargs -I- shellcheck -"
        '''
      }
    } /* stage('Shell Lint') */
    stage('Build a SDS Release Docker Image') {
      matrix {
        axes {
          axis {
            name 'DOCKER_IMAGE_DIR'
            values 'openio-sds/20.04', 'openio-sds/19.10', 'openio-sds/19.04','openio-sds/18.10' //,'openio-sds/18.04' // 1804 disabled because packages are missing
          }
        }
        agent {
          dockerfile {
            label 'docker && big'
            dir "${DOCKER_IMAGE_DIR}/jenkins/"
            filename 'Dockerfile'
            args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
          }
        }
        environment {
          DOCKER_IMAGE_NAME = DOCKER_IMAGE_DIR.replaceAll("/","-")
          DOCKER_BUILD_CONTAINER_NAME = "${GIT_COMMIT.substring(0,6)}-${BUILD_ID}-${DOCKER_IMAGE_NAME}-build"
          DOCKER_TEST_CONTAINER_NAME = "${GIT_COMMIT.substring(0,6)}-${BUILD_ID}-${DOCKER_IMAGE_NAME}-test"
        }
        stages {
          stage('build') {
            steps {
              sh 'echo "Building Docker Image ${DOCKER_IMAGE_NAME} from ${DOCKER_IMAGE_DIR}"'
              sh 'bash ${WORKSPACE}/${DOCKER_IMAGE_DIR}/build.sh'
            }
            post {
              always {
                script {
                  // Cleanup with forced removal, and removal of volumes
                  sh '''
                  docker kill ${DOCKER_BUILD_CONTAINER_NAME} || true
                  docker rm -f -v ${DOCKER_BUILD_CONTAINER_NAME} || true
                  '''
                }
              }
            }
          } // stage('build')

          stage('test') {
            steps {
              sh 'echo "Testing Docker Image ${DOCKER_IMAGE_NAME} from ${DOCKER_IMAGE_DIR}"'
              sh 'bash ${WORKSPACE}/${DOCKER_IMAGE_DIR}/test.sh'
            }
            post {
              always {
                script {
                  // Cleanup with forced removal, and removal of volumes
                  sh '''
                  docker kill ${DOCKER_TEST_CONTAINER_NAME} || true
                  docker rm -f -v ${DOCKER_TEST_CONTAINER_NAME} || true
                  '''
                }
              }
            }
          } // stage('test')

          stage('deploy') {
            environment {
              LATEST = "${params.LATEST}"
              DOCKER_HUB = credentials('ID_HUB_DOCKER') // Defines DOCKER_HUB_USR and DOCKER_HUB_PSW env variables
            }
            steps {
              sh 'echo "Deploying Docker Image ${DOCKER_IMAGE_NAME} from ${DOCKER_IMAGE_DIR}"'

              // Log in local Docker to the remote registry
              sh 'echo ${DOCKER_HUB_PSW} | docker login --password-stdin -u ${DOCKER_HUB_USR}'

              sh 'bash ${WORKSPACE}/${DOCKER_IMAGE_DIR}/deploy.sh'
            }
            when {
              anyOf {
                branch 'master'
                buildingTag()
                expression { return params.FORCE_DEPLOY }
              }
            }
          } // stage('deploy')
        } // stages
        post {
          always {
            sh 'docker rmi -f ${DOCKER_IMAGE_NAME} || true'
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
