#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import logging
import os

import click
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO

from pontoon import Pontoon
from pontoon.cloudvps import CloudVPS
from pontoon.controller import Controller
from pontoon.credentials import Credentials, CredentialsMissing, load_credentials
from pontoon.nova import HORIZON_URL, HOST_DOMAIN
from pontoon.util import as_table

log = logging.getLogger()

CLICK_CONTEXT_SETTINGS = dict(help_option_names=["-h", "--help"])

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
    p = Pontoon("bootstrap", pontoon_home())
    return [k for k in p.available_stacks if k.startswith(incomplete)]


def complete_roles(ctx, param, incomplete) -> list[str]:
    stack = os.environ.get("PONTOON_STACK")
    if not stack:
        return []

    p = Pontoon(stack, pontoon_home())
    return [k for k in p.available_roles if k.startswith(incomplete)]


def pontoon_home(default=".") -> str:
    """
    Used to get Pontoon home in shell complete functions.

    Context can not be used because it is different that command context: see
    also https://github.com/pallets/click/issues/2303
    """
    return os.path.expanduser(os.environ.get("PONTOON_HOME", default))


def pick_host_prefix(ctrl: Controller, host_prefix: str) -> str:
    if host_prefix is not None:
        return host_prefix

    default_prefix = ctrl.default_host_prefix
    click.echo(f"Your new stack {ctrl.pontoon.name!r} needs a prefix for its VMs.")

    return click.prompt(
        "Please choose a prefix or accept the default.",
        type=str,
        default=default_prefix,
    )


# List commands in --help in the same order they are defined in code
# https://github.com/pallets/click/issues/513#issuecomment-504158316
class NaturalOrderGroup(click.Group):
    def list_commands(self, ctx):
        return self.commands.keys()


@click.group(cls=NaturalOrderGroup, context_settings=CLICK_CONTEXT_SETTINGS)
@click.option(
    "--home",
    type=str,
    metavar="PATH",
    default=lambda: pontoon_home(),
    help="Path to Pontoon stacks (env: PONTOON_HOME, default '.')",
)
@click.pass_context
def ctl(ctx, home):
    """Pontoon control tool"""
    ctx.ensure_object(dict)
    ctx.obj["home"] = os.path.expanduser(home)


@ctl.command()
@with_stack
@click.option(
    "--host-prefix",
    type=str,
    metavar="PREFIX",
    help="Hostnames will be generated starting with PREFIX",
)
@click.argument("name", required=False)
@click.pass_context
def new_stack(ctx, stack, host_prefix, name):
    """Create a new stack"""
    wanted_stack = stack or name
    if wanted_stack is None:
        wanted_stack = click.prompt("Please choose the stack name")

    home = ctx.obj["home"]
    if wanted_stack in Pontoon("bootstrap", home).available_stacks:
        raise click.UsageError(f"stack {wanted_stack!r} already exists in {home}")

    Pontoon.new(wanted_stack, home)

    ctrl = get_controller(wanted_stack, home)
    final_host_prefix = pick_host_prefix(ctrl, host_prefix)
    ok = ctrl.new_stack(final_host_prefix)
    if not ok:
        raise click.UsageError("Failed to create a new stack")
    print(INSTRUCTIONS["new-stack"].format(stack=wanted_stack))


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

    if not ctrl.server:
        raise click.UsageError(
            f"Server not found for {ctrl.pontoon.name}, unable to bootstrap"
        )

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
@click.pass_context
def list_stacks(ctx):
    """List stacks found in Pontoon home"""
    p = Pontoon("bootstrap", pontoon_home())
    print("\n".join(sorted(p.available_stacks)))


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
        if not hosts:
            log.warning("No host(s) found")
            return 1
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
    "--skip-enroll/--no-skip-enroll",
    default=False,
    help="Do not enroll the hosts after creation",
)
@click.pass_context
def create_hosts(ctx, stack, role, block, skip_enroll):
    """Create hosts for the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.create_hosts(role=role, skip_enroll=skip_enroll)
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
    # XXX wrap this method into controller
    # XXX make sure to delete ssh host keys too
    # XXX what should happen when removing puppetserver::pontoon ?
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
    """Wait for puppet run to converge on hosts"""
    ctrl = get_controller(stack, ctx.obj["home"])
    _, results = ctrl.wait_puppet(role)

    header = ("FQDN", "stdout", "stderr")
    data = []

    ok = True
    for result in sorted(results, key=lambda x: x.fqdn):
        if result.status != "success":
            ok = False
            data.append((result.fqdn, result.stdout[:50], result.stderr[:50]))

    if ok:
        log.info("Puppet runs completed")
    else:
        log.info("Puppet runs failed")
        print("\n".join(as_table(header, data)))

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
