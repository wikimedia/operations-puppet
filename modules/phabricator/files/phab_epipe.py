#!/usr/bin/env python3
"""2014 Chase Pettet <cpettet@wikimedia.org>

This script acts as an intermediary between an MTA and phabricator providing
some extra functionality and raw email piping.

* deliver to phabricator handler

Looks for configuration file: /etc/phab_epipe.conf

    [default]
    # if 'true' will reject all email to phab
    maint = false
    # saves every message to /tmp/phabmail_*
    save = false
    # saves particular messages from a comma
    # separated list of users
    debug = <emails_to_dump_for_debug>
"""
import os
import subprocess
import sys
import syslog
from email.parser import Parser
from email.utils import parseaddr
from tempfile import NamedTemporaryFile
import configparser

os.environ["PHABRICATOR_ENV"] = "mail"


def output(msg, verbose):
    msg = str(msg)
    if verbose is True:
        syslog.syslog(msg)
        print("-> ", msg)


def log(msg):
    output(msg, verbose="-v" in sys.argv)


class EmailParsingError(Exception):
    pass


class EmailStatusError(Exception):
    pass


def main():
    # if stdin is empty we bail to avoid a loop
    # of looking for EOF that never comes
    if sys.stdin.isatty():
        raise EmailParsingError("no stdin")

    parser = configparser.ConfigParser()
    parser_mode = "phab_bot"
    parser.read("/etc/phab_epipe.conf")

    defaults = {}
    for name, value in parser.items("default"):
        defaults[name] = value

    def parse_from_string(from_str):
        """parses from elements
        :param: src string
        :returns: tuple
        https://docs.python.org/2/library/email.util.html
        """
        name, addy = parseaddr(from_str)
        if not name:
            name = addy.split("@")[0]
        return name, addy

    def phab_handoff(email):
        handler = os.path.join(
            parser.get(parser_mode, "root_dir"), "scripts/mail/mail_handler.php"
        )
        process = subprocess.Popen([handler], stdin=subprocess.PIPE, encoding="utf-8")
        process.communicate(email)

    # If maint is true then reject all email interaction
    if defaults["maint"].lower() == "true":
        raise EmailStatusError("Email interaction is currently disabled.")

    if "debug" in defaults:
        defaults["debug"] = defaults["debug"].lower().split(",")

    # Reading in the message
    stdin = sys.stdin.read()

    if "-s" in sys.argv or defaults.get("save", False):
        with NamedTemporaryFile(prefix="phabmail_", delete=False) as temp:
            log("saving raw email to %s" % temp.name)
            temp.write(stdin)

    # ['Received', 'DKIM-Signature', 'X-Google-DKIM-Signature',
    # 'X-Gm-Message-State', 'X-Received', 'Received',
    # 'Date', 'From', 'To', 'Message-ID',
    # 'Subject', 'X-Mailer', 'MIME-Version', 'Content-Type']
    msg = Parser().parsestr(stdin)
    src_address = msg["from"]
    src_name, src_addy = parse_from_string(src_address)

    # Some email clients do crazy things and it is very difficult to debug
    # without the raw message. In these (rare) cases we can add the sender to
    # debug to log
    src = src_addy.lower().strip()
    if src in defaults.get("debug", []):
        prefix = "phabmail_%s_" % src
        with NamedTemporaryFile(prefix=prefix, delete=False) as temp:
            temp.write(stdin)

    phab_handoff(stdin)


if __name__ == "__main__":
    contact = "Please contact a WMF Phabricator admin."

    try:
        main()
    # using this as a pipe Exim will return any error
    # output to the sender, in order to not reveal internal
    # errors we only respond directly for defined errors
    # otherwise swallow, return generic, and go for syslog
    except EmailStatusError as e:
        print("%s\n\n%s" % (e, contact))
        sys.exit(1)
    except EmailParsingError as e:
        syslog.syslog("EmailParsingError: %s" % (str(e)))
        print("%s\n\n%s" % (e, contact))
        sys.exit(1)
    except Exception as e:
        msg = "Error parsing message"
        syslog.syslog("%s: %s" % (msg, str(e)))
        print("%s\n\n%s" % (msg, contact))
        sys.exit(1)
