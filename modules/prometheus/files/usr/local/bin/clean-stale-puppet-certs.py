#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import subprocess
import sys
from pathlib import Path


STALECERTSSCRIPT = "/usr/local/sbin/prometheus-openstack-stale-puppet-certs"

PUPPETDB_CONFIG_FILE = Path("/etc/puppet/puppetdb.conf")


def clean_certs(clean):
    output = subprocess.check_output([STALECERTSSCRIPT])
    for line in output.decode("utf8").splitlines():
        herald = 'cert_name="'
        if line.startswith("puppetmaster_stale_cert") and herald in line:
            certname_substr = line[line.find(herald) + len(herald):]
            certname = certname_substr[0:certname_substr.find('"')]

            if not clean:
                print("stray cert %s" % certname)
                continue

            subprocess.run(
                ["/usr/bin/puppetserver", "ca", "clean", "--certname", certname]
            )

            if PUPPETDB_CONFIG_FILE.exists():
                subprocess.run(["/usr/bin/puppet", "node", "deactivate", certname])


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--clean",
        dest="delete",
        help="Actually clean stray certs.",
        action="store_true",
    )

    args = parser.parse_args()
    clean_certs(args.delete)


if __name__ == "__main__":
    sys.exit(main())
