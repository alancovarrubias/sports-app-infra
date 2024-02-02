pipeline {
    agent any
    stages {
        stage('provisioning server') {
            environment {
                TF_VAR_domain_name = "${env.DOMAIN_NAME}"
                TF_VAR_public_ssh_key  = "${env.PUBLIC_SSH_KEY}"
                TF_VAR_do_token     = "${env.DO_TOKEN}"
            }
            steps {
                script {
                    dir('terraform/sports_app') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        env.SERVER_IP = sh(script: 'terraform output server_ip', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('copying files to ansible server') {
            environment {
                ANSIBLE_IP = "${env.ANSIBLE_IP}"
                REMOTE_USER = "${env.REMOTE_USER}"
            }
            steps {
                script {
                    sh "scp -r -o StrictHostKeyChecking=no ansible/* $REMOTE_USER@$ANSIBLE_IP:/home/$REMOTE_USER"
                }
            }
        }
        stage('deploying sports app') {
            environment {
                ANSIBLE_IP = "${env.ANSIBLE_IP}"
                REMOTE_USER = "${env.REMOTE_USER}"
            }
            steps {
                script {
                    def remote = [:]
                    remote.name = "ansible_server"
                    remote.host = "$ANSIBLE_IP"
                    remote.allowAnyHosts = true
                    remote.user = "$REMOTE_USER"
                    remote.identityFile = "/var/jenkins_home/.ssh/id_rsa"
                    sshCommand remote: remote, command: "ansible-playbook --inventory $SERVER_IP, --extra-vars @extra_vars.yml deploy_app.yml"
                }
            }
        }
        stage('destroy sports app?') {
            environment {
                TF_VAR_domain_name = "${env.DOMAIN_NAME}"
                TF_VAR_public_ssh_key  = "${env.PUBLIC_SSH_KEY}"
                TF_VAR_do_token     = "${env.DO_TOKEN}"
            }
            steps {
                script {
                    def userInput = input(
                        message: 'Do you want to destroy the sports app?',
                        parameters: [booleanParam(defaultValue: false, description: 'Destroy sports app?', name: 'DESTROY_SPORTS_APP')]
                    )
                    if (userInput) {
                        echo 'Destroying sports app...'
                        dir('terraform/sports_app') {
                            sh "terraform destroy --auto-approve"
                        }
                    }
                }
            }
        }
    }
}