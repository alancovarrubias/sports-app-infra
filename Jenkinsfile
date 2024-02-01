pipeline {
    agent any
    stages {
        stage('provision server') {
            environment {
                TF_VAR_domain_name = "${env.DOMAIN_NAME}"
                TF_VAR_public_ssh_key  = "${env.PUBLIC_SSH_KEY}"
                TF_VAR_do_token     = "${env.DO_TOKEN}"
            }
            steps {
                script {
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        env.SERVER_IP = sh(script: 'terraform output server_ip', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('copy files to ansible server') {
            environment {
                ANSIBLE_IP = "${env.ANSIBLE_IP}"
                REMOTE_USER = "${env.REMOTE_USER}"
            }
            steps {
                script {
                    sh "scp -r -o StrictHostKeyChecking=no ansible/* $REMOTE_USER@$ANSIBLE_IP:/home/alan"
                    sh "scp -r -o StrictHostKeyChecking=no /var/jenkins_home/.ssh/id_rsa* $REMOTE_USER@$ANSIBLE_IP:/home/alan/.ssh"
                    def remote = [:]
                    remote.name = "ansible_server"
                    remote.host = "$ANSIBLE_IP"
                    remote.allowAnyHosts = true
                    remote.user = "$REMOTE_USER"
                    remote.identityFile = "/var/jenkins_home/.ssh/id_rsa"
                    sshCommand remote: remote, command: "ansible-playbook --inventory $SERVER_IP, -e target_host_ip=$SERVER_IP --private-key ~/.ssh/id_rsa --user root deploy_app.yml"
                }
            }
        }
    }
}