#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import logging
import os
import sys
import subprocess
import json

from .cloudvps import CloudVPS
from .nova import HORIZON_URL, HOST_DOMAIN
from . import Pontoon
from .credentials import CredentialsMissing, load_credentials
from .enroll import Enroller
from .util import ssh_bash, as_table
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO
from typing import Optional

import click

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

pontoonctl bootstrap-stack --stack {stack}
""",
    "openstack-config": """
The YAML snippet below can be used as configuration for the openstack commandline client.
Place the file in ~/.config/openstack/clouds.yaml.

{clouds_yaml}

And select the {stack!r} cloud:

openstack --os-cloud {stack}
  or
export OS_CLOUD={stack}
""",
}


class Controller(object):
    def __init__(self, pontoon: Pontoon, cloud: CloudVPS):
        self.yaml = YAML()
        self.pontoon = pontoon
        self.cloud = cloud

    @classmethod
    def config_dir(cls):
        """Where to store Pontoon configuration."""
        base_config_dir = os.environ.get("XDG_CONFIG_HOME", "~/.config")
        config_dir = os.path.join(base_config_dir, "pontoon")
        return os.path.expanduser(config_dir)

    @property
    def server(self) -> Optional[str]:
        return self.pontoon.server_fqdn

    def _host_prefix(self, stack_name: str) -> str:
        if "-" not in stack_name:
            return stack_name

        # Pick a short(er) name as host prefix
        novowels = stack_name.translate({ord(i): None for i in "aeiouAEIOU"})
        return novowels

    def new_stack(self, host_prefix: Optional[str] = None) -> bool:
        if host_prefix is None:
            host_prefix = self._host_prefix(self.pontoon.name)

        server = self.pontoon.server_fqdn
        if server is not None:
            raise click.UsageError(
                f"stack {self.pontoon.name!r} already exists ({server} found in rolemap)"
            )

        fqdn = self.cloud.fqdn(f"{host_prefix}-puppet-01")
        if fqdn in self.cloud.fqdns:
            raise click.UsageError(
                f"The server {fqdn} exists in project {self.cloud.project!r},"
                f"choose a different prefix."
            )

        self.pontoon.add_host_to_role(fqdn, "puppetserver::pontoon")
        self.pontoon.save()
        return True

    def bootstrap_stack(self, local_rev: str) -> bool:
        # XXX run init_ssh_access after host is created?
        if not self.server:
            raise click.UsageError(
                f"Server not found for {self.pontoon.name}, unable to bootstrap"
            )

        self.cloud.create_hosts(hosts=set([self.server]))
        log.info(f"Bootstrapping {self.server} for stack {self.pontoon.name}")
        bootstrap_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "bootstrap.sh"
        )
        status = subprocess.call(
            [
                "scp",
                "-q",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                bootstrap_path,
                self.server + ":",
            ]
        )
        if status != 0:
            log.error("Error copying bootstrap.sh")
            return False

        proc = ssh_bash(
            self.server,
            f"sudo ./bootstrap.sh --check {self.pontoon.name}",
        )

        if proc.returncode == 2:
            log.info("Bootstrap already completed.")
            return True

        # Users can provide their code/data in $HOME/bootstrap
        send_local_checkout = f"""
        cd $(git rev-parse --show-toplevel) && \
            git archive --format tgz {local_rev} | \
                ssh -o StrictHostKeyChecking=no {self.server} \
                    'install -d bootstrap/puppet && tar zxf - -C bootstrap/puppet'
        """
        log.info(f"Sending local checkout of {local_rev} to {self.server}")
        subprocess.call(["bash", "-c", send_local_checkout])

        log.info(f"Bootstrapping {self.server}")
        proc = ssh_bash(self.server, f"sudo ./bootstrap.sh {self.pontoon.name}")

        if proc.returncode != 0:
            log.error(f"Error running bootstrap.sh on {self.server}")
            return False

        return True

    def enroll_hosts(self, role: Optional[str], force: bool = False) -> bool:
        candidates = self.pontoon.host_map().keys()

        if role is not None:
            try:
                candidates = self.pontoon.hosts_for_role(role)
            except ValueError:
                log.error(f"Role {role!r} not found")
                return False

        if force:
            enrolled_hosts = []
        else:
            log.info("Searching for hosts not yet enrolled")
            proc = ssh_bash(
                self.pontoon.server_fqdn,
                "sudo puppetserver ca list --format json --all",
                capture_output=True,
                text=True,
            )
            try:
                ca_list = json.loads(proc.stdout)
            except json.decoder.JSONDecodeError:
                log.error(f"Unable to get list of enrolled hosts from {proc.stdout!r}")
                return False
            enrolled_hosts = [x["name"] for x in ca_list["signed"]]

        to_enroll = set(candidates) - set(enrolled_hosts)
        if not to_enroll:
            log.info("No hosts to enroll")
            return False

        # Abort if the hosts are not known yet to the server
        proc = ssh_bash(
            self.pontoon.server_fqdn,
            "pontoon-enc --list-hosts",
            capture_output=True,
            text=True,
        )
        enrollable_hosts = proc.stdout.split("\n")
        missing_on_server = set(to_enroll) - set(enrollable_hosts)
        if missing_on_server:
            log.error(
                f"Hosts to enroll and not found on Pontoon server: {missing_on_server}"
            )
            log.error("You might need to push an updated rolemap.yaml")
            return False

        e = Enroller(self.pontoon)
        ok = True
        for host in to_enroll:
            if not e.enroll(host, force=force):
                ok = False
        return ok

    def init_ssh_access(self) -> bool:
        """Add the server SSH host key to the user's known_hosts.

        Needed to be able to anchor trust to the server and be able
        to run 'ssh-keyscan' across stacks.
        """
        server = self.pontoon.server_fqdn
        log.info(
            f"Logging into {server} for the first time. Please verify and accept the host key."
        )
        p = subprocess.run(
            [
                "ssh",
                "-o",
                "HashKnownHosts=no",
                f"{server}",
                "true",
            ]
        )
        return p.returncode == 0

    def setup_remote_repositories(self) -> bool:
        """Log in into server and set it up to act as a git remote for the user."""

        stack = self.pontoon.name
        server = self.pontoon.server_fqdn
        if not server:
            click.UsageError(
                f"Unable to find puppetserver::pontoon host for stack {stack}"
            )
            return False

        repos = {
            "puppet.git": (
                "https://gerrit.wikimedia.org/r/operations/puppet",
                "production",
                "/srv/git/operations/puppet",
            ),
            "private.git": (
                "https://gerrit.wikimedia.org/r/labs/private",
                "master",
                "/srv/git/labs/private",
            ),
        }

        log.info(f"Setting up bare repositories on {server}")

        for name, (url, branch, push_path) in repos.items():
            log.info(f"Repository {name}")

            res = ssh_bash(
                server,
                f"pontoon-setup-repo '{branch}' '{url}' $HOME/{name} '{push_path}'",
            )
            if res.returncode != 0:
                log.error(
                    f"Unable to set up repository {name}, is {server} accessible and bootstrapped?"
                )
                return False

        return True

    def update_ssh_fingerprints(self) -> bool:
        cmd = "ssh-keyscan $(pontoon-enc --list-hosts)"
        outfile = f"{self.config_dir()}/ssh_known_hosts"

        log.info(f"Updating SSH fingerprints in {outfile}")
        proc = ssh_bash(self.pontoon.server_fqdn, cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            log.error("Failed to update SSH fingerprints: %s", proc.stderr)
            return False

        with open(outfile, "w") as known_hosts:
            known_hosts.write(proc.stdout)

        return True


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


def get_controller(stack, home) -> Controller:
    if stack is None:
        raise click.UsageError("stack required")

    try:
        p = Pontoon(stack, home)
    except FileNotFoundError:
        raise click.UsageError(
            INSTRUCTIONS["stack-not-found"].format(
                stack=stack,
                home=home,
            )
        )

    credentials_path = os.path.join(Controller.config_dir(), "cloudvps.yaml")
    try:
        creds = load_credentials(credentials_path)
    except ValueError:
        raise click.UsageError(f"Unable to get credentials from {credentials_path}")
    except CredentialsMissing:
        raise click.UsageError(
            INSTRUCTIONS["credentials-missing"].format(
                config_path=credentials_path, horizon_url=HORIZON_URL
            ),
        )

    cloud = CloudVPS(p, creds)
    return Controller(p, cloud)


def with_stack(func):
    """Common decorator to add a --stack option to a command."""
    func = click.option(
        "-s",
        "--stack",
        type=str,
        metavar="NAME",
        default=os.environ.get("PONTOON_STACK"),
        help="Target Pontoon stack. (env: PONTOON_STACK)",
    )(func)
    return func


# List commands in --help in the same order they are defined in code
# https://github.com/pallets/click/issues/513#issuecomment-504158316
class NaturalOrderGroup(click.Group):
    def list_commands(self, ctx):
        return self.commands.keys()


@click.group(cls=NaturalOrderGroup)
@click.option(
    "--home",
    type=str,
    metavar="PATH",
    default=lambda: os.environ.get("PONTOON_HOME", "."),
    help="Directory where to locate Pontoon stacks (env: PONTOON_HOME)",
)
@click.pass_context
def ctl(ctx, home):
    ctx.ensure_object(dict)
    ctx.obj["home"] = os.path.expanduser(home)


@ctl.command()
@click.argument("name")
@click.option(
    "--prefix", metavar="NAME", help="Create hosts with NAME prefix.", default=None
)
@click.pass_obj
def new_stack(obj, name, prefix):
    Pontoon.new(name, obj["home"])
    ctrl = get_controller(name, obj["home"])
    ok = ctrl.new_stack(prefix)
    if ok:
        print(INSTRUCTIONS["new-stack"].format(stack=name))
    else:
        raise click.UsageError("Failed to create a new stack")


@ctl.command()
@with_stack
@click.option(
    "--local-rev",
    help="Use local git checkout rev to bootstrap. Defaults to 'HEAD'.",
    default="HEAD",
    metavar="REV",
    type=str,
)
@click.pass_obj
def bootstrap_stack(obj, stack, local_rev):
    ctrl = get_controller(stack, obj["home"])

    ok = ctrl.bootstrap_stack(local_rev)
    if not ok:
        log.error("Error bootstrapping")
        return 1

    ok = ctrl.setup_remote_repositories()
    if not ok:
        log.error("Error setting up remote repositories")
        return 1

    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=ctrl.server))
    print(INSTRUCTIONS["bootstrap-stack"].format(stack=stack))


@ctl.command()
@with_stack
@click.pass_context
def join_stack(ctx, stack):
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.setup_remote_repositories()
    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=ctrl.server))


@ctl.command()
@with_stack
@click.option(
    "--all",
    is_flag=True,
)
@click.option("--output", default="table", type=click.Choice(["fqdn", "table"]))
@click.pass_obj
def list_hosts(obj, stack, all, output):
    ctrl = get_controller(stack, obj["home"])
    hosts = ctrl.cloud.list_hosts()
    if not all:
        stack_fqdns = ctrl.pontoon.host_map().keys()
        hosts = [h for h in hosts if h.fqdn in stack_fqdns]

    if output == "fqdn":
        print("\n".join([h.fqdn for h in hosts]))
    elif output == "table":
        header = ("FQDN", "Image", "Flavor")
        data = []
        for h in hosts:
            data.append((h.fqdn, h.image, h.flavor))
        if not all:
            log.info(
                "Listing hosts for project %r and stack %r:"
                % (ctrl.cloud.project, stack)
            )
        else:
            log.info("Listing hosts for project %r:" % (ctrl.cloud.project))
        print("\n".join(as_table(header, data)))


@ctl.command()
@with_stack
@click.pass_context
def create_hosts(ctx, stack):
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.cloud.create_hosts()
    ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@click.option("--role")
@click.option("--force", is_flag=True, default=False)
@click.pass_context
def enroll_hosts(ctx, stack, role, force):
    # XXX handle failure, print instructions
    ctrl = get_controller(stack, ctx.obj["home"])
    ok = ctrl.enroll_hosts(role, force)
    if ok:
        ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@click.argument("pattern")
@click.pass_context
def destroy_hosts(ctx, stack, pattern):
    # XXX wait for destruction?
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.cloud.destroy_hosts(pattern)


@ctl.command()
@with_stack
@click.argument("pattern")
@click.option("--type", default="soft", type=click.Choice(["soft", "hard"]))
@click.option("--block/--no-block", default=True)
@click.pass_context
def reboot_hosts(ctx, stack, pattern, type, block):
    # XXX wait for destruction?
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.cloud.reboot_hosts(pattern, type, not block)


@ctl.command()
def ssh_config():
    print(
        INSTRUCTIONS["ssh-config"].format(
            host_domain=HOST_DOMAIN, config_dir=Controller.config_dir()
        )
    )


@ctl.command()
@with_stack
@click.pass_context
def ssh_keyscan(ctx, stack):
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@click.pass_context
def openstack_config(ctx, stack):
    ctrl = get_controller(stack, ctx.obj["home"])
    cfg = ctrl.cloud.openstack_config
    print(
        INSTRUCTIONS["openstack-config"].format(
            stack=stack,
            clouds_yaml=StringYAML().dump(cfg),
        )
    )


def main():
    logging.basicConfig(level=logging.INFO)
    fmt = logging.Formatter(fmt="[*] %(message)s")
    [h.setFormatter(fmt) for h in log.handlers]

    return ctl()


if __name__ == "__main__":
    sys.exit(main())
