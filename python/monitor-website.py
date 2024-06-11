import requests
from send_email import SendEmail

# response = requests.get('http://fake.com:8080')

# if response.status_code == 200:
#     print('Application fine')
# else:
print('Application down')
send_email = SendEmail()
send_email.run('Subject', 'Body')
