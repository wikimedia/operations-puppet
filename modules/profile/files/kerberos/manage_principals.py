#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import os
import pexpect
import random
import smtplib
import socket
import string
import subprocess
import sys
import textwrap

from email.message import EmailMessage


def parse_args(argv):
    p = argparse.ArgumentParser()
    p.add_argument('--realm', action='store', default="WIKIMEDIA",
                   help='The Kerberos realm for which the user principals will be generated')
    p.add_argument('action', action='store', choices=['get', 'create', 'delete'],
                   help="Action to perform with the principal.")
    p.add_argument('principal', action='store',
                   help="Name of the Kerberos Principal to use (without @REALM suffix).")
    p.add_argument('--email_address', action='store',
                   help="Email address of the user to send the temporary password to.")

    args = p.parse_args(argv)
    return args


def create_user_principal(principal, password, realm):
    try:
        kadmin_local = pexpect.spawn(
            '/usr/sbin/kadmin.local add_principal +needchange +requires_preauth '
            + principal+'@'+realm)
        kadmin_local.expect('Enter password for principal .*:')
        kadmin_local.sendline(password)
        kadmin_local.expect('Re-enter password for principal .*:')
        kadmin_local.sendline(password)
        kadmin_local.wait()
        return 0
    except pexpect.ExceptionPexpect as e:
        print("Error while running kadmin.local: " + str(e))
        return -1


def delete_user_principal(principal, realm):
    try:
        return subprocess.Popen(
            ['/usr/sbin/kadmin.local', 'delete_principal', principal+'@'+realm])
    except subprocess.CalledProcessError as e:
        print("Error while running kadmin.local: " + str(e))
        return -1


def get_principal_info(principal, realm):
    try:
        subprocess.call(
            ['/usr/sbin/kadmin.local', 'get_principal', principal+'@'+realm])
    except subprocess.CalledProcessError as e:
        print("Error while running kadmin.local: " + str(e))
        return -1


def send_email(email_address, principal, password, realm):
    try:
        msg = EmailMessage()
        msg['From'] = 'root@' + socket.getfqdn()
        msg['To'] = email_address
        msg['Subject'] = "New Kerberos user {} created".format(principal)
        text_to_send = """
        Hi!

        If you are receiving this message it means that you requested
        a Kerberos account to use the Analytics Hadoop Test cluster.

        Your kerberos username is {}, that should be the same as the one
        that you use on Analytics Hadoop clients (like stat1007, etc..).
        If not, please reach out to the Analytics team for a follow up.

        Please ssh to any of the Hadoop client test hosts
        (like an-tool1006.eqiad.wmnet, etc..) and set you own password
        with the following command:

        kinit

        You will need to enter the following (temporary) password, that
        will enable you to set up your own final password (that only you
        will know):

        {}

        If you have any question, please contact the Analytics team.

        """.format(principal, password)
        msg.set_content(textwrap.dedent(text_to_send))
        smtp_sender = smtplib.SMTP('localhost')
        smtp_sender.send_message(msg)
        print("Successfully sent email to " + email_address)
        smtp_sender.quit()
    except smtplib.SMTPException as e:
        print(
            "Error: unable to send email to " + email_address + ". Reason: "
            + str(e) + "\nThe easiest option is to fix the problem with SMTP, and then "
            "delete and re-create the principal.")


def main():
    args = parse_args(sys.argv[1:])
    realm = args.realm.upper()
    action = args.action
    principal = args.principal
    email_address = args.email_address

    if action == "get":
        get_principal_info(principal, realm)
    elif action == "create":
        password = ''.join(
            [random.choice(string.ascii_letters + string.digits) for n in range(32)])
        ret = create_user_principal(principal, password, realm)
        if ret == 0:
            print("Principal successfully created.")
        else:
            sys.exit(1)
        if email_address:
            send_email(email_address, principal, password, realm)
    elif action == "delete":
        ret = delete_user_principal(principal, realm)
        if ret == 0:
            print("Principal successfully deleted.")
        else:
            sys.exit(1)


if __name__ == '__main__':
    if os.geteuid() != 0:
        print("Needs to be run as root")
        sys.exit(1)

    main()
