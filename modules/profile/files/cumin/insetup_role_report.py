#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Audit all servers in an insetup* Puppet role and send an email report to their owners.

Sends also a summary of the audit to the audit owner.
"""
import json
import smtplib

from email.message import EmailMessage
from pathlib import Path

import cumin

from cumin import query


CONFIG_PATH = Path('/etc/cumin/insetup_role_report.json')
MESSAGE_PREFIX = ('This is the list of hosts owned by your team that are ready to be put in '
                  'production but still have an "insetup" Puppet role:\n')
MESSAGE_SUFFIX = ('For more information or to relay feedback just reply to this email or get in '
                  'touch with {audit_owner}.\n')
OWNER_PREFIX = 'Those are the audit reports sent to the various owners.\n\n'


def send_mail(mail_to: str, message: str, audit_owner: str) -> None:
    """Send an email to the receipient with the given message."""
    msg = EmailMessage()
    msg.set_content(message)
    msg['Subject'] = 'Insetup Server Audit'
    msg['From'] = 'Insetup Server Audit <no-reply@wikimedia.org>'
    msg['To'] = mail_to
    msg['Reply-To'] = audit_owner
    msg['Auto-Submitted'] = "auto-generated"
    smtp = smtplib.SMTP("localhost")
    smtp.send_message(msg)
    smtp.quit()


def generate_message(roles: list[str], audit_owner: str) -> str:
    """Generate a message to send with the list of hosts in the given roles."""
    config = cumin.Config()
    message_parts = [MESSAGE_PREFIX]
    for role in roles:
        if role.startswith('O:'):
            role_query = role
        else:
            role_query = f'O:insetup::{role}_ferm or O:insetup::{role}_nftables'

        hosts = query.Query(config).execute(role_query)
        if not hosts:
            continue

        message_parts.append(f'* {len(hosts)} hosts with Puppet role {role_query}:\n{hosts}\n')

    if len(message_parts) == 1:
        return ''

    message_parts.append(MESSAGE_SUFFIX.format(audit_owner=audit_owner))
    return '\n'.join(message_parts)


def main() -> None:
    """Execute the script."""
    config = json.loads(CONFIG_PATH.read_text(encoding='utf-8'))
    audit_owner = config['audit_owner']
    owner_message = [OWNER_PREFIX]
    # Mapping of owner email to Puppet O:insetup::* roles (allow exceptions starting a role with O:)
    for mail_to, roles in config['mapping'].items():
        message = generate_message(roles, audit_owner)
        if not message:
            continue

        send_mail(mail_to, message, audit_owner)
        owner_message.append(f'TO: {mail_to}')
        owner_message.append(message)

    if len(owner_message) > 1:
        message = '\n'.join(owner_message)
        send_mail(audit_owner, message, audit_owner)
        for debug_owner in config['debug_owners']:
            send_mail(debug_owner, message, audit_owner)


if __name__ == '__main__':
    main()
