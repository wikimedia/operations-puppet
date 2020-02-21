#!/usr/bin/env python3

# ats_stek_manager - creates or updates a Session Ticket Encryption Key (STEK) file
#
# Copyright 2020 Valentin Gutierrez
# Copyright 2020 Wikimedia Foundation, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import secrets
import sys
import tempfile

from collections import deque

from pystemd.systemd1 import Unit

STEK_LENGTH = 48
MAX_KEYS = 4


def generate_key(length=STEK_LENGTH):
    """ATS defines a STEK like this:
    struct ssl_ticket_key_t {
        unsigned char key_name[16];
        unsigned char hmac_secret[16];
        unsigned char aes_key[16];
    };
    So we need to ensure that NULL bytes (0x0) don't end up on the key material."""
    return secrets.token_urlsafe(length)[:length].encode()


def load_stek_file(path, max_keys=MAX_KEYS):
    with open(path, 'rb') as stek_file:
        data = stek_file.read()
    if len(data) % STEK_LENGTH != 0:
        raise OSError("Unexpected data on STEK file.")
    keys = [data[STEK_LENGTH*i:STEK_LENGTH*(i+1)] for i in range((int(len(data) / STEK_LENGTH)))]
    return deque(keys, max_keys)


def save_stek_file(stek_keys, path):
    os.umask(0o66)
    base_directory = os.path.dirname(path)
    with tempfile.NamedTemporaryFile(dir=base_directory, delete=False) as tmpfile:
        tmpfilename = tmpfile.name
        for stek_key in stek_keys:
            tmpfile.write(stek_key)

    os.rename(tmpfilename, path)


def reload_ats_unit(unit_name=b'trafficserver-tls.service'):
    ats_unit = Unit(unit_name)
    ats_unit.load()
    if ats_unit.Unit.ActiveState == b'active':
        ats_unit.Unit.Reload(b'replace')


def main(stek_path):
    try:
        stek_keys = load_stek_file(stek_path)
    except OSError:
        # if the file doesn't exist/contains invalid data we will create a new one
        stek_keys = deque(maxlen=MAX_KEYS)

    stek_keys.appendleft(generate_key())

    save_stek_file(stek_keys, stek_path)
    reload_ats_unit()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: {} stek_path".format(sys.argv[0]))
        sys.exit(1)

    main(sys.argv[1])
