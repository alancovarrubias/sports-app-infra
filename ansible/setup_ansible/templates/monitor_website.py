import requests
from send_email import SendEmail
import paramiko
import schedule

send_email = SendEmail()
def restart_server():
    print('Restarting server')
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname="{{ web_ip }}", username="{{ user_name }}", key_filename="/home/{{ user_name }}/.ssh/id_rsa")
    stdin, stdout, stderr = ssh.exec_command("cd {{ repo_name }} && docker-compose up -d")
    print(stdout.readlines())
    ssh.close()

def monitor_website():
    try:
        response = requests.get("http://{{ web_ip }}")
        if response.status_code == 200:
            print('Application fine')
        else:
            print('Application down')
            send_email.run('SITE DOWN', f'Application returned {response.status_code}')
            restart_server()
    except Exception as ex:
        msg = 'Application not accessible'
        print(msg)
        send_email.run('Connection error', msg)
        restart_server()

schedule.every(5).minutes.do(monitor_website)

while True:
    schedule.run_pending()