from flask_mail import Message
from app import mail
from flask import render_template
from app import app
from threading import Thread
import logging

def send_email(subject, sender, recipients, text_body, html_body):
    print("SENDING EMAIL", app.config['MAIL_USERNAME'], app.config['MAIL_SERVER'])
    msg = Message(subject, sender=sender, recipients=recipients)
    msg.body = text_body
    msg.html = html_body
    send_async_email(app, msg)
    #Thread(target=send_async_email, args=(app,msg)).start()

def send_password_reset_email(user, email):
    token = user.get_reset_password_token()
    send_email('(2bij3) Wachtwoord opnieuw instellen',
               sender=app.config['ADMINS'][0],
               recipients=[email],
               text_body=render_template('email/reset_password.txt',
                                         user=user, token=token),
               html_body = render_template('email/reset_password.html',
                                           user=user, token=token))


def send_registration_confirmation(user, email):
    send_email('2bij3 registratie voltooid - activeer jouw account',
               sender=app.config['ADMINS'][0],
               recipients=[email],
               text_body = render_template('email/registration_confirmation.txt',
                                           user=user),
               html_body = render_template('email/registration_confirmation.html',
                                            user=user))
def send_async_email(app, msg):
    with app.app_context():
        print("Sending email...", app.config['MAIL_USERNAME'])
        try:
            mail.send(msg)
        except Exception:
            print("Oops!")
            logging.exception("Error sending email!")
            raise
        print("Email sent!")
