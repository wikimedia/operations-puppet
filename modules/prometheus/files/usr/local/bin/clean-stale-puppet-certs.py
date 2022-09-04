#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import subprocess
import sys

STALECERTSSCRIPT = "/usr/local/sbin/prometheus-openstack-stale-puppet-certs"


def clean_certs(clean):
    output = subprocess.check_output(
        [
            "/usr/local/sbin/prometheus-openstack-stale-puppet-certs",
            "--signed-certs-dir",
        ]
    )
    for line in output.decode("utf8").splitlines():
        herald = 'cert_name="'
        if line.startswith("puppetmaster_stale_cert") and herald in line:
            certname_substr = line[line.find(herald) + len(herald):]
            certname = certname_substr[0:certname_substr.find('"')]
            if clean:
                subprocess.run(["/usr/bin/puppet", "cert", "clean", certname])
            else:
                print("stray cert %s" % certname)


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
