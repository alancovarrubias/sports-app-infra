import requests
from send_email import SendEmail

send_email = SendEmail()
try:
    response = requests.get('http://fake.com:8080')
    if response.status_code == 200:
        print('Application fine')
    else:
        print('Application down')
        send_email.run('SITE DOWN', f'Application returned {response.status_code}')
except Exception as ex:
    print(ex)
    send_email.run('Connection error', 'Application not accessible')
