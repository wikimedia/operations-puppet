#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# Generates a daily subkey for differential privacy purposes (T315676)

import datetime
import sys
import tempfile
from pathlib import Path
from shutil import chown

# provided by python3-nacl
import nacl.encoding
from nacl.hash import blake2b, BLAKE2B_KEYBYTES_MAX, SIPHASH_KEYBYTES

from pystemd.systemd1 import Unit

CONTEXT = b'diffpriv'
SUBKEY_ID = str(datetime.date.today()).encode()
VARNISH_GROUP = 'varnish'


def generate_sub_key(master_key, length=SIPHASH_KEYBYTES):
    # from https://libsodium.gitbook.io/doc/key_derivation
    # BLAKE2B-subkeylen(key=key, message={}, salt=subkey_id || {0}, personal=ctx || {0})
    derived = blake2b(b'', key=master_key, salt=SUBKEY_ID,
                      person=CONTEXT, encoder=nacl.encoding.RawEncoder)
    return derived[:SIPHASH_KEYBYTES]


def reload_varnish_unit(unit_name=b'varnish-frontend.service'):
    varnish_unit = Unit(unit_name)
    varnish_unit.load()
    if varnish_unit.Unit.ActiveState == b'active':
        varnish_unit.Unit.Reload(b'replace')


def main(master_key_path, sub_key_path):
    master_key = ''

    try:
        master_key = master_key_path.read_bytes()
    except OSError as ose:
        raise Exception("Unable to read master key file", ose)

    if len(master_key) > BLAKE2B_KEYBYTES_MAX:
        raise ValueError("Unexpected key length")

    sub_key = generate_sub_key(master_key)
    try:
        # NamedTemporaryFile ensures 0600 permissions
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file.write(sub_key)

        # varnish group needs to be able to read the key
        temp_path = Path(temp_file.name)
        temp_path.chmod(0o640)
        chown(temp_path, group=VARNISH_GROUP)
        temp_path.replace(sub_key_path)
    except OSError as ose:
        raise Exception("Unable to write subkey file", ose)

    reload_varnish_unit()


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} master_key_path sub_key_path")
        sys.exit(1)

    main(Path(sys.argv[1]), Path(sys.argv[2]))
    sys.exit(0)
