#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import argparse
import logging
import os
import stat
import sys
import subprocess

from pontoon.cloudvps import HORIZON_URL, HOST_DOMAIN, CloudVPS, NovaAuth
from pontoon import Pontoon
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO

log = logging.getLogger()

INSTRUCTIONS = {
    "credentials-missing": """
Credentials not found. In order to get new credentials:
  * Navigate to {horizon_url}/identity/application_credentials
  * Switch to the project for your Pontoon stack from the top left dropdown
  * Create a new application credential and pick a name for it

The credential will need to be written to {config_path} in this form:

credentials:
  default:
    id: <CREDENTIAL-ID>
    secret: <CREDENTIAL-SECRET>
""",
    "git-remote-setup": """
# Setup the Pontoon git remote for {stack} with the following commands:
git remote add pontoon-{stack} ssh://{server}/~/puppet.git

# If the Pontoon server has changed, update its url:
git remote set-url pontoon-{stack} ssh://{server}/~/puppet.git
""",
    "stack-not-found": """

Unable to find stack {stack!r} in path {home!r}.
Make sure to run from a directory with Pontoon stacks, or set PONTOON_HOME to be
the location to search for stacks.
""",
    "ssh-config": """
Below you'll find the ~/.ssh/config snippet to enable Pontoon integration

# Place this configuration *before* your configuration for Cloud VPS (e.g. bastions)
Host *.{host_domain}
  UserKnownHostsFile {config_dir}/ssh_known_hosts
""",
    "bootstrap-stack": """


Your new stack {stack!r} has been bootstrapped!

Make sure to run the commands above to set up git locally.


""",
    "new-stack": """
Stack {stack!r} has been created.

Make sure to commit the stack files before bootstrapping.

git checkout -b pontoon-{stack}
git add {stack}
git commit -m "pontoon: new stack {stack}" {stack}

Then proceed to bootstrap the stack:

pontoonctl bootstrap-stack -s {stack}
""",
    "openstack-config": """
The configuration below can be used as configuration for the openstack commandline client.
Place the file in ~/.config/openstack/clouds.yaml.

{clouds_yaml}

And select the {stack} cloud either via command line or environment:

  openstack --os-cloud {stack}
  export OS_CLOUD={stack}
""",
}


class Credentials(object):
    def __init__(self, config_path: str):
        self.config_path = config_path

        if not os.path.exists(self.config_path):
            raise CredentialsMissing

        if os.stat(self.config_path).st_mode & stat.S_IROTH:
            raise ValueError(f"{self.config_path} is world-readable")

        with open(self.config_path) as f:
            loaded = YAML().load(f)

        try:
            self.creds = loaded["credentials"]["default"]
            self.id = self.creds["id"]
            self.secret = self.creds["secret"]
        except KeyError:
            raise CredentialsMissing


class CredentialsMissing(Exception):
    pass


def configure_ssh(config_dir: str) -> None:
    print(
        INSTRUCTIONS["ssh-config"].format(
            host_domain=HOST_DOMAIN, config_dir=config_dir
        )
    )


