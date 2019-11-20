#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
   Check or set Graphite webapp user credentials

   Usage: graphite-auth [check | set] USER PASSWORD

   Copyright (c) 2013 Ori Livneh and Wikimedia Foundation. All Rights Reserved.

"""
import argparse
import os
import socket
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'graphite.settings')

# django 1.7 compatibility
import django  # noqa: E402
try:
    django.setup()
except AttributeError:
    pass

from django.contrib.auth.models import User  # noqa: E402


def check_admin(args):
    try:
        user = User.objects.get(username=args.user)
        return user.check_password(args.password)
    except User.DoesNotExist:
        return False


def set_admin(args):
    try:
        user = User.objects.get(username=args.user)
        user.set_password(args.password)
        user.save()
        return True
    except User.DoesNotExist:
        pass

    try:
        User.objects.create_superuser(
            args.user, 'admin@' + socket.gethostname(), args.password)
        return True
    except Exception:
        pass

    return False


parser = argparse.ArgumentParser()
parser.add_argument('command', choices=('check', 'set'))
parser.add_argument('user')
parser.add_argument('password')
args = parser.parse_args()

if args.command == 'check':
    ok = check_admin(args)
else:
    ok = set_admin(args)

print(ok)
sys.exit(0 if ok else 1)
