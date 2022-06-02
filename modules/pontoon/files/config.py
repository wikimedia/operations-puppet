#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# This script helps the user to interact with their stack, either by aiding
# local setup (e.g. git configuration) or remote hosts (e.g. git remote setup).

# The script is meant to be ran locally on the user's workstation from a puppet.git checkout.
import argparse
import logging
import os
import shlex
import subprocess

from enc import Pontoon

log = logging.getLogger()

SSH_CONNECT_TIMEOUT = 6


def ssh_bash(host, cmd, *args, **kwargs):
    ssh_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={SSH_CONNECT_TIMEOUT}",
    ]
    return subprocess.run(
        ssh_cmd + [host, "bash", "-c", shlex.quote(cmd)], *args, **kwargs
    )


def git_config_remote(stack):
    print(f"# The following commands will setup the Pontoon git remote for {stack}")
    print(f"git remote add pontoon-{stack} ssh://{server}/~/puppet.git")
    print(f"git remote add pontoon-{stack}-private ssh://{server}/~/private.git")


def setup_remote(server):
    """Log in into server and setup bare remote repositories in the user's HOME.

    The repos will receive changes via git push from the user's workstation
    and update the canonical git repositories on the server."""

    puppet_git_path = "/var/lib/git/operations/puppet"
    hook_path = f"{puppet_git_path}/modules/puppetmaster/files/self-master-post-receive"
    repos = {
        "puppet.git": (puppet_git_path, "production"),
        "private.git": ("/var/lib/git/labs/private", "master"),
    }

    logging.info(f"Setting up bare repositories on {server}")
    for name, (path, branch) in repos.items():
        logging.info(f"Repository {name}")

        clone_cmd = (
            f"[ -d ~/{name} ] || "
            f"git clone --bare --no-hardlinks --branch {branch} {path} ~/{name}"
        )
        hook_cmd = (
            f"[ -e ~/{name}/hooks/post-receive ] || "
            f"install -v -m755 {hook_path} ~/{name}/hooks/post-receive"
        )

        ssh_bash(server, f"({clone_cmd}) && ({hook_cmd})")


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser(
        description="Interact with your stack's configuration and run setup tasks."
    )
    parser.add_argument(
        "-s",
        "--stack",
        type=str,
        metavar="NAME",
        default=os.environ.get("PONTOON_STACK"),
        help="Target Pontoon stack",
    )
    subparsers = parser.add_subparsers(help="action to perform", dest="action")
    subparsers.add_parser(
        "git-config-remote", help='print "git remote" configuration for stack'
    )
    subparsers.add_parser(
        "setup-remote",
        help="setup the stack's puppet server bare repositories for the current user",
    )

    args = parser.parse_args()

    if not args.stack:
        parser.error("No --stack specified")

    scriptdir = os.path.dirname(os.path.realpath(__file__))

    config = os.path.join(scriptdir, args.stack, "rolemap.yaml")
    with open(config, encoding="utf-8") as f:
        p = Pontoon(f)

    server = p.hosts_for_role("puppetmaster::pontoon")[0]

    if args.action == "git-config-remote":
        git_config_remote(args.stack)
    elif args.action == "setup-remote":
        setup_remote(server)
    else:
        parser.print_help()
