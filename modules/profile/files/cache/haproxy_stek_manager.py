#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# haproxy_stek_manager - creates or updates a Session Ticket Encryption Key (STEK) file
#
# Copyright 2021 Valentin Gutierrez
# Copyright 2021 Wikimedia Foundation, Inc.

import base64
import os
import pwd
import secrets
import sys
import tempfile

from collections import deque

from pystemd.systemd1 import Unit


STEK_LENGTH = 48
ENCODED_STEK_LENGTH = 64  # 48 bytes encoded in base64 results in 64 bytes strings
MAX_KEYS = 3              # HAProxy sets this at build time as TLS_TICKETS_NO and defaults to 3
HAPROXY_USERNAME = 'haproxy'


def generate_key(length=STEK_LENGTH):
    """HAProxy requires keys to be base64 encoded"""
    return base64.standard_b64encode(secrets.token_bytes(length))


def drop_privileges(target_user=HAPROXY_USERNAME):
    pwd_entry = pwd.getpwnam(target_user)

    os.setegid(pwd_entry.pw_gid)
    os.seteuid(pwd_entry.pw_uid)


def restore_privileges():
    os.seteuid(os.getuid())
    os.setegid(os.getgid())


def load_stek_file(path, max_keys=MAX_KEYS):
    with open(path, 'rb') as stek_file:
        data = stek_file.readlines()

    # keys = [line.removesuffix(b'\n') for line in data]
    # removesuffix is introduced on python 3.9
    keys = [line[:-1] for line in data]

    return deque(keys, max_keys)


def save_stek_file(stek_keys, path):
    os.umask(0o66)
    base_directory = os.path.dirname(path)
    with tempfile.NamedTemporaryFile(dir=base_directory, delete=False) as tmpfile:
        tmpfilename = tmpfile.name
        for stek_key in stek_keys:
            tmpfile.write(stek_key+b'\n')  # HAProxy expects one key per line

    os.rename(tmpfilename, path)


def reload_haproxy_unit(unit_name=b'haproxy.service'):
    haproxy_unit = Unit(unit_name)
    haproxy_unit.load()
    if haproxy_unit.Unit.ActiveState == b'active':
        haproxy_unit.Unit.Reload(b'replace')


def main(stek_path):
    try:
        stek_keys = load_stek_file(stek_path)
    except OSError:
        # if the file doesn't exist/contains invalid data a new one will be created
        stek_keys = deque(maxlen=MAX_KEYS)

    # ensure that we always have MAX_KEYS available on the file
    keys_to_add = max(1, MAX_KEYS - len(stek_keys))
    for i in range(keys_to_add):
        stek_keys.appendleft(generate_key())

    drop_privileges()

    save_stek_file(stek_keys, stek_path)

    restore_privileges()
    reload_haproxy_unit()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: {} stek_path".format(sys.argv[0]))
        sys.exit(1)

    main(sys.argv[1])
