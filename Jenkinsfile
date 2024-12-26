pipeline {
    agent any
    parameters {
        text(name: 'ANSIBLE_IP', description: 'Enter your ansible ip:')
        choice(
            choices: ['prod'],
            description: 'Select an env:',
            name: 'ENV'
        )
    }
    environment {
        ENV = "${params.ENV}"
        ANSIBLE_IP = "${params.ANSIBLE_IP}"
        REMOTE_USER = "${env.REMOTE_USER}"
        TF_VAR_domain_name = "${env.DOMAIN_NAME}"
        TF_VAR_public_ssh_key  = "${env.PUBLIC_SSH_KEY}"
        TF_VAR_do_token     = "${env.DO_TOKEN}"
    }
    stages {
        stage('provisioning server') {
            steps {
                script {
                    dir("terraform/$ENV") {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        env.WEB_IP = sh(script: 'terraform output web_ip', returnStdout: true).trim()
                        env.WORKER_IP = sh(script: 'terraform output worker_ip', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('copying files to ansible server') {
            steps {
                script {
                    sh "scp -r -o StrictHostKeyChecking=no ./* $REMOTE_USER@$ANSIBLE_IP:/home/$REMOTE_USER"
                }
            }
        }
        stage('deploying sports app') {
            steps {
                script {
                    def remote = [:]
                    remote.name = "ansible"
                    remote.host = "$ANSIBLE_IP"
                    remote.allowAnyHosts = true
                    remote.user = "$REMOTE_USER"
                    remote.identityFile = "/var/jenkins_home/.ssh/id_rsa"
                    sshCommand remote: remote, command: "./bin/infra_cli.rb -c run -i $WEB_IP -m web -e $ENV"
                    sshCommand remote: remote, command: "./bin/infra_cli.rb -c run -i $WORKER_IP -m worker -e $ENV"
                }
            }
        }
        stage('destroy sports app?') {
            steps {
                script {
                    def userInput = input(
                        message: 'Do you want to destroy the sports app?',
                        parameters: [booleanParam(defaultValue: false, description: 'Destroy sports app?', name: 'DESTROY_SPORTS_APP')]
                    )
                    if (userInput) {
                        echo 'Destroying sports app...'
                        dir("terraform/$ENV") {
                            sh "terraform destroy --auto-approve"
                        }
                    }
                }
            }
        }
    }
}