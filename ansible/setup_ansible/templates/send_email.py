import smtplib
import os
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class SendEmail:
    def __init__(self) -> None:
        self.address = os.environ.get('EMAIL_ADDRESS')
        self.password = os.environ.get('EMAIL_PASSWORD')
    
    def run(self, subject, body):
        msg = self.create_msg(subject,  body)
        with smtplib.SMTP('smtp.mail.me.com', 587) as smtp:
            smtp.starttls(context=ssl.create_default_context())
            smtp.login(self.address, self.password)
            smtp.sendmail(from_addr=self.address, to_addrs=self.address, msg=msg.as_string())

    def create_msg(self, subject, body):
        msg = MIMEMultipart()
        msg["From"] = self.address
        msg["To"] = self.address
        msg["Subject"] = subject
        msg.attach(MIMEText(body, "plain"))
        return msg