def update_ssh_fingerprints(pontoon: Pontoon, config_dir: str) -> None:
    cmd = "ssh-keyscan $(pontoon-enc --list-hosts)"
    outfile = f"{config_dir}/ssh_known_hosts"
    outfile = os.path.expanduser(outfile)

    log.info(f"Updating SSH fingerprints in {outfile}")
    proc = pontoon.ssh_bash(pontoon.server_fqdn, cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        log.error("Failed to update SSH fingerprints: %s", proc.stderr)
        return

    with open(outfile, "w") as known_hosts:
        known_hosts.write(proc.stdout)


def init_stack_ssh(pontoon: Pontoon) -> None:
    """Add the server SSH host key to the user's known_hosts.

    Needed to be able to anchor trust to the server and be able to run 'ssh-keyscan' across stacks.
    """
    server = pontoon.server_fqdn
    log.info(
        f"Logging into {server} for the first time. Please verify and accept the host key."
    )
    subprocess.call(
        [
            "ssh",
            "-o",
            "HashKnownHosts=no",
            f"{server}",
            "true",
        ]
    )


# Adapt dump() to return a string.
# https://yaml.readthedocs.io/en/latest/example/#output-of-dump-as-a-string
class StringYAML(YAML):
    def dump(self, data, stream=None, **kw):
        inefficient = False
        if stream is None:
            inefficient = True
            stream = StringIO()
        YAML.dump(self, data, stream, **kw)
        if inefficient:
            return stream.getvalue()


def print_openstack_config(pontoon: Pontoon, cloud: CloudVPS, creds: Credentials) -> bool:
    """Print clouds.yaml configuration for the pontoon stack."""
    stack = pontoon.name
    auth_cfg = {
        "auth_url": cloud.nova.auth.auth_url,
        "application_credential_secret": creds.secret,
        "application_credential_id": creds.id,
    }
    cfg = {
        "clouds": {
            stack: {
                "interface": "public",
                "identity_api_version": 3,
                "auth_type": "v3applicationcredential",
                "auth": auth_cfg,
            }
        }
    }
    clouds_yaml = StringYAML().dump(cfg)
    print(
        INSTRUCTIONS["openstack-config"].format(
            stack=stack,
            clouds_yaml=clouds_yaml,
        )
    )
    return True


def setup_remote_repositories(pontoon: Pontoon) -> bool:
    """Log in into server and set it up to act as a git remote for the user."""

    stack = pontoon.name
    server = pontoon.server_fqdn
    if not server:
        log.error(f"Unable to find puppetserver::pontoon host for stack {stack}")
        return False

    git_base = "/srv/git"
    repos = {
        "puppet.git": (
            "https://gerrit.wikimedia.org/r/operations/puppet",
            "production",
            f"{git_base}/operations/puppet",
        ),
        "private.git": (
            "https://gerrit.wikimedia.org/r/labs/private",
            "master",
            f"{git_base}/labs/private",
        ),
    }

    log.info(f"Setting up bare repositories on {server}")

    for name, (url, branch, push_path) in repos.items():
        log.info(f"Repository {name}")

        res = pontoon.ssh_bash(
            server, f"pontoon-setup-repo '{branch}' '{url}' $HOME/{name} '{push_path}'"
        )
        if res.returncode != 0:
            log.error(
                f"Unable to set up repository {name}, is {server} accessible and bootstrapped?"
            )
            return False

    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=server))
    return True


def load_credentials(config_path):
    config_dir = os.path.dirname(config_path)
    if not os.path.exists(config_dir):
        os.makedirs(config_dir)

    try:
        creds = Credentials(config_path)
    except ValueError:
        log.exception("Unable to get credentials")
        creds = None
    except CredentialsMissing:
        log.error(
            INSTRUCTIONS["credentials-missing"].format(
                config_path=config_path, horizon_url=HORIZON_URL
            )
        )
        creds = None
    return creds


def as_table(headers, data, separator="|"):
    res = []
    # Format data in columns
    column_widths = [max(len(str(item)) for item in col) for col in zip(headers, *data)]
    res.append(
        separator.join(
            f"{header.ljust(width)}" for header, width in zip(headers, column_widths)
        )
    )
    res.append(separator.join("-" * width for width in column_widths))
    for row in data:
        res.append(
            separator.join(
                f"{str(item).ljust(width)}" for item, width in zip(row, column_widths)
            )
        )

    return res


