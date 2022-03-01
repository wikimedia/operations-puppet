#!/usr/bin/env python3

"""Check the versions of the local mediawiki installation against upstream.

If an appserver falls behind in deployments, we can see weird behaviour. All
machines should be on the expected version and we should know about those that
aren't.

"""

import argparse
import datetime
import json
import os
import sys

from typing import Tuple, Dict

import requests

# How long after wikiversions update are we willing to fail open? In minutes
DEFAULT_WINDOW = 60

DEFAULT_DEPLOY_HOST = "deployment.eqiad.wmnet"
# Path on the deploy host to query for the production wikiversions
DEPLOYMENTS_PATH = "/mediawiki-staging/wikiversions.json"
LOCAL_VERSIONS_FILE = "/srv/mediawiki/wikiversions.json"


class FetchDeploymentsException(Exception):
    """ Something has gone wrong when fetching the upstream deployment versions"""

    pass


class LocalDeploymentException(Exception):
    """ Something has gone wrong with reading the local deployment"""

    pass


class ArgumentError(Exception):
    """ Passed arguments conflict """
    pass


def fetch_production_wikiversions(deployments_url: str) -> Tuple[datetime.datetime, Dict]:
    """ Fetch the deployments file over HTTP """

    try:
        response = requests.get(deployments_url,
                                headers={'User-Agent': 'check_mw_version (python-requests)'})
        response.raise_for_status()
    except requests.exceptions.RequestException as exc:
        raise FetchDeploymentsException("Failed to get deployed version: ({}) {}".format(
            response.status_code,
            exc))

    try:
        last_modified = datetime.datetime.strptime(response.headers["Last-Modified"],
                                                   '%a, %d %b %Y %X %Z')
    except AttributeError:
        sys.stderr.write(
            "Couldn't get last-modified from deploy server - disabling deploy detection\n")
        last_modified = None

    deployment_data = response.json()
    return last_modified, deployment_data


def parse_args() -> argparse.Namespace:
    """ Parse command line arguments """

    parser = argparse.ArgumentParser(
        description='Check local mediawiki versions against the expected deployment')
    parser.add_argument("--deployhost", "-d", dest="deployhost", action="store",
                        default=DEFAULT_DEPLOY_HOST,
                        help="Host to query for current wikiversions file")
    parser.add_argument("--checkurl", "-u", dest="deploy_url", action="store",
                        help="A full URL for a file in wikiversions JSON format")
    parser.add_argument("--https", dest="https", action="store_true",
                        help="Fetch the deployment URL using HTTPS rather than HTTP")
    parser.add_argument("--deploy-time", "-t", dest="deploytime", action="store",
                        default=DEFAULT_WINDOW, type=int,
                        help=("A value in minutes. If the production wikiversions file differs "
                              "and is younger than $deploytime seconds, don't fail."))

    args = parser.parse_args()

    if args.deploy_url and args.deployhost:
        raise ArgumentError("Can't specify a deploy host and a URL at the same time")

    return args


def construct_url(args: argparse.Namespace) -> str:
    """ Construct a URL based on command line args. """

    if args.deploy_url:
        return args.deploy_url

    return "{}://{}{}".format(
        "https" if args.https else "http",
        args.deployhost,
        DEPLOYMENTS_PATH)


def load_local_wikiversions(localversion_path: str) -> dict:
    """ Load the local version mapping file from disk """

    if not os.path.exists(localversion_path):
        raise LocalDeploymentException("Couldn't find local wikiversions file at {}".format(
            localversion_path))
    with open(localversion_path) as local_f:
        return json.load(local_f)


def main():

    args = parse_args()

    try:
        last_modified, production_wikiversions = fetch_production_wikiversions(construct_url(args))
    except FetchDeploymentsException as exc:
        print("UNKNOWN: Couldn't load remote versions: {}".format(exc))
        sys.exit(3)

    try:
        local_wikiversions = load_local_wikiversions(LOCAL_VERSIONS_FILE)
    except LocalDeploymentException:
        print("CRITICAL: Couldn't load local wikiversions file at {}".format(LOCAL_VERSIONS_FILE))
        sys.exit(2)

    failed = False
    nagios_message = ""

    no_alert = False
    if last_modified:
        if datetime.datetime.now() < (last_modified + datetime.timedelta(minutes=args.deploytime)):
            sys.stderr.write("Production wikiversions changed recently - assuming a recent deploy.")
            sys.stderr.write("Not alerting even if we see discrepancies.\n")
            no_alert = True

    if local_wikiversions != production_wikiversions:
        sys.stderr.write("Local wikiversions doesn't match production wikiversions\n")

        missing_sites = set(production_wikiversions.keys()).difference(
            set(local_wikiversions.keys()))
        if missing_sites:
            nagios_message = "Missing {} sites from wikiversions. ".format(len(missing_sites))
            sys.stderr.write("Local copy is missing sites: {}\n".format(" ".join(missing_sites)))
            failed = True

    bad_versions = 0
    for local_site, local_version in local_wikiversions.items():
        official_version = production_wikiversions.get(local_site, "")
        if official_version != local_version:
            sys.stderr.write("Local version for {} is incorrect (local: {}, official: {})\n".format(
                local_site, local_version, official_version))
            bad_versions += 1
            failed = True

    if bad_versions:
        nagios_message += "{} mismatched wikiversions".format(bad_versions)

    if failed:
        if no_alert:
            print("OKAY: Not alerting due to fresh production wikiversions: {}".format(
                    nagios_message))
            sys.exit(0)
        else:
            print("CRITICAL: {}".format(nagios_message))
            sys.exit(2)
    else:
        print("OKAY: wikiversions in sync")
        sys.exit(0)


if __name__ == "__main__":
    main()
