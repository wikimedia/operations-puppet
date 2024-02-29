#! /usr/bin/python3
# -*- coding: utf-8 -*-

import os
import smtplib
import subprocess

from argparse import ArgumentParser, REMAINDER
from email.message import EmailMessage
from textwrap import dedent
from socket import getfqdn


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-T', '--mail-to', default='root@{}'.format(getfqdn()))
    parser.add_argument(
        '-s', '--subject', required=True, help="Add this string to the subject line"
    )
    parser.add_argument(
        '--only-on-error',
        action='store_true',
        help='Only send emails if the job errors',
    )
    parser.add_argument(
        '-F', '--mail-from', required=False,
        default='SYSTEMDTIMER <noreply@wikimedia.org>',
        help="Override the default Sender: and From: headers"
    )
    parser.add_argument('cmd', nargs=REMAINDER)
    return parser.parse_args()


def main():
    """Send out status for a systemd timer via mail"""

    args = get_args()
    ret = 0

    try:
        result = subprocess.check_output(args.cmd, stderr=subprocess.STDOUT)
    except FileNotFoundError as error:
        # This will cause the systemd unit to fail
        print("Failed to run command: {}", error)
        return 1
    except subprocess.CalledProcessError as error:
        output = error.output.decode()
        ret = error.returncode
    else:
        output = result.decode()

    # print the output so its captured in the journal
    print(output)
    if ret == 0 and args.only_on_error:
        return 0

    if output:
        status = 'PASS' if ret == 0 else 'FAIL'
        msg = EmailMessage()
        msg['From'] = args.mail_from
        # Set an explicit sender for hosts with stricter exim config
        # which requires both From and Sender headers to be routable. (T280744)
        msg['Sender'] = args.mail_from
        if os.getenv('MAILTO'):
            msg['To'] = os.getenv('MAILTO')
        else:
            msg['To'] = args.mail_to
        cmd_str = ' '.join(str(i) for i in args.cmd)
        body = dedent(
            """\
            Systemd timer ran the following command:

                {}

            Its return value was {} and emitted the following output:

            {}
            """).format(cmd_str, ret, output)
        msg['Subject'] = "{}: {}".format(status, args.subject)
        msg['Auto-Submitted'] = "auto-generated"
        msg.set_content(body)
        smtp = smtplib.SMTP('localhost')
        smtp.send_message(msg)
        smtp.quit()

    return ret


if __name__ == '__main__':
    raise SystemExit(main())
