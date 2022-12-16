#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# envoy_stek_manager - creates or updates a Session Ticket Encryption Key (STEK) directory
#
# Copyright 2021 Valentin Gutierrez
# Copyright 2021 Wikimedia Foundation, Inc.

import os
import pathlib
import pwd
import secrets
import shutil
import sys

from pystemd.systemd1 import Unit

STEK_LENGTH = 80
KEYS = 4
STEK_FILENAME_FORMAT = 'stek.key.{key_index}'
ENVOY_USERNAME = 'envoy'


def generate_key(length=STEK_LENGTH):
    """envoy requires 80 bytes of random data per STEK file.
       Their documentation mentions openssl rand 80 as a valid source,
       so it looks like here 0x00 bytes aren't an issue.
    """
    return secrets.token_bytes(STEK_LENGTH)


def drop_privileges(target_user=ENVOY_USERNAME):
    pwd_entry = pwd.getpwnam(target_user)

    os.setegid(pwd_entry.pw_gid)
    os.seteuid(pwd_entry.pw_uid)


def restore_privileges():
    os.seteuid(os.getuid())
    os.setegid(os.getgid())


def get_path(base_directory, key_index, stek_filename_format=STEK_FILENAME_FORMAT):
    file_name = stek_filename_format.format(key_index=key_index)
    file_path = base_directory / file_name

    return file_path


def populate_stek_directory(directory, keys=KEYS):
    for i in range(keys):
        file_path = get_path(directory, i)
        key = generate_key()
        file_path.write_bytes(key)


def rotate_stek_directory(directory, keys=KEYS):
    """We need to ensure that all STEK files are always present to avoid
       envoy crashing if it's reloaded (externally) in the middle of the operation.
       Order here is important as well. First we copy the existing keys discarding
       the oldest one and finally we replace the first one"""
    for i in range(keys-2, -1, -1):
        old_file_path = get_path(directory, i)
        new_file_path = get_path(directory, i+1)

        shutil.copy(old_file_path, new_file_path)

    # time to generate the new key
    populate_stek_directory(directory, keys=1)


def reload_envoy_unit(unit_name=b'envoyproxy.service'):
    envoy_unit = Unit(unit_name)
    envoy_unit.load()
    if envoy_unit.Unit.ActiveState == b'active':
        envoy_unit.Unit.Reload(b'replace')


def main(stek_dir):
    os.umask(0o66)
    main_key_path = get_path(stek_dir, 0)

    drop_privileges()

    if main_key_path.exists():
        rotate_stek_directory(stek_dir)
    else:
        populate_stek_directory(stek_dir)

    restore_privileges()
    reload_envoy_unit()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage {} stek_base_directory".format(sys.argv[0]))
        sys.exit(1)

    main(pathlib.Path(sys.argv[1]))
