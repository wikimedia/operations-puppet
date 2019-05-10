#!/usr/bin/env python3

import argparse
import glob
import grp
import logging
import os
import pwd
import shutil
import sys
import tempfile

import yaml


log = logging.getLogger(__name__)
DESCRIPTION = """Assemble files matching --config-glob into --config-file.
Additionally, validate the result as YAML."""


def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('--config-glob', default='/etc/prometheus/snmp.yml.d/*.yml')
    parser.add_argument('--config-file', default='/etc/prometheus/snmp.yml')
    args = parser.parse_args()

    logging.basicConfig()

    with tempfile.NamedTemporaryFile(dir=os.path.dirname(args.config_file)) as tmpconfig:
        for fragment in glob.glob(args.config_glob):
            with open(fragment, 'r') as f:
                shutil.copyfileobj(f.buffer, tmpconfig)

        tmpconfig.seek(0)
        if yaml.safe_load(tmpconfig) is None:
            log.error('Empty YAML assembled')
            return 1

        os.chmod(tmpconfig.name, 0o400)
        uid = pwd.getpwnam('prometheus').pw_uid
        gid = grp.getgrnam('root').gr_gid
        os.chown(tmpconfig.name, uid, gid)
        os.rename(tmpconfig.name, args.config_file)

        # Temporary file has been atomically renamed to its final destination.
        # Create it again empty so tempfile cleanup is happy
        with open(tmpconfig.name, 'w+') as f:
            pass


if __name__ == '__main__':
    sys.exit(main())
