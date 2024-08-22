#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Audit all servers in an insetup* Puppet role and send an email report to their owners.

Sends also a summary of the audit to the audit owner.
"""
import smtplib

from email.message import EmailMessage

import cumin

from cumin import query


AUDIT_OWNER = 'dtankersley@wikimedia.org'
MESSAGE_PREFIX = ('This is the list of hosts owned by your team that are ready to be put in '
                  'production but still have an "insetup" Puppet role:\n')
MESSAGE_SUFFIX = ('For more information or to relay feedback just reply to this email or get in '
                  f'touch with {AUDIT_OWNER}.\n')
OWNER_PREFIX = 'Those are the audit reports sent to the various owners.\n\n'
# Mapping of owner email to Puppet O:insetup::* roles (allow exceptions starting a role with O:)
MAPPING = {
    'calbon': ['machine_learning'],
    'glederrey': ['search_platform', 'data_engineering'],
    'jborun': ['infrastructure_foundations', 'unowned', 'buster', 'wmcs'],
    'kappakayala': ['serviceops', 'container'],
    'kofori': ['data_persistence', 'traffic', 'O:insetup_noferm'],
    'lmata': ['observability'],
    'lsobanski': ['collaboration_services'],
}


def send_mail(mail_to: str, message: str) -> None:
    """Send an email to the receipient with the given message."""
    msg = EmailMessage()
    msg.set_content(message)
    msg['Subject'] = 'Insetup Server Audit'
    msg['From'] = 'Insetup Server Audit <no-reply@wikimedia.org>'
    msg['To'] = mail_to
    msg['Reply-To'] = AUDIT_OWNER
    msg['Auto-Submitted'] = "auto-generated"
    smtp = smtplib.SMTP("localhost")
    smtp.send_message(msg)
    smtp.quit()


def generate_message(roles: list[str]) -> str:
    """Generate a message to send with the list of hosts in the given roles."""
    config = cumin.Config()
    message_parts = [MESSAGE_PREFIX]
    for role in roles:
        if role.startswith('O:'):
            role_query = role
        else:
            role_query = f'O:insetup::{role}'

        hosts = query.Query(config).execute(role_query)
        if not hosts:
            continue

        message_parts.append(f'* {len(hosts)} hosts with Puppet role {role_query[2:]}:\n{hosts}\n')

    if len(message_parts) == 1:
        return ''

    message_parts.append(MESSAGE_SUFFIX)
    return '\n'.join(message_parts)


def main() -> None:
    """Execute the script."""
    owner_message = [OWNER_PREFIX]
    for email, roles in MAPPING.items():
        message = generate_message(roles)
        if not message:
            continue

        mail_to = f'{email}@wikimedia.org'
        send_mail(mail_to, message)
        owner_message.append(f'TO: {mail_to}')
        owner_message.append(message)

    if len(owner_message) > 1:
        send_mail(AUDIT_OWNER, '\n'.join(owner_message))


if __name__ == '__main__':
    main()
