import org.jenkinsci.plugins.pipeline.modeldefinition.Utils
node {
    cleanWs()
    checkout scm
    docker.image('hashicorp/terraform:0.12.24').inside('--entrypoint=""') {
        withEnv(['TF_IN_AUTOMATION=true']) {
            stage('initialize') {
                sh 'terraform init'
            }
            stage('plan') {
                sh 'terraform plan'
            }
            stage('apply') {
                if (env.BRANCH_NAME == 'master') {
                    sh 'terraform apply -auto-approve'
                } else {
                    Utils.markStageSkippedForConditional('apply')
                }
            }
        }
    }
}
