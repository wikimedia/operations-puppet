#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Temporary script to keep the mw-debug deployment up to date with
the scap-released version. Given its temporary nature, the script
will hardcode most values.

Copyright (c) 2021- Giuseppe Lavagetto <joe@wikimedia.org>
"""
import argparse
import fcntl
import logging
import pathlib
import re
import subprocess
import sys
from datetime import datetime
from typing import List

import yaml
from docker_report.registry import operations
from wmflib.interactive import AbortError, ask_confirmation

logger = logging.getLogger()

# Default values we don't expect to change
REGISTRY = "docker-registry.discovery.wmnet"
RELEASES_FILE = pathlib.Path("/etc/helmfile-defaults/mediawiki-deployments.yaml")
VALUES_DIR = pathlib.Path("/etc/helmfile-defaults/mediawiki/release/")
DEPLOY_DIR = "/srv/deployment-charts/helmfile.d/services/mw-debug"
good_tag_regex = re.compile(r"\d{4}-\d{2}-\d{2}-\d{6}-(publish|webserver)")

# Lock file, to ensure parallel executions didn't happen.
LOCK_FILE = pathlib.Path("/var/lib/deploy-mwdebug/flock")
# Error file, created when a deployment fails.
# Further deployments can only happen if we set --force
ERROR_FILE = pathlib.Path("/var/lib/deploy-mwdebug/error")
# Pause file, to cause this script to exit happily without doing any work, regardless
# of --force.
PAUSE_FILE = pathlib.Path("/var/lib/deploy-mwdebug/pause")

# Clusters to deploy to
CLUSTERS = ["eqiad", "codfw"]


def parse_args(args=sys.argv[1:]):
    """Argument parser"""
    parser = argparse.ArgumentParser(
        prog="deploy-mwdebug",
        description="script to automate deployments to mediawiki on k8s",
    )
    parser.add_argument(
        "--force",
        "-f",
        action="store_true",
        help="force deployment even if there was a previous error or there is no apparent update.",
    )
    parser.add_argument(
        "--mediawiki-image",
        "-m",
        help="The name:tag of the mediawiki image (without registry).",
        default="restricted/mediawiki-multiversion",
    )
    parser.add_argument(
        "--web-image",
        "-w",
        help="The name:tag of the web image (without registry).",
        default="restricted/mediawiki-webserver",
    )
    parser.add_argument(
        "--noninteractive",
        "-n",
        help="Run as a batch process (do not ask for confirmation before deployment)",
        action="store_true",
    )
    return parser.parse_args(args)


def get_deployment_files() -> List[pathlib.Path]:
    deployments = yaml.safe_load(RELEASES_FILE.read_text(encoding="utf-8"))
    results = []
    for deployment in deployments:
        if deployment.get("release") is not None:
            results.append(VALUES_DIR / f"{deployment['namespace']}-{deployment['release']}.yaml")
        if deployment.get("canary") is not None:
            results.append(VALUES_DIR / f"{deployment['namespace']}-{deployment['canary']}.yaml")
    return results


def find_last_tag(registry: operations.RegistryOperations, image: str) -> str:
    """Finds the last standard tag present on the registry"""
    maxtag = "0"
    for tag in registry.get_tags_for_image(image):
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
    return f"{image}:{maxtag}"


def values_file_update(filepath: pathlib.Path, maxtag_mw: str, maxtag_web: str) -> bool:
    """Updates the values file, if necessary. Returns true in that case."""
    values = yaml.safe_dump(
        {
            "main_app": {"image": maxtag_mw},
            "mw": {"httpd": {"image_tag": maxtag_web}},
        }
    )
    try:
        orig_values = filepath.read_text()
        if values == orig_values:
            return False
        logger.info("Updating the values file")
    except FileNotFoundError:
        logger.info("Creating the releases file")
    filepath.write_text(values)
    # Commit the file to the repository
    repo = str(filepath.absolute().parent)
    subprocess.run(["git", "add", filepath.name], cwd=repo, check=True)
    return True


def _deploy_to(env: str):
    """Deploy to production automatically"""
    logger.info(f"Deploying to {env}")
    subprocess.run(["helmfile", "-e", env, "apply"], cwd=DEPLOY_DIR, check=True)


def deployment(noninteractive: bool):
    """Deploy to production"""
    for env in CLUSTERS:
        if noninteractive:
            _deploy_to(env)
        else:
            try:
                ask_confirmation(f"Proceed to deploy to {env}?")
                _deploy_to(env)
            except AbortError:
                logger.warning(f"Skipping {env}")
            except subprocess.CalledProcessError as e:
                logger.error(f"Deploying to {env} failed: {e}")


def main():
    try:
        fd = LOCK_FILE.open("w+")
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        logging.basicConfig(level=logging.INFO)
        opts = parse_args()

        try:
            pause_message = PAUSE_FILE.read_text().strip() or "<no explanation provided>"
            logging.info(f"This script has been paused by {PAUSE_FILE}: {pause_message}")
            if opts.force:
                logging.warning(f"--force is ignored when {PAUSE_FILE} exists")
            return
        except FileNotFoundError:
            pass

        if opts.force:
            ERROR_FILE.unlink()
        if ERROR_FILE.is_file():
            logger.error(
                f"A previous deployment failed. Check the file at {ERROR_FILE} "
                "and re-run manually with --force"
            )
            sys.exit(1)
        ops = operations.RegistryOperations(REGISTRY, logger=logger)
        maxtag_mw = find_last_tag(ops, opts.mediawiki_image)
        maxtag_web = find_last_tag(ops, opts.web_image)
        repo = str(VALUES_DIR.absolute())
        commit = False
        # check if we should deploy mwdebug
        is_deploy = False
        # We update all releases, but we only deploy to mwdebug for now.
        for deployment_file in get_deployment_files():
            updated = values_file_update(deployment_file, maxtag_mw, maxtag_web)
            if updated:
                commit = True
                if "mw-debug" in str(deployment_file):
                    is_deploy = True

        if commit:
            subprocess.run(["git", "commit", "-m", "'Updating release'"], cwd=repo, check=True)

        if is_deploy or opts.force:
            deployment(opts.noninteractive)
        else:
            logger.info("Nothing to deploy")
    except BlockingIOError:
        logger.info("Unable to acquire the lock, not running")
        sys.exit(0)
    except subprocess.CalledProcessError:
        # The deployments have failed, so save the error file.
        ERROR_FILE.write_text(datetime.now().isoformat())
        sys.exit(1)
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        fd.close()


if __name__ == "__main__":
    main()
