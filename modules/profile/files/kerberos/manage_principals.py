#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
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
    p.add_argument('action', action='store',
                   choices=['get', 'list', 'create', 'delete', 'reset-password'],
                   help="Action to perform with the principal.")
    p.add_argument('principal', action='store',
                   help="Name of the Kerberos Principal to use (without @REALM suffix). "
                   "The list command also works with wildcards like the char '*'.")
    p.add_argument('--email_address', action='store',
                   help="Email address of the user to send the temporary password to. "
                   "Required for some actions.")

    args = p.parse_args(argv)

    if args.action in {'reset-password', 'create'} and not args.email_address:
        p.error(f'{args.action} requires an argument for --email_address')
        sys.exit(1)

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


def delete_principal(principal, realm):
    try:
        if '@' + realm in principal:
            principal_to_del = principal
        else:
            principal_to_del = principal + '@' + realm
        return subprocess.call(
            ['/usr/sbin/kadmin.local', 'delete_principal', principal_to_del])
    except subprocess.CalledProcessError as e:
        print("Error while running kadmin.local: " + str(e))
        return -1


def does_principal_exist(principal, realm):
    try:
        subprocess.check_output(
            ['/usr/sbin/kadmin.local', 'get_principal', principal+'@'+realm],
            stderr=subprocess.STDOUT)
        return True
    except subprocess.CalledProcessError:
        return False


def list_principals(principal_pattern):
    try:
        subprocess.call(
            ['/usr/sbin/kadmin.local', 'list_principals', principal_pattern])
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


def send_email(email_address, principal, password, subject):
    try:
        msg = EmailMessage()
        msg['From'] = 'root@' + socket.getfqdn()
        msg['To'] = email_address
        msg['Subject'] = subject
        text_to_send = """
        Hi!

        If you are receiving this message it means that you requested
        a Kerberos account within the Wikimedia Foundation production
        servers.

        Your kerberos username is {}, that should be the same as the one
        that you use on Analytics Hadoop clients (like stat1007, etc..).
        If not, please reach out to the Analytics team for a follow up.

        Please ssh to any of the Hadoop client hosts
        (like stat1005.eqiad.wmnet, stat1008.eqiad.wmnet, etc..) and set your
        own password with the following command:

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


def generate_temporary_password():
    return ''.join(
        [random.choice(string.ascii_letters + string.digits) for n in range(32)])


def reset_password(principal, password, realm):
    try:
        kadmin_local = pexpect.spawn(
            '/usr/sbin/kadmin.local change_password ' + principal+'@'+realm)
        kadmin_local.expect('Enter password for principal .*:')
        kadmin_local.sendline(password)
        kadmin_local.expect('Re-enter password for principal .*:')
        kadmin_local.sendline(password)
        kadmin_local.wait()
    except pexpect.ExceptionPexpect as e:
        print("Error while running kadmin.local: " + str(e))
        return -1

    try:
        return subprocess.call(
            ['/usr/sbin/kadmin.local', 'modify_principal', '+needchange', principal+'@'+realm])
    except subprocess.CalledProcessError as e:
        print("Error while running kadmin.local: " + str(e))
        return -1


def main():
    args = parse_args(sys.argv[1:])
    realm = args.realm.upper()
    action = args.action
    principal = args.principal
    email_address = args.email_address

    if action == "get":
        get_principal_info(principal, realm)
    elif action == 'list':
        list_principals(principal)
    elif action == "create":
        if does_principal_exist(principal, realm):
            print("Principal already created (or an error occurred with kadmin), skipping.")
            sys.exit(1)
        password = generate_temporary_password()
        ret = create_user_principal(principal, password, realm)
        if ret == 0:
            print("Principal successfully created. Make sure to update data.yaml in Puppet.")
        else:
            sys.exit(1)

        subject = "New Kerberos user {} created".format(principal)
        send_email(email_address, principal, password, subject=subject)
    elif action == "delete":
        ret = delete_principal(principal, realm)
        if ret == 0:
            delete_msg = "Principal successfully deleted."
            if '/' not in principal:
                delete_msg += (" Since the principal seems to be related to a user, "
                               "make sure to update the krb flag in Puppet's data.yaml.")
            print(delete_msg)
        else:
            sys.exit(1)
    elif action == "reset-password":
        password = generate_temporary_password()

        ret = reset_password(principal, password, realm)

        if ret == 0:
            print("Password reset successfully.")
        else:
            print("Password reset errored.")
            sys.exit(1)

        subject = "Kerberos password reset for user {}".format(principal)
        send_email(email_address, principal, password, subject=subject)


if __name__ == '__main__':
    if os.geteuid() != 0:
        print("Needs to be run as root")
        sys.exit(1)

    main()
