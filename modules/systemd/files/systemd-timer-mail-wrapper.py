#! /usr/bin/python3
# -*- coding: utf-8 -*-

import os
import smtplib
import subprocess
import sys
from email.message import EmailMessage
from socket import getfqdn


def main():
    """Send out status for a systemd timer via mail
    """

    if len(sys.argv) == 1:
        sys.exit(1)

    ret = 0
    cmd = sys.argv[1:]

    try:
        result = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except FileNotFoundError as e:
        print("Failed to run command: {}", e)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        output = e.output.decode()
        ret = e.returncode
    else:
        output = result.decode()

    if output:
        msg = EmailMessage()
        msg['From'] = 'SYSTEMDTIMER <noreply@{}>'.format(getfqdn())
        if os.getenv('MAILTO'):
            msg['To'] = os.getenv('MAILTO')
        else:
            msg['To'] = 'root@{}'.format(getfqdn())
        cmd_str = ' '.join([str(i) for i in cmd])
        msg['Subject'] = "Output of systemd timer for '{}'".format(cmd_str)
        msg.set_content(output)
        smtp = smtplib.SMTP('localhost')
        smtp.send_message(msg)
        smtp.quit()

    sys.exit(ret)


if __name__ == '__main__':
    main()
