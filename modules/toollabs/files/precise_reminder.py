#!/usr/bin/python3

# Copyright 2016 Madhumitha Viswanathan mviswanathan@wikimedia.org
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
# Maps tool users to precise tools, and sends reminder emails to all tool
# maintainers to move their tools of precise before deprecation.
#
# Run ./precise-reminder.py from tools bastions
#

from email.mime.text import MIMEText

import collections
import datetime
import fileinput
import http.client
import json
import ldap3
import logging
import smtplib
import textwrap
import yaml

logging.basicConfig(
    format="%(asctime)-15s %(message)s",
    filename='/var/log/precise-reminder',
    level=logging.INFO
)


def ldap_conn(config):
    """
    Return a ldap connection
    Return value can be used as a context manager
    """
    servers = ldap3.ServerPool([
        ldap3.Server(host)
        for host in config['servers']
    ], ldap3.POOLING_STRATEGY_ROUND_ROBIN, active=True, exhaust=True)
    return ldap3.Connection(servers, read_only=True,
                            user=config['user'],
                            auto_bind=True,
                            password=config['password'])


def tools_members():
    """
    Query the precise-tools tool and return a dict with tool names associated with
    a list of members
    Ex:
    {'musikbot': ['musikanimal'],
     'ifttt': ['slaporte', 'mahmoud', 'madhuvishy', 'ori']}
    """
    all_precise_tools = []
    conn = http.client.HTTPConnection('tools.wmflabs.org')
    conn.request("GET", "/precise-tools/json",
                 headers={"User-Agent": "Precise reminder emailer|labs-admin@lists.wikimedia.org"})
    res = conn.getresponse().read().decode('utf-8')
    if res:
        tools = json.loads(res)["tools"]
    return {tool_name: tool_info["members"] for tool_name, tool_info in tools.items()}


def members_tools(tool_to_members):
    member_to_tools = collections.defaultdict(list)
    for tool, members in tool_to_members.items():
        for m in members:
            if tool not in member_to_tools[m]:
                member_to_tools[m].append(tool)
    return member_to_tools


def member_emails(member_uids):
    uid_emails = collections.defaultdict(list)
    for uid in member_uids:
        with ldap_conn(config) as conn:
            conn.search('ou=people,dc=wikimedia,dc=org',
                        '(uid={})'.format(uid),
                        ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                        attributes=['mail'],
                        time_limit=5
                        )
            for resp in conn.response:
                attributes = resp.get('attributes')
                uid_emails[uid] = attributes['mail'][0] if attributes.get('mail') else ''
    return uid_emails


def notify_admins(member_tools, member_emails):

    for member, tools in member_tools.items():
        recip_email = member_emails[member]
        subject = '[Weekly reminder][action required] Your Precise Tools need migration'
        body = """
        All Tools/bots/webservices running on Ubuntu Precise 12.04 (jsub release=precise)
        will no longer function starting on Monday, March 6, 2017, and will crash with an error.

        Ubuntu Precise was released in April 2012, and support for it
        (including security updates) will cease in April 2017. We need to shut
        down all Precise hosts before the end of support date to ensure that
        Tool Labs remains a secure platform.

        You (username: {}) are registered as admin/maintainer for the following tools,
        that are still on Precise: \n{}

        Please make sure to migrate these over to Trusty as early as possible, to
        ensure continued operation.

        The steps to migrate to Trusty, and more information about the
        Precise deprecation are here -
        https://wikitech.wikimedia.org/wiki/Tools_Precise_deprecation#What_should_I_do.3F.

        A quick tip for webservices - running `webservice stop; webservice start` -
        will migrate it to trusty (webservice restart currently sticks).
        Additional information on running precise jobs can be seen at our Precise tools
        dashboard here - https://tools.wmflabs.org/precise-tools/

        Do feel free to reach out with questions/help at #wikimedia-labs on IRC.
        """.format(member, '\n'.join(sorted(tools)))

        with smtplib.SMTP('mx1001.wikimedia.org') as s:
            msg = MIMEText(textwrap.dedent(body))
            msg['Subject'] = subject
            msg['From'] = 'Madhumitha Viswanathan <mviswanathan@wikimedia.org>'
            msg['To'] = recip_email
            msg['List-Unsubscribe'] = '<mailto:mviswanathan@wikimedia.org>'
            try:
                s.send_message(msg, 'mviswanathan@wikimedia.org', [recip_email])
                logging.info('Sent email to user {}'.format(member))
            except smtplib.SMTPRecipientsRefused as e:
                logging.error('Recipients refused error while sending to {}'.format(member))
                logging.error(e)
            except Exception as e:
                logging.error('Error while sending to {}'.format(member))
                logging.error(e)

with open('/etc/ldap.yaml') as f:
    config = yaml.safe_load(f)

tool_to_members = tools_members()
logging.info("Tools on precise: \n {}".format(tool_to_members.keys()))
mt = members_tools(tool_to_members)
logging.info("Users being reminded: \n {}".format(mt.keys()))
emails = member_emails(mt.keys())
notify_admins(mt, emails)
