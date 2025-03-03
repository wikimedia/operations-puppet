#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import json
import logging
import os
import subprocess
import sys
from dataclasses import dataclass
from typing import Optional

import click
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO

from . import Pontoon
from .cloudvps import CloudVPS
from .credentials import Credentials, CredentialsMissing, load_credentials
from .enroll import Enroller
from .nova import HORIZON_URL, HOST_DOMAIN
from .rolegroups import RoleGroups
from .util import (
    as_table,
    ssh_bash,
    SSH_CONNECT_TIMEOUT_SECONDS,
    wait_subprocesses,
    HOSTS_ACCESS_TIMEOUT_MINUTES,
)

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
and host autocompletion.

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
    "add-rolegroup": """
The rolegroup {name!r} has been added to the stack {stack!r}.
Please inspect the changes in {stack_path!r}, then commit and push them:

git add {stack_path}
git commit -m "pontoon: add rolegroup {name} to {stack}"
git push -f pontoon-{stack} HEAD:production
""",
}


@dataclass
class WaitPuppetResult:
    fqdn: str
    status: str
    stdout: str
    stderr: str


class Controller(object):
    def __init__(self, pontoon: Pontoon, cloud: CloudVPS):
        self._rolegroups = None
        self.yaml = YAML()
        self.pontoon = pontoon
        self.cloud = cloud

    @classmethod
    def config_dir(cls) -> str:
        """Where to store Pontoon configuration."""
        base_config_dir = os.environ.get("XDG_CONFIG_HOME", "~/.config")
        config_dir = os.path.join(base_config_dir, "pontoon")
        return os.path.expanduser(config_dir)

    @property
    def server(self) -> Optional[str]:
        return self.pontoon.server_fqdn

    @property
    def rolegroups(self) -> RoleGroups:
        if self._rolegroups is not None:
            return self._rolegroups
        self._rolegroups = self._load_rolegroups()
        return self._rolegroups

    def _load_rolegroups(self) -> RoleGroups:
        groupmap = {}

        groupfile = os.path.join(self.pontoon.base_path, "rolegroups.yaml")
        with open(groupfile, encoding="utf-8") as f:
            groupmap = self.yaml.load(f)

        stack_groupfile = os.path.join(self.pontoon.stack_path, "rolegroups.yaml")
        if os.path.exists(stack_groupfile):
            with open(stack_groupfile, encoding="utf-8") as f:
                stack_groupmap = self.yaml.load(f)
                groupmap.update(stack_groupmap)

        return RoleGroups(groupmap)

    def add_rolegroup(self, name: str) -> bool:
        """Add a role group to the Pontoon stack.

        Args:
            name (str): The role group to add
        """
        group = self.rolegroups.get_group(name)
        if not group.roles:
            log.error("Group %s not found", name)
            return False

        for role in group.roles:
            if role in self.pontoon.rolemap:
                log.debug("Role %s already exists, skipping", role)
                continue
            hostname = self._hostname_for_role(role)
            fqdn = self.cloud.fqdn(hostname)
            self.pontoon.add_host_to_role(fqdn, role)
        self.pontoon.save()

        for setting in group.settings:
            destfile = f"{self.pontoon.stack_path}/hiera/{setting}.yaml"
            if os.path.lexists(destfile):
                log.debug("Setting %s already exists, skipping", setting)
                continue
            os.symlink(f"../../settings/{setting}.yaml", destfile)
            if not os.path.exists(destfile):
                log.error(
                    f"Unable to find source setting file for {setting}. "
                    f"Check {self.pontoon.stack_path}/hiera"
                )
                continue

        return True

    def wait_puppet(self, role: Optional[str]) -> tuple[bool, list[WaitPuppetResult]]:
        """Wait for puppet runs to finish on hosts.

        Args:
            role (str): The role to wait for, or None for all roles

        Returns:
            bool: True if all hosts succeeded, False otherwise
            List[WaitPuppetResult]: List of results for each host
        """

        def commands_for_hosts(hosts):
            """Generator yielding (command, subprocess) tuples."""
            for host in hosts:
                proc = subprocess.Popen(
                    [
                        "ssh",
                        "-o",
                        "BatchMode=yes",
                        "-o",
                        "ControlPersist=5",
                        "-o",
                        "RequestTty=force",  # make sure remote processes get SIGHUP on exit
                        "-o",
                        f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
                        host,
                        "sudo pontoon-wait-puppet",
                    ],
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                yield host, proc

        candidates = self.pontoon.host_map().keys()

        if role is not None:
            try:
                candidates = self.pontoon.hosts_for_role(role)
            except ValueError:
                log.error(f"Role {role!r} not found")
                return False, [WaitPuppetResult("", "", "", "")]

        log.info(f"Waiting for puppet to converge on {len(candidates)} hosts")

        results = wait_subprocesses(
            commands_for_hosts(candidates), timeout=60 * HOSTS_ACCESS_TIMEOUT_MINUTES
        )

        ret = []

        ok = True
        for fqdn, result in results.items():
            returncode, stdout, stderr = result
            status = "success" if returncode == 0 else "error"
            ret.append(WaitPuppetResult(fqdn, status, stdout, stderr))
            if returncode != 0:
                ok = False

        return ok, ret

    def _hostname_for_role(self, role: str, id: str = "01") -> str:
        host_prefix = self._host_prefix(self.pontoon.name)
        role_hostname = self.cloud.specs_for_role(role).hostname
        return f"{host_prefix}-{role_hostname}-{id}"

    def _host_prefix(self, stack_name: str) -> str:
        if "-" not in stack_name:
            return stack_name

        # Pick a short(er) name as host prefix
        novowels = stack_name.translate({ord(i): None for i in "aeiouAEIOU"})
        return novowels

    def new_stack(self) -> bool:
        if self.server is not None:
            raise click.UsageError(
                f"stack {self.pontoon.name!r} already exists ({self.server} found in rolemap)"
            )

        hostname = self._hostname_for_role("puppetserver::pontoon")
        fqdn = self.cloud.fqdn(hostname)
        if fqdn in self.cloud.fqdns:
            raise click.UsageError(
                f"The server {fqdn} exists in project {self.cloud.project!r}"
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
            log.info("Searching for hosts to enroll")
            proc = ssh_bash(
                self.server,
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
            self.server,
            "pontoon-enc --list-hosts",
            capture_output=True,
            text=True,
        )
        enrollable_hosts = proc.stdout.split("\n")
        missing_on_server = set(to_enroll) - set(enrollable_hosts)
        if missing_on_server:
            log.error(
                "The following hosts need enrolling and could not be found ."
                f"on Pontoon server: {missing_on_server}"
            )
            log.error("You might need to push an updated rolemap.yaml")
            return False

        e = Enroller(self.pontoon)
        ok = True
        # XXX enroll concurrently ?
        for host in to_enroll:
            if not e.enroll(host, force=force):
                ok = False
                # Normally pontoon-wait-puppet is deployed by Puppet, though
                # during enrollment the first puppet run can fail too.
                # The script can be used to wait for puppet runs to succeed.
                self._install_wait_puppet(host)

        return ok

    def _install_wait_puppet(self, host: str) -> bool:
        wait_puppet_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "pontoon_wait_puppet.py"
        )
        status = subprocess.call(
            [
                "scp",
                "-q",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                wait_puppet_path,
                f"{host}:/tmp/pontoon_wait_puppet.py",
            ]
        )

        if status != 0:
            log.error(f"Error copying {wait_puppet_path}")
            return False

        p = ssh_bash(
            host,
            "sudo install -m755 /tmp/pontoon_wait_puppet.py /usr/local/bin/pontoon-wait-puppet",
        )
        if p.returncode != 0:
            log.error("Failed to install pontoon-wait-puppet")
            return False

        return True

    def init_ssh_access(self) -> bool:
        """Add the server SSH host key to the user's known_hosts.

        Needed to be able to anchor trust to the server and be able
        to run 'ssh-keyscan' across stacks.
        """
        log.info(
            f"Logging into {self.server} for the first time. Please verify and accept the host key."
        )
        p = subprocess.run(
            [
                "ssh",
                "-o",
                "HashKnownHosts=no",
                f"{self.server}",
                "true",
            ]
        )
        return p.returncode == 0

    def setup_remote_repositories(self) -> bool:
        """Set up the Pontoon stack server to act as a git remote for the user."""

        stack = self.pontoon.name
        if not self.server:
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

        log.info(f"Setting up bare repositories on {self.server}")

        for name, (url, branch, push_path) in repos.items():
            log.info(f"Repository {name}")

            res = ssh_bash(
                self.server,
                f"pontoon-setup-repo '{branch}' '{url}' $HOME/{name} '{push_path}'",
            )
            if res.returncode != 0:
                log.error(
                    f"Unable to set up repository {name}. "
                    f"Is {self.server} accessible and bootstrapped?"
                )
                return False

        return True

    def update_ssh_fingerprints(self) -> bool:
        cmd = "ssh-keyscan $(pontoon-enc --list-hosts)"
        outfile = f"{self.config_dir()}/ssh_known_hosts"

        log.info(f"Updating SSH fingerprints in {outfile}")
        proc = ssh_bash(self.server, cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            log.error("Failed to update SSH fingerprints: %s", proc.stderr)
            return False

        with open(outfile, "w") as known_hosts:
            known_hosts.write(proc.stdout)

        return True


def get_credentials() -> Credentials:
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
    return creds


def get_controller(stack, home) -> Controller:
    if stack is None:
        raise click.UsageError("--stack or PONTOON_STACK required")

    try:
        p = Pontoon(stack, home)
    except FileNotFoundError:
        raise click.UsageError(
            INSTRUCTIONS["stack-not-found"].format(
                stack=stack,
                home=home,
            )
        )

    creds = get_credentials()
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
        shell_complete=complete_stacks,
        help="Target Pontoon stack. (env: PONTOON_STACK)",
    )(func)
    return func


def with_role(func):
    """Common decorator to add a --role option to a command."""
    func = click.option(
        "--role",
        type=str,
        metavar="ROLE",
        shell_complete=complete_roles,
        help="Operate on hosts belonging to ROLE",
    )(func)
    return func


def complete_stacks(ctx, param, incomplete) -> list[str]:
    p = Pontoon("bootstrap", _pontoon_home())
    return [k for k in p.available_stacks if k.startswith(incomplete)]


def complete_roles(ctx, param, incomplete) -> list[str]:
    stack = os.environ.get("PONTOON_STACK")
    if not stack:
        return []

    p = Pontoon(stack, _pontoon_home())
    return [k for k in p.available_roles if k.startswith(incomplete)]


def _pontoon_home(default=".") -> str:
    return os.path.expanduser(os.environ.get("PONTOON_HOME", default))


# List commands in --help in the same order they are defined in code
# https://github.com/pallets/click/issues/513#issuecomment-504158316
class NaturalOrderGroup(click.Group):
    def list_commands(self, ctx):
        return self.commands.keys()


CONTEXT_SETTINGS = dict(help_option_names=["-h", "--help"])


@click.group(cls=NaturalOrderGroup, context_settings=CONTEXT_SETTINGS)
@click.option(
    "--home",
    type=str,
    metavar="PATH",
    default=lambda: _pontoon_home(),
    help="Path to Pontoon stacks (env: PONTOON_HOME, default '.')",
)
@click.pass_context
def ctl(ctx, home):
    """Pontoon control tool"""
    ctx.ensure_object(dict)
    ctx.obj["home"] = os.path.expanduser(home)


@ctl.command()
@click.argument("name")
@click.pass_context
def new_stack(ctx, name):
    """Create a new stack"""
    Pontoon.new(name, ctx.obj["home"])
    ctrl = get_controller(name, ctx.obj["home"])
    ok = ctrl.new_stack()
    if not ok:
        raise click.UsageError("Failed to create a new stack")
    print(INSTRUCTIONS["new-stack"].format(stack=name))


@ctl.command()
@with_stack
@click.option(
    "--local-rev",
    help="Use local git checkout rev to bootstrap. Defaults to 'HEAD'.",
    default="HEAD",
    metavar="REV",
    type=str,
)
@click.pass_context
def bootstrap_stack(ctx, stack, local_rev):
    """Bootstrap an existing stack"""
    ctrl = get_controller(stack, ctx.obj["home"])

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
    """Configure the stack to be available for local development"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ok = ctrl.setup_remote_repositories()
    if not ok:
        log.error("Error setting up remote repositories")
        return 1
    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=ctrl.server))


@ctl.command()
@with_stack
@click.option(
    "--all",
    is_flag=True,
    default=False,
    help="List all hosts, not just those in the stack",
)
@click.option(
    "--output",
    default="table",
    type=click.Choice(["fqdn", "table"]),
    help="Output format. 'fqdn' is suitable for scripting.",
)
@click.pass_context
def list_hosts(ctx, stack, all, output):
    """Show hosts belonging to the stack, or --all"""
    # don't require stack when listing all hosts
    if stack is None and all:
        stack = "bootstrap"
    ctrl = get_controller(stack, ctx.obj["home"])
    hosts = ctrl.cloud.list_hosts()
    if not all:
        # Filter out hosts not in the stack
        stack_fqdns = ctrl.pontoon.host_map().keys()
        hosts = [h for h in hosts if h.fqdn in stack_fqdns]

    hosts = sorted(hosts, key=lambda h: h.fqdn)

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
@with_role
@click.option(
    "--block/--no-block",
    default=True,
    help="Don't wait for creation to complete (default 'block')",
)
@click.pass_context
def create_hosts(ctx, stack, role, block):
    """Create hosts for the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.cloud.create_hosts(role=role, block=block)
    ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@with_role
@click.option("--force", is_flag=True, default=False, help="Force re-enrollment")
@click.pass_context
def enroll_hosts(ctx, stack, role, force):
    """Enroll hosts for the stack"""
    # XXX handle failure, print instructions
    ctrl = get_controller(stack, ctx.obj["home"])
    ok = ctrl.enroll_hosts(role, force)
    if ok:
        ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@with_role
@click.argument("pattern", required=False)
@click.pass_context
def destroy_hosts(ctx, stack, role, pattern):
    """Destroy hosts matching a pattern or role"""
    # XXX wait for destruction?
    ctrl = get_controller(stack, ctx.obj["home"])
    if not (pattern or role):
        raise click.UsageError("Specify a pattern or --role to destroy hosts")
    ctrl.cloud.destroy_hosts(pattern or "*", role=role)


@ctl.command()
@with_stack
@with_role
@click.argument("pattern", required=False)
@click.option(
    "--type",
    default="soft",
    type=click.Choice(["soft", "hard"]),
    help="'hard' will power cycle the host. (default 'soft')",
)
@click.option(
    "--block/--no-block",
    default=True,
    help="Don't wait for reboot to complete (default 'block')",
)
@click.pass_context
def reboot_hosts(ctx, stack, role, pattern, type, block):
    """Reboot hosts matching a pattern or role"""
    # XXX wait for destruction?
    ctrl = get_controller(stack, ctx.obj["home"])
    if not (pattern or role):
        raise click.UsageError("Specify a pattern or --role to reboot hosts")
    ctrl.cloud.reboot_hosts(pattern or "*", type, block, role=role)


@ctl.command()
@with_stack
@with_role
@click.pass_context
def wait_puppet(ctx, stack, role):
    """Add a rolegroup (a collection of roles) to the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])
    _, results = ctrl.wait_puppet(role)

    ok = True
    for result in sorted(results, key=lambda x: x.fqdn):
        if result.status != "success":
            ok = False
            print(result.fqdn)
            print(result.stdout)
            print(result.stderr)

    if ok:
        log.info("Puppet runs completed")
    else:
        log.info("Puppet runs failed")

    return ok


@ctl.command()
@with_stack
@click.argument("name")
@click.pass_context
def add_rolegroup(ctx, stack, name):
    """Add a rolegroup (a collection of roles) to the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ok = ctrl.add_rolegroup(name)
    if not ok:
        raise click.UsageError("Failed to add rolegroup")
    stack_path = os.path.relpath(ctrl.pontoon.stack_path, os.getcwd())
    print(
        INSTRUCTIONS["add-rolegroup"].format(
            name=name,
            stack=stack,
            stack_path=stack_path,
        )
    )


@ctl.command()
def ssh_config():
    """Show the local SSH configuration snippet for Pontoon"""
    print(
        INSTRUCTIONS["ssh-config"].format(
            host_domain=HOST_DOMAIN, config_dir=Controller.config_dir()
        )
    )


@ctl.command()
@with_stack
@click.pass_context
def ssh_keyscan(ctx, stack):
    """Update Pontoon's known_hosts file with the stack' SSH fingerprints"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.update_ssh_fingerprints()


@ctl.command()
@with_stack
@click.pass_context
def openstack_config(ctx, stack):
    """Show the OpenStack configuration snippet for the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])
    cfg = ctrl.cloud.openstack_config

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

    print(
        INSTRUCTIONS["openstack-config"].format(
            stack=stack,
            clouds_yaml=StringYAML().dump(cfg),
        )
    )


def main() -> int:
    logging.basicConfig(level=logging.INFO)
    fmt = logging.Formatter(fmt="[*] %(message)s")
    [h.setFormatter(fmt) for h in log.handlers]

    return ctl()


if __name__ == "__main__":
    sys.exit(main())
