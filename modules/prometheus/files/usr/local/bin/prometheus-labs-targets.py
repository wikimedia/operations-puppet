#!/usr/bin/python3
# Generate Prometheus targets configuration for a given project from nova API.

import argparse
import sys

import yaml

from keystoneclient import client as keystone_client
from keystoneclient import session as keystone_session
from keystoneclient.auth.identity import generic
from novaclient import client as nova_client


HELP_EPILOG = """

The --print-format option accepts .format()-style strings, some examples
can be found at https://docs.python.org/3/library/string.html#format-examples

For example list all default scraping URLs:
  --print-format "http://{name}:{port}/metrics"
"""


def get_session(env, project):
    nova_connection = {
        "username": env["OS_USERNAME"],
        "password": env["OS_PASSWORD"],
        "auth_url": env["OS_AUTH_URL"],
        "project_domain_name": env["OS_PROJECT_DOMAIN_NAME"],
        "user_domain_name": env["OS_USER_DOMAIN_NAME"],
        "project_name": project,
    }
    auth = generic.Password(**nova_connection)
    return keystone_session.Session(auth=auth)


def list_instances(env, project, region):
    session = get_session(env, project)
    client = nova_client.Client("2", session=session, region_name=region)
    for instance in client.servers.list():
        yield instance


def list_regions(env, project):
    session = get_session(env, project)
    client = keystone_client.Client(session=session, interface="public")
    for region in client.regions.list():
        yield region


def main():
    parser = argparse.ArgumentParser(
        epilog=HELP_EPILOG, formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--project", dest="project")
    parser.add_argument(
        "--region",
        default=None,
        dest="region",
        help="Fetch instances for REGION (default: all regions)",
        metavar="REGION",
    )
    parser.add_argument("--port", dest="port", default="9100")
    parser.add_argument(
        "--print-format",
        default=None,
        dest="print_format",
        help="Print each host according to FMT",
        metavar="FMT",
    )
    parser.add_argument(
        "--prefix",
        default="",  # Match everything by default
        help="Only output targets for instances that match this prefix",
    )
    args = parser.parse_args()

    if args.project is None:
        try:
            with open("/etc/wmflabs-project") as f:
                args.project = f.read().strip()
        except IOError as e:
            parser.error(
                "Unable to detect project from /etc/wmflabs-project: {!r}".format(e)
            )
            return 1

    with open("/etc/novaobserver.yaml") as f:
        env = yaml.safe_load(f)

    all_regions = list_regions(env, args.project)
    regions = [r.id for r in all_regions]

    if args.region is not None:
        if args.region not in regions:
            parser.error(
                "Region {!r} invalid. Valid choices: {!r}".format(args.region, regions)
            )
            return 1
        regions = [args.region]

    format_lines = []
    config = {"targets": []}

    for region in regions:
        instances = list_instances(env, args.project, region)
        for instance in instances:
            if not instance.name.startswith(args.prefix):
                continue
            config["targets"].append("{}:{}".format(instance.name, args.port))
            if args.print_format:
                print_args = {
                    "hostname": instance.name,
                    "port": args.port,
                    "project": args.project,
                }
                format_lines.append(args.print_format.format(**print_args))
    config["targets"] = sorted(config["targets"])

    if args.print_format:
        print("\n".join(format_lines))
    else:
        out = []
        out.append(config)
        print(yaml.dump(out, default_flow_style=False))


if __name__ == "__main__":
    sys.exit(main())
