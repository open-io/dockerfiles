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
  triggers {
    cron('@weekly')
  }
  stages {
    stage('Shell Lint') {
      agent {
        label 'docker'
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
            name 'SDS_VERSION'
            values '20.04', '19.10', '19.04','18.10'
          }
        }
        agent {
          label 'docker && big'
        }
        environment {
          DOCKER_IMAGE_NAME = DOCKER_IMAGE_DIR.replaceAll("/","-")
          DOCKER_BUILD_CONTAINER_NAME = "${GIT_COMMIT.substring(0,6)}-${BUILD_ID}-${DOCKER_IMAGE_NAME}-build"
          COMPOSE_PROJECT_NAME = "${GIT_COMMIT.substring(0,6)}-${BUILD_ID}-${DOCKER_IMAGE_NAME}".replaceAll(".","")
          DOCKER_IMAGE_DIR = "openio-sds/${SDS_VERSION}"
          PYTHONUNBUFFERED = '1'
          ANSIBLE_FORCE_COLOR = 'true'
        }
        stages {
          stage('build') {
            steps {
              sh 'echo "Building Docker Image ${DOCKER_IMAGE_NAME} from ${DOCKER_IMAGE_DIR}"'
              sh '''
              docker build -t "openio-sds-docker-builder:${SDS_VERSION}" "./openio-sds/${SDS_VERSION}/jenkins/"
              docker run --rm -t -u root \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v "$(pwd):$(pwd)" -w "$(pwd)" \
                -e DOCKER_BUILD_CONTAINER_NAME \
                -e DOCKER_IMAGE_NAME \
                "openio-sds-docker-builder:${SDS_VERSION}" \
                  bash "./openio-sds/${SDS_VERSION}/build.sh"
              '''
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
                  sh 'docker ps | grep ${COMPOSE_PROJECT_NAME} | awk \'{print $1}\' | xargs --no-run-if-empty docker kill'
                  sh "docker system prune -f --volumes"
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
