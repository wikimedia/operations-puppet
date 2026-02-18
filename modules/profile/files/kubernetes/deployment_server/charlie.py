#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Automate large-scale helmfile deployments.

charlie.py recursively searches out helmfile services in a given repository or subtree, identifies
all the environments for each service, and diffs or applies them by shelling out to helmfile. It's
named after Charles Babbage because it's a labor-saving mechanized difference engine.
"""

import argparse
import itertools
import json
import os
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass
from fnmatch import fnmatch
from pathlib import Path
from typing import Optional

from kubernetes import client, config

HELMFILE_ROOT = Path('/srv/deployment-charts/helmfile.d')
DEFAULTS = Path('/etc/helmfile-defaults')
# Paths relative to the root of the deployment-charts repo. Skip any helmfiles in these subtrees,
# regardless of the glob passed on the command line.
SKIP_DIRS = [Path('helmfile.d/services/_example_')]
# Skip these environments, regardless of the glob passed on the command line.
SKIP_ENVS = ['traindev']


@dataclass
class Service:
    helmfile: Path
    environments: list[str]
    name: str

    def __str__(self) -> str:
        return self.name


@dataclass
class ServiceInventory:
    services: list[Service]
    services_dir: Path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="%(prog)s recursively searches out helmfile services in a given repository or "
                    "subtree, identifies all the environments for each service, and diffs or "
                    "applies them by shelling out to helmfile. It's named after Charles Babbage "
                    "because it's a labor-saving mechanized difference engine.")
    parser.add_argument('--services_dir', default='services/', type=parse_services_dir,
                        help=f'Directory (absolute, or relative to {HELMFILE_ROOT}) to search for '
                             f'helmfile services. Default: services/')
    parser.add_argument('-s', '--service', default='*',
                        help='Glob for services to act on (e.g. mw-*).')
    parser.add_argument('-e', '--environment', default='*',
                        help='Glob for clusters to act on (e.g. staging*).')
    parser.add_argument('--priority', metavar='SERVICE,SERVICE,...', default=[],
                        help='Act on these services before any others.',
                        type=lambda arg: arg.split(','))
    parser.add_argument('--resume_at', metavar='SERVICE',
                        help='After interrupting a previous execution, pick up where you left off '
                             'by specifying the first service to act on. All services before '
                             'SERVICE in order will be skipped.')
    subparsers = parser.add_subparsers(
        dest='action',
        help='Subcommand to run. (Default: diff)  Run "%(prog)s SUBCOMMAND --help" for more '
             'options.')
    subparsers.add_parser('list')
    subparsers.add_parser('diff')
    apply = subparsers.add_parser('apply')
    parser.add_argument('--dry_run', action='store_true',
                        help='Only run read-only helmfile commands.')
    apply.add_argument('--dangerously_fast', action='store_true',
                       help="Deploy everything without stopping. Don't print diffs and don't ask "
                            "for confirmation. For serviceops use only, to repopulate the cluster "
                            "after wiping it.")
    args = parser.parse_args()

    try:
        inventory = service_inventory(
            args.services_dir, args.service, args.environment, args.priority, args.resume_at)
    except Error as e:
        print(e)
        return 1
    if args.action == 'list':
        for service in inventory.services:
            print(f'{service}: {", ".join(service.environments)}')
        return 0
    elif args.action == 'diff' or args.action is None:  # Default action.
        return multidiff(inventory)
    elif args.action == 'apply':
        if args.dangerously_fast:
            return fast_multiapply(inventory, dry_run=args.dry_run)
        else:
            return multiapply(inventory, dry_run=args.dry_run)
    else:
        # Unreachable, argparse enforces this.
        return 1


def parse_services_dir(services_dir: str) -> Path:
    # Join HELMFILE_ROOT with --services_dir. This intentionally allows running charlie from outside
    # HELMFILE_ROOT (say, from a checkout of deployment-charts in the user's homedir) if given an
    # absolute path for --services_dir. Specifically:
    # - A relative path (--services_dir=foo) is treated as HELMFILE_ROOT/foo.
    # - An absolute path (--services_dir=/home/foo/deployment-charts) is treated as itself.
    # - A path with an explicit "." at the beginning (--services_dir=./foo) is treated as equivalent
    #   to $PWD/foo and thus *absolute*. That semantics is slightly magic in a nonstandard way, but
    #   the end result is intuitively familiar from use cases like $PATH.
    if services_dir == '.' or services_dir.startswith('./'):
        # Special-case this, because otherwise with "--services_dir=." we would join it to
        # HELMFILE_ROOT and get "/srv/deployment-charts/helmfile.d/.", which isn't the intent.)
        result = Path(services_dir).absolute()
    else:
        result = HELMFILE_ROOT / services_dir
    if not result.is_dir():  # This includes if the path doesn't exist.
        raise argparse.ArgumentTypeError(f'{result} is not a directory.')
    return result


def service_inventory(services_dir: Path, service_glob: str, environment_glob: str,
                      priority_services: list[str], resume_at: Optional[str]) -> ServiceInventory:
    """Search recursively under services_dir and return all helmfile paths and environments."""
    errors: list[str] = []
    services: dict[str, Service] = {}
    repo_root = _repo_root(services_dir)
    for helmfile in sorted(services_dir.rglob('helmfile.yaml')):
        service_name = str(helmfile.parent.relative_to(services_dir))
        if any((repo_root / skip) in helmfile.parents for skip in SKIP_DIRS):
            continue
        if not fnmatch(service_name, service_glob):
            continue
        try:
            envs = _environments(helmfile.read_text())
            envs = [env for env in envs
                    if env not in SKIP_ENVS and fnmatch(str(env), environment_glob)]
            if not envs:
                continue
            # Place all the staging environments before all the non-staging ones.
            envs.sort(key=lambda i: 'staging' not in i)
            services[service_name] = Service(helmfile, envs, service_name)
        except Error:
            # Keep going, then raise once at the end for all the bad files.
            errors.append(service_name)
    if errors:
        them = 'them' if len(errors) > 1 else 'it'
        they = 'they' if len(errors) > 1 else 'it'
        raise Error(f"Couldn't parse environments from: {', '.join(errors)}. Add {them} to the "
                    f"SKIP global in {Path(__file__).name} if {they} should always be excluded.")
    if not services:
        if service_glob != '*' and environment_glob != '*':
            print(f'No service matched "{service_glob}" in environment matching '
                  f'"{environment_glob}".')
        elif service_glob != '*':
            print(f'No service matched "{service_glob}".')
        elif environment_glob != '*':
            print(f'No services in environment matching "{environment_glob}".')
        else:
            print('No services.')
        return ServiceInventory([], services_dir)
    # Return any --priority services in priority order, then all the rest in alphabetical order (as
    # they were inserted into the dict).
    try:
        result = [services.pop(name) for name in priority_services]
    except KeyError as e:
        name = e.args[0]
        raise Error(f'--priority service {name} not found. Use "charlie list" to list all '
                    f'services.') from None
    result.extend(services.values())
    # Now that we have the final order, cut off everything before --resume_at (if there is one).
    if resume_at is not None:
        result = list(itertools.dropwhile(lambda service: service.name != resume_at, result))
        if not result:
            raise Error(f'--resume_at service "{resume_at}" not found. Use "charlie list" to list '
                        f'all services.')
    return ServiceInventory(result, services_dir)


def _environments(helmfile_body: str) -> list[str]:
    """Read the body of a helmfile and return the names of its environments.

    If we squint, the helmfile is just YAML, and really all we want is
        yaml.safe_load(helmfile_body)["environments"].keys()

    But because a helmfile is a YAML *template*, it won't actually parse as YAML, so we have to do
    the parsing ourselves.
    """
    # Remove comments and trailing whitespace from each line. (This isn't foolproof: the line
    #   key: "string # with # hashes"  # comment
    # is valid YAML, and this split() would do the wrong thing. But it's sufficient for our limited
    # application.) Then remove blank lines, and whitespace-only lines (which are now blank).
    lines = [stripped_line for line in helmfile_body.splitlines()
             if (stripped_line := line.split('#')[0].rstrip())]
    # Skip until the line "environments:", then skip that line.
    try:
        lines = lines[lines.index('environments:') + 1:]
    except ValueError:
        # No environments in this helmfile.
        return []

    # The next line is the first key in the environments map. Keep track of its indentation. All
    # the other keys are the lines indented exactly the same.
    indent = ''.join(itertools.takewhile(str.isspace, lines[0]))
    result = []
    for line in lines:
        if not line.startswith(indent):
            # We've exited the environments: block, so we're done.
            break
        if line[len(indent) + 1].isspace():
            # We're more deeply indented, e.g. inside the eqiad: block.
            continue
        if '{{' in line:
            # The environment name is templated?? Bail out.
            raise Error
        # This also does the right thing with e.g. "eqiad: &anchor" and "codfw: *anchor".
        result.append(line.split(':')[0].strip())
    return result


def multidiff(inventory: ServiceInventory) -> int:
    """Print helmfile diffs for each environment in each helmfile."""
    errors = []
    continue_prompt = False
    for service in inventory.services:
        for env in service.environments:
            # Put the prompt at the beginning of the loop instead of the end, and suppress it on the
            # first run, so that we don't prompt at the end right before exiting. It's the little
            # things.
            if sys.stdout.isatty() and continue_prompt:
                prompt(['next'], default='next')

            try:
                diffs = diff(service, env)
            except Error:
                errors.append(f'{service} {env}')
                continue_prompt = True
                continue
            if diffs:
                print(diffs)
                continue_prompt = True
            else:
                print(f'[{service} {env}] No diffs.')
                continue_prompt = False
    if errors:
        them = 'them' if len(errors) > 1 else 'it'
        they = 'they' if len(errors) > 1 else 'it'
        print(f"Diff errors from: {', '.join(errors)}. Add {them} to the SKIP global in "
              f"{Path(__file__).name} if {they} should always be excluded.")
        return 1
    return 0


def multiapply(inventory: ServiceInventory, dry_run: bool) -> int:
    """Print helmfile diffs for each environment in each helmfile, then offer to apply.

    Why diff and then apply, instead of just running apply -i on everything? One reason is that
    apply -i logs to the SAL when it prints the diffs, which is a nuisance if you choose not to
    proceed. But we could turn that off with SUPPRESS_SAL if we wanted to. The better reason is that
    in the future we might summarize and coalesce the diffs here, so we'll want to print them in our
    own format instead of apply -i's.
    """
    for service in inventory.services:
        for env in service.environments:
            retry = True
            while retry:
                try:
                    retry = diff_and_apply(inventory.services_dir, service, env, dry_run)
                except UnretriableError as e:
                    print(e)
                    return 1
                except Error as e:
                    print(e)
                    retry = (prompt(['retry', 'skip']) == 'retry')
    return 0


def fast_multiapply(inventory: ServiceInventory, dry_run: bool) -> int:
    """Rapidly initialize an empty cluster."""
    if not inventory.services:
        return 0
    all_envs = {env for service in inventory.services for env in service.environments}
    if len(all_envs) != 1:
        # It's otherwise allowed to be a glob, and it's "*" by default.
        print('--dangerously_fast requires a single environment name, like "-e codfw".')
        return 1
    [env] = all_envs
    try:
        if not _cluster_is_wiped(inventory):
            # _cluster_is_wiped already printed more details about what objects exist.
            print(f"Cluster {env} is not wiped, can't use --dangerously_fast.")
            return 1
    except Error as e:
        print(e)
        return 1

    print('--dangerously_fast is meant to run on an empty cluster, e.g. right after running')
    print('sre.k8s.wipe-cluster. It may harm any services already running in the cluster.')
    print()
    print('* It will run "helmfile apply" on each service.')
    print('* It will NOT print the diffs.')
    print('* It will NOT stop between services to ask for approval.')
    print('* Any outstanding diffs will be immediately deployed without confirmation.')
    print('* If anything goes wrong, it will print the output and pause.')
    print()
    print('Is that what you want?')
    prompt(['begin'])

    for service in inventory.services:
        retry = True
        while retry:
            print(f'[{service} {env}] Applying...')
            # Pass --context 5, but suppress the output by default. We'll print it if there was a
            # problem, and in that case we want the diffs to be concise if possible. (But typically
            # it'll all be objects that didn't exist, so they'll get printed in full anyway.)
            returncode, output = _exec_helmfile(
                service, env, "apply --context 5", print_output=False, dry_run=dry_run)
            if returncode:
                print(output)
                print(f'helmfile exited with status {returncode}.')
                retry = (prompt(['retry', 'next']) == 'retry')
            else:
                print(f'[{service} {env}] Done.')
                retry = False
    return 0


def diff_and_apply(services_dir: Path, service: Service, env: str, dry_run: bool) -> bool:
    start_time = time.time()
    diffs = diff(service, env)
    if not diffs:
        print(f'[{service} {env}] No diffs.')
        return False
    print(diffs)
    if dry_run:
        print('Dry run. ', end='')
    if prompt(['apply', 'skip']) == 'skip':
        return False

    apply_command = 'apply --context 5'
    if files_modified_since(services_dir, start_time):
        # In principle this kind of race condition is always possible, but we check for it here
        # specifically because we were just sitting at an interactive prompt. If the user was
        # distracted, we could have been waiting for minutes or days.
        print('Repo was modified since the diffs ran. Rechecking...')
        new_diffs = diff(service, env)
        if new_diffs != diffs:
            print('WARNING: Diffs have changed! Review carefully before applying.')
            if prompt(['apply interactively', 'skip']) == 'skip':
                return False
            apply_command += ' -i'
        else:
            print(f'No changes that affect {service}, proceeding.')

    returncode, _ = _exec_helmfile(service, env, apply_command, print_output=True, dry_run=dry_run)
    if returncode:
        print(f'helmfile exited with status {returncode}.')
        return prompt(['retry', 'next']) == 'retry'
    return False


def diff(service: Service, env: str) -> Optional[str]:
    """Return the diffs for a single service in a single environment."""
    returncode, output = _exec_helmfile(
        service, env, 'diff --color --detailed-exitcode --context 5', print_output=False)
    if returncode == 0:
        # No diffs.
        return None
    if returncode == 2:
        # Exited successfully with diffs.
        return output
    # Real error.
    print(output)
    raise Error(f'Exit: {returncode}')


def _exec_helmfile(service: Service, env: str, subcommand: str, print_output: bool,
                   dry_run: bool = False) -> tuple[int, str]:
    """Shell out to helmfile, returning the exit status and stdout prefixed with [service env]."""
    cmd = ['/usr/bin/helmfile', '--file', str(service.helmfile), '--environment', env]
    if dry_run:
        print(f'Dry run. Would execute: {shlex.join(cmd)} {subcommand}')
        return 0, ''
    cmd.extend(shlex.split(subcommand))

    prefix = f'[{service} {env}] '
    output = ''
    # Read from the child process's stdout/stderr unbuffered, a character (not byte) at a time. Then
    # we can detect newlines and insert the prefix at the start of the next line. We have to do it
    # this way (rather than just line buffering) because helmfile is sometimes interactive, and the
    # prompts ("Apply? [y/n] ") don't have a trailing newline, so they'd sit in the buffer.
    with subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=0) as p:
        start_of_line = True
        while (char := p.stdout.read(1)) != '':
            text = (prefix + char) if start_of_line else char
            output += text
            if print_output:
                print(text, end='', flush=True)
            start_of_line = (char == '\n')
        returncode = p.wait()  # p.stdout has EOFed, so this should be quick.
    return returncode, output


def files_modified_since(services_dir: Path, start_time: float) -> bool:
    """Return True if, since the given timestamp, a file has changed that might alter the diffs.

    This produces plenty of false positives -- for example, it returns True if some Helm chart has
    been modified, even if it's not the chart for the service we're looking at. If it returns True,
    we'll just rerun `helmfile diff` and see if it's actually changed. This is much simpler than
    parsing the helmfile to work out what files it really depends on.

    False negatives should be rare, but are possible if the helmfile refers to a chart outside the
    repo, or a values file that's neither in the repo nor in DEFAULTS, or if ChartMuseum is delayed
    in updating the chart and finally does so at an inopportune time, etc.
    """
    return (_tree_modified_since(_repo_root(services_dir), start_time)
            or _tree_modified_since(DEFAULTS, start_time))


def _repo_root(services_dir: Path) -> Path:
    # The repo root is services_dir or its nearest ancestor containing a .git directory.
    for parent in [services_dir, *services_dir.parents]:
        if list(parent.glob('.git/')):
            return parent
    else:
        raise UnretriableError(f'{services_dir} is not in a git repository.')


def _tree_modified_since(tree: Path, start_time: float) -> bool:
    # We don't care if files under .git changed, and there's a lot of them, so use os.walk to skip
    # it. We would use Path.walk instead, but it's only available as of Trixie.
    for root, dirs, files in os.walk(tree):
        root_path = Path(root)
        if any((root_path / file).stat().st_mtime > start_time for file in files):
            return True
        if '.git' in dirs:
            dirs.remove('.git')
    return False


def _cluster_is_wiped(inventory: ServiceInventory) -> bool:
    """Return True if the only pods in the cluster are in the system namespaces."""
    system_namespaces = {'cert-manager', 'default', 'istio-system', 'kube-node-lease',
                         'kube-public', 'kube-system'}
    # By now we know all the services have just one environment and it's the same one.
    [env] = inventory.services[0].environments
    # Any one of their Kubernetes configs has the "all namespaces" read access we need, so just grab
    # the first one. We need its namespace to find its Kube config (it might be, but isn't always,
    # the same name as the service directory). We can't read the namespace directly out of
    # helmfile.yaml, becaues it's templated in, but we can run "helmfile list" to find it. (We don't
    # use _exec_helmfile() because we don't want the "[service env]" prefix on the JSON output.)
    cmd = ['/usr/bin/helmfile', '--file', str(inventory.services[0].helmfile), '--environment', env,
           'list', '--output', 'json']
    try:
        process = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=True)
    except subprocess.CalledProcessError as e:
        print(e.stdout)
        raise UnretriableError(f'helmfile list --output=json exited with status {e.returncode}.')
    releases = json.loads(process.stdout)
    namespace = releases[0]['namespace']  # Any of the releases should work.

    config.load_kube_config(config_file=f'/etc/kubernetes/{namespace}-{env}.config')
    pods = client.CoreV1Api().list_pod_for_all_namespaces().items
    found_namespaces = set(pod.metadata.namespace for pod in pods)
    found_namespaces.difference_update(system_namespaces)
    if found_namespaces:
        namespaces = 'namespaces' if len(found_namespaces) > 1 else 'namespace'
        print(f'Found pods in {namespaces}: {", ".join(sorted(found_namespaces))}')
        return False
    else:
        return True


def prompt(options: list[str], default: Optional[str] = None) -> str:
    options = [*options, 'quit']  # Append without mutating the input.
    if len({option[0].upper() for option in options}) < len(options):
        raise ValueError(f'Prompt options must have unique first letters: {options}')
    # Yes, we're building a string with plus signs in the 21st century, but the equivalent f-string
    # is just so dense as to be unreadable.
    text = ', '.join('(' + option[0].upper() + ')' + option[1:] for option in options) + '? '
    if default:
        text += f'[{default[0]}] '

    while True:
        try:
            answer = input(text)
        except (KeyboardInterrupt, EOFError):
            print()
            sys.exit(0)
        if not answer and default is not None:
            answer = default
        answer = answer[:1].lower()
        for option in options:
            if answer == option[0]:
                if option == 'quit':
                    sys.exit(0)
                return option


class Error(BaseException):
    pass


class UnretriableError(BaseException):
    pass


if __name__ == '__main__':
    sys.exit(main())
