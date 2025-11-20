pipeline {
  agent any

  environment {
    AWS_REGION      = "ap-south-1"
    MODULES_GIT_URL = "https://github.com/GalamManesha/modules.git"
    MODULES_BRANCH  = "main"
  }

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  stages {
    stage('Checkout repo (contains module/main.tf)') {
      steps {
        // checkout the repo that triggered the build (should contain module/main.tf)
        checkout scm
      }
    }

    stage('Fetch modules repo into module/modules/module') {
      steps {
        script {
          sh '''
            set -e
            tmpdir=$(mktemp -d)
            git clone --depth 1 --branch ${MODULES_BRANCH} ${MODULES_GIT_URL} "$tmpdir"
            mkdir -p module/modules/module
            if [ -d "$tmpdir/module" ]; then
              rsync -a --delete "$tmpdir/module/" module/modules/module/
            else
              echo "ERROR: expected folder 'module' not found in modules repo root."
              ls -la "$tmpdir"
              rm -rf "$tmpdir"
              exit 1
            fi
            rm -rf "$tmpdir"
          '''
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('module') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-cred'
          ]]) {
            sh '''
              set -e
              terraform --version
              terraform init -input=false -no-color
            '''
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('module') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-cred'
          ]]) {
            sh '''
              set -e
              terraform plan -out=tfplan -input=false -no-color
              terraform show -no-color tfplan > plan.txt || true
            '''
            archiveArtifacts artifacts: 'module/plan.txt', onlyIfSuccessful: true
          }
        }
      }
    }

    stage('Terraform Apply (auto-approve)') {
      steps {
        dir('module') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-cred'
          ]]) {
            sh '''
              set -e
              terraform apply -input=false -auto-approve tfplan
            '''
          }
        }
      }
    }
  }

  post {
    always {
      dir('module') {
        sh 'terraform state list || true'
      }
    }
    success {
      echo "Terraform apply completed successfully."
    }
    failure {
      echo "Pipeline failed — check logs."
    }
  }
}