def main():
    logging.basicConfig(level=logging.INFO)
    fmt = logging.Formatter(fmt="[*] %(message)s")
    [h.setFormatter(fmt) for h in log.handlers]

    base_config_dir = os.environ.get("XDG_CONFIG_HOME", "~/.config")
    config_dir = os.path.join(base_config_dir, "pontoon")
    config_path = os.path.join(os.path.expanduser(config_dir), "cloudvps.yaml")

    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument(
        "-s",
        "--stack",
        type=str,
        metavar="NAME",
        default=os.environ.get("PONTOON_STACK"),
        help="Target Pontoon stack. (env: PONTOON_STACK)",
    )
    parser = argparse.ArgumentParser(
        description="Operate a Pontoon stack",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        epilog=f"Credentials will be read from {config_path}",
    )
    parser.add_argument(
        "--pontoon-home",
        type=str,
        metavar="PATH",
        default=os.environ.get("PONTOON_HOME", "."),
        help="Directory where to locate Pontoon stacks. (env: PONTOON_HOME)",
    )

    actions_p = parser.add_subparsers(
        help="action to perform",
        dest="action",
        required=True,
    )

    def new_action(*args, **kwargs):
        kwargs["parents"] = [common_parser]
        return actions_p.add_parser(*args, **kwargs)

    a = new_action(
        "new-stack",
        help="Create a new stack in the current directory.",
    )
    a.add_argument(
        "--prefix",
        help="Create hosts with NAME prefix.",
        dest="prefix",
        default=None,
        metavar="NAME",
        type=str,
    )

    new_action(
        "ssh-config",
        help="Print SSH client configuration",
    )

    new_action(
        "ssh-keyscan",
        help="Update SSH host fingerprints",
    )

    new_action(
        "openstack-config",
        help="Print openstack CLI client configuration",
    )

    a = new_action(
        "bootstrap-stack",
        help="Bootstrap a newly-created stack",
    )
    a.add_argument(
        "--local-rev",
        help="Use local git checkout rev to bootstrap. Defaults to 'HEAD'.",
        dest="bootstrap_local_rev",
        default="HEAD",
        metavar="REV",
        type=str,
    )

    new_action(
        "join-stack",
        help="Join an existing stack",
    )

    a = new_action("list-hosts", help="List cloud hosts")
    a.add_argument(
        "--all",
        help="List all hosts in the project",
        dest="all_hosts",
        default=False,
        action="store_true",
    )

    a = new_action(
        "create-hosts",
        help="Create missing cloud hosts",
    )
    a.add_argument(
        "--no-block",
        help="Do not block waiting for hosts to be accessible",
        default=False,
        dest="no_block",
        action="store_true",
    )

    a = new_action(
        "reboot-hosts",
        help="Reboot cloud hosts",
    )
    a.add_argument(
        "--no-block",
        help="Do not block waiting for hosts to be accessible again",
        default=False,
        dest="no_block",
        action="store_true",
    )
    a.add_argument(
        "--type",
        help="Perform hard or soft reboot. (default soft)",
        default="SOFT",
        dest="type",
    )
    a.add_argument("pattern")

    a = new_action(
        "destroy-hosts",
        help="Destroy cloud hosts matching a pattern",
    )
    a.add_argument("pattern")

    a = new_action(
        "enroll-hosts",
        help="Enroll cloud hosts into the stack",
    )
    a.add_argument(
        "--force",
        default=False,
        action="store_true",
        help="Pretend no hosts are enrolled already",
    )
    a.add_argument("--role", default=None)

    args = parser.parse_args()
    if args.action == "ssh-config":
        configure_ssh(config_dir)
        return 0

    # Create a new Pontoon as needed for CloudVPS
    home = os.path.expanduser(args.pontoon_home)
    if args.action == "new-stack":
        p = Pontoon.new(args.stack, home)
    elif args.action == "list-hosts":
        if args.stack:
            p = Pontoon(args.stack, home)
        else:
            p = Pontoon("bootstrap", home)
    else:
        if not args.stack:
            parser.error(
                "No stack specified. Use --stack or set PONTOON_STACK in the environment"
            )

        try:
            p = Pontoon(args.stack, home)
        except FileNotFoundError:
            parser.error(
                INSTRUCTIONS["stack-not-found"].format(
                    stack=args.stack, home=args.pontoon_home
                )
            )

    creds = load_credentials(config_path)
    if creds is None:
        return 1

    cloud = CloudVPS(p, NovaAuth(creds.id, creds.secret))
    if args.action == "list-hosts":
        if args.stack and not args.all_hosts:
            log.info(
                "Loading hosts for project %r and stack %r:"
                % (cloud.project_id, p.name)
            )
            print("\n".join(as_table(*cloud.list_hosts())))
        else:
            log.info("Loading hosts for project %r:" % cloud.project_id)
            print("\n".join(as_table(*cloud.list_hosts(all=True))))
    elif args.action == "create-hosts":
        cloud.create_hosts(args.no_block)
        update_ssh_fingerprints(p, config_dir)
    elif args.action == "enroll-hosts":
        # XXX handle failure, print instructions
        ok = cloud.enroll_hosts(args.role, args.force)
        if ok:
            update_ssh_fingerprints(p, config_dir)
    elif args.action == "destroy-hosts":
        # XXX wait for destruction?
        # XXX stack shouldn't be mandatory ?
        cloud.destroy_hosts(args.pattern)
    elif args.action == "reboot-hosts":
        cloud.reboot_hosts(args.pattern, args.type, args.no_block)
    elif args.action == "bootstrap-stack":
        init_stack_ssh(p)
        ok = cloud.bootstrap_stack(from_local_rev=args.bootstrap_local_rev)
        if ok:
            setup_remote_repositories(p)
            print(INSTRUCTIONS["bootstrap-stack"].format(stack=p.name))
        else:
            log.error("Error bootstrapping")
    elif args.action == "new-stack":
        ok = cloud.new_stack(args.prefix)
        if ok:
            print(INSTRUCTIONS["new-stack"].format(stack=p.name))
    elif args.action == "ssh-keyscan":
        update_ssh_fingerprints(p, config_dir)
    elif args.action == "openstack-config":
        print_openstack_config(p, cloud, creds)
    elif args.action == "join-stack":
        setup_remote_repositories(p)
    else:
        parser.print_help()


if __name__ == "__main__":
    sys.exit(main())
