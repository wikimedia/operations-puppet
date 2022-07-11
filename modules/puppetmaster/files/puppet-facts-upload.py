#!/usr/bin/python3
"""example script"""

import logging
import subprocess

from base64 import b64encode
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from pathlib import Path
from requests import post
from socket import gethostname

from argparse import ArgumentParser


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "-u", "--uri", default="https://puppet-compiler.wmflabs.org/upload"
    )
    parser.add_argument("-s", "--skip", action="store_true")
    parser.add_argument("-p", "--proxy")
    parser.add_argument("-v", "--verbose", action="count")
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def get_signature(key, payload):
    logging.debug("Generating signiture")
    private_key = serialization.load_pem_private_key(
        key, password=None, backend=default_backend()
    )
    signature = b64encode(
        private_key.sign(
            payload,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH,
            ),
            hashes.SHA256(),
        )
    )
    logging.debug("Generated signiture: %s", signature)
    return signature


def get_realm():
    wmcs_projects_file = Path("/etc/wmcs-project")
    if wmcs_projects_file.is_file():
        return wmcs_projects_file.read_text().strip()
    return "production"


def generate_facts_file(facts_file, skip):
    if not skip:
        if facts_file.is_file():
            logging.debug("deleting old file: %s", facts_file)
            facts_file.unlink()
        logging.debug("Generating facts export: %s", facts_file)
        subprocess.run("/usr/local/bin/puppet-facts-export", check=True)
    if not facts_file.is_file():
        logging.error("Error creating facts export")
        raise SystemExit(1)


def get_key_file():
    return Path(
        subprocess.run(
            "facter -p puppet_config.hostprivkey".split(),
            check=True,
            capture_output=True,
        )
        .stdout.decode()
        .strip()
    )


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    facts_file = Path("/tmp/puppet-facts-export.tar.xz")
    generate_facts_file(facts_file, args.skip)

    key_file = get_key_file()
    signature = get_signature(key_file.read_bytes(), facts_file.read_bytes())

    data = {"realm": get_realm(), "hostname": gethostname(), "signature": signature}
    files = {"file": facts_file.read_bytes()}
    proxies = {"http": args.proxy, "https": args.proxy} if args.proxy else None

    logging.debug("Posting data to: %s", args.uri)
    resp = post(args.uri, data=data, files=files, proxies=proxies)
    if not resp.ok:
        if resp.status_code == 403:
            logging.error(
                "request denied, ensure you have added the puppetmaster certificate "
                "https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Manually_update_cloud"
            )
        else:
            logging.error("%d: Unable to submit request: %s", resp.status_code, resp.text)
        return 1
    if not resp.json().get("result"):
        logging.error("Error submitting facts file")
        return 1

    logging.debug("Success!")
    facts_file.unlink()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
