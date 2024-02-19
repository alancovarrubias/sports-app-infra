pipeline {
    agent any
    parameters {
        text(name: 'ANSIBLE_IP', description: 'Enter your ansible ip:')
    }
    stages {
        stage('provisioning server') {
            environment {
                TF_VAR_domain_name = "${env.DOMAIN_NAME}"
                TF_VAR_public_ssh_key  = "${env.PUBLIC_SSH_KEY}"
                TF_VAR_do_token     = "${env.DO_TOKEN}"
            }
            steps {
                script {
                    dir('terraform/prod') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        env.WEB_IP = sh(script: 'terraform output web_ip', returnStdout: true).trim()
                        env.WORKER_IP = sh(script: 'terraform output worker_ip', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('copying files to ansible server') {
            environment {
                REMOTE_USER = "${env.REMOTE_USER}"
            }
            steps {
                script {
                    sh "scp -r -o StrictHostKeyChecking=no ansible/* $REMOTE_USER@${params.ANSIBLE_IP}:/home/$REMOTE_USER"
                }
            }
        }
        stage('deploying sports app') {
            environment {
                REMOTE_USER = "${env.REMOTE_USER}"
            }
            steps {
                script {
                    def remote = [:]
                    remote.name = "ansible_server"
                    remote.host = "${params.ANSIBLE_IP}"
                    remote.allowAnyHosts = true
                    remote.user = "$REMOTE_USER"
                    remote.identityFile = "/var/jenkins_home/.ssh/id_rsa"
                    sshCommand remote: remote, command: "ansible-playbook --inventory $WEB_IP, --extra-vars @extra_vars.yml setup_prod.yml"
                    sshCommand remote: remote, command: "ansible-playbook --inventory $WORKER_IP, --extra-vars @extra_vars.yml -e web_ip=$WEB_IP setup_worker.yml"
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
                        dir('terraform/prod') {
                            sh "terraform destroy --auto-approve"
                        }
                    }
                }
            }
        }
    }
}