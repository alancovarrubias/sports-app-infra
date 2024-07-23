import requests
from send_email import SendEmail
import paramiko

send_email = SendEmail()
def read_server():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname='138.68.16.95', username='alancovarrubias', key_filename='/Users/alancovarrubias/.ssh/id_rsa')
    stdin, stdout, stderr = ssh.exec_command('docker ps')
    print(stdout.readlines())
    ssh.close()

read_server()
try:
    print('Attempting')
    response = requests.get('http://138.68.16.95:3000')
    print('Completed')
    if response.status_code == 200:
        print('Application fine')
    else:
        print('Application down')
        send_email.run('SITE DOWN', f'Application returned {response.status_code}')
except Exception as ex:
    print(ex)
    send_email.run('Connection error', 'Application not accessible')
