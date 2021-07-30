#!/usr/bin/env python3
"""
Temporary script to keep the mwdebug deployment up to date with
the scap-released version. Given its temporary nature, the script
will hardcode most values.

Copyright (c) 2021 Giuseppe Lavagetto <joe@wikimedia.org>
"""
import fcntl
import logging
import pathlib
import re
import subprocess
import sys

import yaml
from docker_report.registry import operations

logger = logging.getLogger()

IMAGE = "restricted/mediawiki-multiversion"
WEB_IMAGE = "restricted/mediawiki-webserver"
REGISTRY = "docker-registry.discovery.wmnet"
VALUES_FILE = pathlib.Path("/etc/helmfile-defaults/mediawiki/releases.yaml")
DEPLOY_DIR = "/srv/deployment-charts/helmfile.d/services/mwdebug"
good_tag_regex = re.compile(r"\d{4}-\d{2}-\d{2}-\d{6}-publish")


def find_last_tag(registry: operations.RegistryOperations) -> str:
    """Finds the last standard tag present on the registry"""
    maxtag = "0"
    for tag in registry.get_tags_for_image(IMAGE):
        m = good_tag_regex.match(tag)
        # This is a non-standard tag like "latest", skip it
        if m is None:
            continue
        ts = m.group()
        if ts > maxtag:
            maxtag = tag
    if maxtag == "0":
        raise RuntimeError("No release tags found")
    logger.info(f"Found the most recent release, {maxtag}")
    return maxtag


def values_file_update(maxtag: str) -> bool:
    """Updates the values file, if necessary. Returns true in that case."""
    values = yaml.safe_dump(
        {
            "main_app": {"image": f"{IMAGE}/{maxtag}"},
            "mw": {"httpd": {"image_tag": f"{WEB_IMAGE}/{maxtag}"}},
        }
    )
    try:
        orig_values = VALUES_FILE.read_text()
        if values == orig_values:
            return False
        logger.info("Updating the values file")
    except FileNotFoundError:
        logger.info("Creating the releases file")
    VALUES_FILE.write_text(values)

    return True


def deployment():
    """Deploy to production"""
    logger.info("Deploying to eqiad")
    subprocess.run(["helmfile", "-e", "eqiad", "apply"], cwd=DEPLOY_DIR, check=True)
    logger.info("Deploying to codfw")
    subprocess.run(["helmfile", "-e", "codfw", "apply"], cwd=DEPLOY_DIR, check=True)


def main():
    try:
        fd = open("/tmp/deploy-mwdebug-flock", "w+")
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        logging.basicConfig(level=logging.INFO)
        ops = operations.RegistryOperations(REGISTRY, logger=logger)
        maxtag = find_last_tag(ops)
        if values_file_update(maxtag):
            deployment()
        else:
            logger.info("Nothing to deploy")
    except BlockingIOError:
        logger.info("Unable to acquire the lock, not running")
        sys.exit(1)
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        fd.close()


if __name__ == "__main__":
    main()
