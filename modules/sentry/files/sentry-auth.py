#!/usr/bin/env /srv/sentry/bin/python
# -*- coding: utf-8 -*-
"""
   Check or set Sentry admin credentials
   Usage: sentry-auth [check | set] USER PASSWORD

"""
import argparse
import os
import sys

os.environ.setdefault('SENTRY_CONF', '/etc/sentry.conf.py')

from sentry.models import User
from sentry.utils.runner import configure

configure()


def check_admin(args):
    try:
        user = User.objects.get(username=args.email)
        return user.check_password(args.password)
    except:
        return False


def set_admin(args):
    try:
        user = User.objects.get(username=args.email)
        user.set_password(args.password)
        user.save()
        return True
    except:
        pass

    try:
        user = User(
            email=args.email,
            username=args.email,
            is_superuser=True,
            is_staff=True,
            is_active=True,
        )
        user.set_password(args.password)
        user.save()
        return True
    except:
        pass

    return False


parser = argparse.ArgumentParser()
parser.add_argument('command', choices=('check', 'set'))
parser.add_argument('email')
parser.add_argument('password')
args = parser.parse_args()

if args.command == 'check':
    ok = check_admin(args)
else:
    ok = set_admin(args)

print(ok)
sys.exit(0 if ok else 1)
