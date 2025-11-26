#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# The pontoonctl CLI utility entry point


import logging
import sys
import os

import click
from pontoon import Pontoon, SYS_CONFIG_PATH
from pontoon.cloudvps import CloudVPS
from pontoon.controller import Controller
from pontoon.credentials import Credentials, CredentialsMissing
from pontoon.host import Filter as HostFilter
from pontoon.nova import HORIZON_URL, HOST_DOMAIN
from pontoon.ssh import KNOWN_HOSTS_PATH
from pontoon.util import as_table
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO

log = logging.getLogger()

CLICK_CONTEXT_SETTINGS = dict(help_option_names=["-h", "--help"])

INSTRUCTIONS = {
    "credentials-missing": """
Credentials not found. In order to get new credentials:
  * First log in into {horizon_url}
  * Then navigate to {horizon_url}/identity/application_credentials
  * From the top left dropdown, select the project for your Pontoon stack
  * Create a new application credential, 'name' is the only required field.
    for example '<username>-pontoon'.

The credential will need to be written to {credentials_path} in this form:

credentials:
  default:
    id: <CREDENTIAL-ID>
    secret: <CREDENTIAL-SECRET>

Note: {credentials_path} will need to be readable only by your user
""",
    "git-remote-setup": """
# Setup the Pontoon git remote for {stack} with the following commands:
git remote add pontoon-{stack} ssh://{server}/~/puppet.git

# If the Pontoon server has changed, update its url:
git remote set-url pontoon-{stack} ssh://{server}/~/puppet.git

# (optional) private.git can be set up as well:
git remote add pontoon-{stack}-private ssh://{server}/~/private.git
""",
    "stack-not-found": """

Unable to find stack {stack!r} in path {home!r}.
Make sure to run pontoonctl from a directory with Pontoon stacks, usually
<puppet.git checkout>/modules/pontoon/files.
To run pontoonctl from any directory set PONTOON_HOME to the location above.
""",
    "ssh-config": """
Below you'll find the ~/.ssh/config snippet to enable Pontoon integration
and host autocompletion.

# Place this configuration *before* your configuration for Cloud VPS (e.g. bastions)
Host *.{host_domain}
  UserKnownHostsFile {known_hosts}
""",
    "bootstrap-stack": """


Your new stack {stack!r} has been bootstrapped!

Make sure to run the commands above to set up git locally.


""",
    "new-stack": """
Stack {stack!r} has been created.

Make sure to commit the stack files before bootstrapping:

cd {home}
git checkout -b pontoon-{stack}
git add {stack}
git commit -m "pontoon: new stack {stack}" {stack}

Then proceed to bootstrap the stack:

pontoonctl bootstrap-stack --stack {stack}

NOTE: for convenience you can set the stack in the environment:

export PONTOON_STACK={stack}
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
    "create-hosts-wait-fail": """
Hosts can not be accessed. Make sure SSH access works, then enroll hosts with:

pontoonctl enroll-hosts
""",
}


def get_credentials() -> Credentials:
    credentials_path = SYS_CONFIG_PATH().joinpath("cloudvps.yaml").as_posix()
    try:
        creds = Credentials.load(credentials_path)
    except ValueError as e:
        raise click.UsageError(f"load credentials: {e}")
    except CredentialsMissing:
        raise click.UsageError(
            INSTRUCTIONS["credentials-missing"].format(
                credentials_path=credentials_path, horizon_url=HORIZON_URL
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
        metavar="NAME",
        shell_complete=complete_roles,
        help="Operate on hosts running NAME role.",
    )(func)
    return func


def with_scope(func):
    """Common decorator to add a --scope option to a command."""
    func = click.option(
        "--scope",
        default="stack",
        type=click.Choice(["stack", "project"]),
        help="Operate on hosts from this scope.",
        show_default=True,
    )(func)
    return func


def with_no_prompt(func):
    """Common decorator to add a --no-prompt option to a command."""
    func = click.option(
        "--no-prompt",
        is_flag=True,
        default=False,
        type=bool,
        help="Do not stop at prompts.",
        show_default=True,
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


def pontoon_home(default: str = ".") -> str:
    """
    Used to get Pontoon home in shell complete functions.

    Context can not be used because it is different that command context: see
    also https://github.com/pallets/click/issues/2303
    """
    return os.path.expanduser(os.environ.get("PONTOON_HOME", default))


def pick_host_prefix(ctrl: Controller, host_prefix: str) -> str:
    """Ask the user to pick a prefix for hostnames in the stack."""
    if host_prefix is not None:
        return host_prefix

    default_prefix = ctrl.default_host_prefix
    click.echo(f"Your new stack {ctrl.pontoon.name!r} needs a prefix for its VMs.")

    return click.prompt(
        "Please choose a prefix or accept the default.",
        type=str,
        default=default_prefix,
    )


def show_and_prompt(operation: str, f: HostFilter, no_prompt: bool) -> bool:
    if len(f) == 0:
        log.error(f"No hosts found to {operation}.")
        return False

    log.info(f"Hosts to {operation}:")
    for i in f:
        print(f"  {i.fqdn}")

    if no_prompt:
        return True

    count = len(f)
    answer = click.prompt(
        f"About to {operation} {count} host(s). Input the number to confirm",
        type=int,
    )

    if answer != count:
        log.info("Not doing anything")
        return False

    return True


class NaturalOrderGroup(click.Group):
    """
    List commands in --help in the same order they are defined in code
    https://github.com/pallets/click/issues/513#issuecomment-504158316
    """

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
    help="Hostnames will be generated starting with PREFIX.",
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

    p = Pontoon.new(wanted_stack, home)

    try:
        ctrl = get_controller(wanted_stack, home)
        chosen_host_prefix = pick_host_prefix(ctrl, host_prefix)
        ok = ctrl.new_stack(chosen_host_prefix)
        if not ok:
            raise click.UsageError("Failed to create a new stack")
    except Exception:
        # Make sure the stack is deleted so pontoonctl new-stack can be run again
        p.delete()
        raise

    print(
        INSTRUCTIONS["new-stack"].format(stack=wanted_stack, cwd=os.getcwd(), home=home)
    )


@ctl.command()
@with_stack
@click.option(
    "--local-rev",
    help="Use git revision ID during bootstrap.",
    show_default=True,
    default="HEAD",
    metavar="ID",
    type=str,
)
@click.option(
    "--accept-ssh-key",
    help="Trust the SSH host key from Puppet server.",
    default=False,
    is_flag=True,
)
@click.pass_context
def bootstrap_stack(ctx, stack, local_rev, accept_ssh_key):
    """Bootstrap a newly-created stack"""
    ctrl = get_controller(stack, ctx.obj["home"])

    if not ctrl.server:
        raise click.UsageError(
            f"Server not found for {ctrl.pontoon.name}, unable to bootstrap"
        )

    ok = ctrl.bootstrap_stack(local_rev, accept_ssh_key)
    if not ok:
        log.error("Error bootstrapping")
        sys.exit(1)

    ok = ctrl.setup_remote_repositories()
    if not ok:
        log.error("Error setting up remote repositories")
        sys.exit(1)

    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=ctrl.server))
    print(INSTRUCTIONS["bootstrap-stack"].format(stack=stack))


@ctl.command()
@with_stack
@click.option(
    "--accept-ssh-key",
    help="Trust the SSH host key from Puppet server.",
    default=False,
    is_flag=True,
)
@click.pass_context
def join_stack(ctx, stack, accept_ssh_key):
    """Configure the stack to be available for local development"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ok = ctrl.join_stack(accept_ssh_key)
    if not ok:
        log.error(f"Error joining stack {stack}")
        sys.exit(1)
    print(INSTRUCTIONS["git-remote-setup"].format(stack=stack, server=ctrl.server))


@ctl.command()
@click.pass_context
def list_stacks(ctx):
    """List stacks found in Pontoon home"""
    p = Pontoon("bootstrap", pontoon_home())
    print("\n".join(sorted(p.available_stacks)))


@ctl.command()
@with_stack
@with_role
@with_scope
@click.option(
    "--output",
    default="table",
    type=click.Choice(["fqdn", "table"]),
    help="Output format. 'fqdn' is suitable for scripting.",
    show_default=True,
)
@click.argument("pattern", required=False)
@click.pass_context
def list_hosts(ctx, stack, role, scope, output, pattern):
    """Show cloud hosts belonging to the stack, or the whole project"""
    # don't require stack when listing project hosts
    if stack is None and scope == "project":
        stack = "bootstrap"

    if scope == "project" and role:
        raise click.UsageError("--role can be used only in stack scope")

    ctrl = get_controller(stack, ctx.obj["home"])

    hosts = HostFilter(ctrl.cloud.list_hosts())

    # First filter by scope, keeping only hosts in the stack
    if scope == "stack":
        stack_fqdns = {h.fqdn for h in ctrl.stack_hosts}
        hosts = hosts.apply(lambda host: host.fqdn in stack_fqdns)

    # Apply role/pattern filter (with AND logic)
    if role:
        hosts = hosts.apply(HostFilter.by_role(role))

    if pattern:
        hosts = hosts.apply(HostFilter.by_fqdn(pattern))

    hosts = sorted(hosts, key=lambda h: h.fqdn)

    if output == "fqdn":
        if not hosts:
            sys.exit(1)
        print("\n".join([h.fqdn for h in hosts]))
    elif output == "table":
        if not hosts:
            log.warning("No host(s) found")
            sys.exit(1)
        header = ("FQDN", "Image", "Flavor")
        data = []
        for h in hosts:
            data.append((h.fqdn, h.image, h.flavor))
        if scope == "stack":
            log.info("Hosts for project %r and stack %r:" % (ctrl.cloud.project, stack))
        else:
            log.info("Hosts for project %r:" % (ctrl.cloud.project))
        print("\n".join(as_table(header, data)))


@ctl.command()
@with_stack
@with_role
@with_no_prompt
@click.option(
    "--skip-enroll/--no-skip-enroll",
    default=False,
    help="Do not enroll the hosts after creation.",
)
@click.pass_context
def create_hosts(ctx, stack, role, no_prompt, skip_enroll):
    """Create hosts for the stack"""
    ctrl = get_controller(stack, ctx.obj["home"])

    f = HostFilter(ctrl.stack_hosts)
    if role is not None:
        f = f.apply(f.by_role(role))
    f = f.apply(f.not_(ctrl.cloud.all_hosts_filter))

    ok = show_and_prompt("create", f, no_prompt)
    if not ok:
        sys.exit(1)

    ok = ctrl.create_hosts(f, skip_enroll, no_prompt)
    if not ok:
        if not skip_enroll:
            print(INSTRUCTIONS["create-hosts-wait-fail"])
        sys.exit(1)


@ctl.command()
@with_stack
@with_role
@click.option(
    "--force",
    is_flag=True,
    default=False,
    help="Force re-enrollment.",
)
@click.pass_context
def enroll_hosts(ctx, stack, role, force):
    """Enroll hosts for the stack"""
    # XXX handle failure, print instructions
    ctrl = get_controller(stack, ctx.obj["home"])
    f = HostFilter(ctrl.stack_hosts)
    if role is not None:
        f = f.apply(f.by_role(role))
    ok = ctrl.enroll_hosts(f, force)
    if not ok:
        sys.exit(1)


@ctl.command()
@with_stack
@with_role
@with_scope
@with_no_prompt
@click.argument("pattern", required=False)
@click.pass_context
def destroy_hosts(ctx, stack, role, scope, no_prompt, pattern):
    """Destroy hosts matching a pattern or role"""
    if scope != "stack":
        stack = "bootstrap"
    ctrl = get_controller(stack, ctx.obj["home"])
    if not (pattern or role):
        raise click.UsageError("Specify a pattern or --role to destroy hosts")

    if scope != "stack" and role:
        raise click.UsageError("--role can be used only in scope 'stack'")

    f = HostFilter(ctrl.cloud_hosts(scope))
    f = f.apply(f.any(f.by_role(role), f.by_fqdn(pattern)))
    # XXX wait for destruction?
    ok = show_and_prompt("destroy", f, no_prompt)
    if not ok:
        sys.exit(1)

    ok = ctrl.destroy_hosts(f)
    if not ok:
        sys.exit(1)


@ctl.command()
@with_stack
@with_role
@with_scope
@with_no_prompt
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
def reboot_hosts(ctx, stack, role, scope, no_prompt, pattern, type, block):
    """Reboot hosts matching a pattern or role"""
    if scope != "stack":
        stack = "bootstrap"
    ctrl = get_controller(stack, ctx.obj["home"])
    if not (pattern or role):
        raise click.UsageError("Specify a pattern or --role to reboot hosts")
    if scope != "stack" and role:
        raise click.UsageError("--role can be used only in scope 'stack'")

    f = HostFilter(ctrl.cloud_hosts(scope))

    f = f.apply(f.any(f.by_role(role), f.by_fqdn(pattern)))

    ok = show_and_prompt("reboot", f, no_prompt)
    if not ok:
        sys.exit(1)

    ok = ctrl.reboot_hosts(f, type, block)
    if not ok:
        sys.exit(1)


@ctl.command()
@with_stack
@with_role
@click.pass_context
def wait_puppet(ctx, stack, role):
    """Wait for puppet run to converge on hosts"""
    ctrl = get_controller(stack, ctx.obj["home"])

    f = HostFilter(ctrl.cloud_hosts("stack"))
    if role is not None:
        f = f.apply(f.by_role(role))
    if len(f) == 0:
        log.error("No hosts selected.")
        sys.exit(1)

    # XXX use click progress bar
    # XXX be able to tweak the timeout
    _, results = ctrl.wait_puppet(f)

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

    if not ok:
        sys.exit(1)


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
            host_domain=HOST_DOMAIN,
            known_hosts=KNOWN_HOSTS_PATH(),
        )
    )


@ctl.command()
@with_stack
@click.option(
    "--accept-ssh-key",
    help="Automatically accept the SSH host key from Puppet server.",
    default=False,
    is_flag=True,
)
@click.pass_context
def ssh_keyscan(ctx, stack, accept_ssh_key):
    """Update Pontoon's known_hosts file with the stack' SSH fingerprints"""
    ctrl = get_controller(stack, ctx.obj["home"])
    ctrl.update_ssh_fingerprints(accept_ssh_key)


@ctl.command()
@with_stack
@click.argument("role", shell_complete=complete_roles)
@click.pass_context
def hosts_for_role(ctx, stack, role):
    """Print stack hosts for the given role"""
    ctrl = get_controller(stack, ctx.obj["home"])
    try:
        hosts = ctrl.pontoon.hosts_for_role(role)
    except ValueError:
        raise click.UsageError(f"Role {role!r} not found in stack {stack!r}")

    print("\n".join(hosts))


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
    for h in log.handlers:
        h.setFormatter(fmt)

    return ctl.main()
