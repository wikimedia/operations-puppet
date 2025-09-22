#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Automate large-scale helmfile deployments.

charlie.py recursively searches out helmfile services in a given repository or subtree, identifies
all the environments for each service, and diffs or applies them by shelling out to helmfile. It's
named after Charles Babbage because it's a labor-saving mechanized difference engine.
"""

import argparse
import itertools
import os
import shlex
import subprocess
import sys
import time
from fnmatch import fnmatch
from pathlib import Path
from typing import Optional

# TODO: This might become a command-line arg instead of a constant.
ROOT = Path('/srv/deployment-charts/helmfile.d/services')
DEFAULTS = Path('/etc/helmfile-defaults')
# Absolute paths, or paths relative to ROOT. Skip any helmfiles in these subtrees, regardless of the
# glob passed on the command line.
SKIP_DIRS = [Path('/srv/deployment-charts/helmfile.d/services/_example_')]
# Skip these environments, regardless of the glob passed on the command line.
SKIP_ENVS = ['traindev']


def main() -> int:
    parser = argparse.ArgumentParser(
        description="%(prog)s recursively searches out helmfile services in a given repository or "
                    "subtree, identifies all the environments for each service, and diffs or "
                    "applies them by shelling out to helmfile. It's named after Charles Babbage "
                    "because it's a labor-saving mechanized difference engine.")
    parser.add_argument('-s', '--service', default='*',
                        help='Glob for services to act on (e.g. mw-*).')
    parser.add_argument('-e', '--environment', default='*',
                        help='Glob for clusters to act on (e.g. staging*).')
    parser.add_argument('--dry_run', action='store_true',
                        help='Only run read-only helmfile commands.')
    parser.add_argument('--resume_at', metavar='SERVICE',
                        help='After interrupting a previous execution, pick up where you left off '
                             'by specifying the first service to act on. All services before '
                             'SERVICE alphabetically will be skipped.')
    # TODO: Make this a subcommand if we turn out to need the flexibility (e.g. different flags).
    parser.add_argument('action', choices=['list', 'diff', 'apply'], nargs='?', default='diff',
                        help='Action to take.')
    args = parser.parse_args()

    try:
        envs_by_helmfile = service_inventory(args.service, args.environment, args.resume_at)
    except Error as e:
        print(e)
        return 1
    if args.action == 'list':
        for helmfile, envs in envs_by_helmfile.items():
            service = helmfile.parent.relative_to(ROOT)
            print(f'{service}: {", ".join(envs)}')
        return 0
    elif args.action == 'diff':
        return multidiff(envs_by_helmfile)
    elif args.action == 'apply':
        return multiapply(envs_by_helmfile, dry_run=args.dry_run)
    else:
        # Unreachable, argparse enforces this.
        return 1


def service_inventory(service_glob: str, environment_glob: str,
                      resume_at: Optional[str]) -> dict[Path, list[str]]:
    """Search recursively under ROOT and return a mapping of helmfile paths to environments."""
    errors: list[str] = []
    result: dict[Path, list[str]] = {}
    for helmfile in sorted(ROOT.rglob('helmfile.yaml')):
        service = helmfile.parent.relative_to(ROOT)
        if resume_at is not None and str(service) < resume_at:
            continue
        if any((ROOT / skip) in helmfile.parents for skip in SKIP_DIRS):
            continue
        if not fnmatch(str(service), service_glob):
            continue
        try:
            envs = _environments(helmfile.read_text())
            envs = [env for env in envs
                    if env not in SKIP_ENVS and fnmatch(str(env), environment_glob)]
            # Place all the staging environments before all the non-staging ones.
            envs.sort(key=lambda i: 'staging' not in i)
            result[helmfile] = envs
        except Error:
            # Keep going, then raise once at the end for all the bad files.
            errors.append(str(service))
    if errors:
        them = 'them' if len(errors) > 1 else 'it'
        they = 'they' if len(errors) > 1 else 'it'
        raise Error(f"Couldn't parse environments from: {', '.join(errors)}. Add {them} to the "
                    f"SKIP global in {Path(__file__).name} if {they} should always be excluded.")
    if not result:
        if service_glob == '*':
            print('No services.')
        else:
            print(f'No service matched {service_glob}')
    return result


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


def multidiff(envs_by_helmfile: dict[Path, list[str]]) -> int:
    """Print helmfile diffs for each environment in each helmfile."""
    errors = []
    continue_prompt = False
    for helmfile, envs in envs_by_helmfile.items():
        service = helmfile.parent.relative_to(ROOT)
        for env in envs:
            # Put the prompt at the beginning of the loop instead of the end, and suppress it on the
            # first run, so that we don't prompt at the end right before exiting. It's the little
            # things.
            if sys.stdout.isatty() and continue_prompt:
                prompt(['next'], default='next')

            try:
                diffs = diff(helmfile, env)
            except Error:
                errors.append(f'{service} {env}')
                continue_prompt = True
                continue
            if diffs:
                for line in diffs.splitlines():
                    print(f'[{service} {env}] {line}')
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


def multiapply(envs_by_helmfile: dict[Path, list[str]], dry_run: bool) -> int:
    """Print helmfile diffs for each environment in each helmfile, then offer to apply.

    Why diff and then apply, instead of just running apply -i on everything? One reason is that
    apply -i logs to the SAL when it prints the diffs, which is a nuisance if you choose not to
    proceed. But we could turn that off with SUPPRESS_SAL if we wanted to. The better reason is that
    in the future we might summarize and coalesce the diffs here, so we'll want to print them in our
    own format instead of apply -i's.
    """
    for helmfile, envs in envs_by_helmfile.items():
        for env in envs:
            retry = True
            while retry:
                try:
                    retry = diff_and_apply(helmfile, env, dry_run)
                except UnretriableError as e:
                    print(e)
                    return 1
                except Error as e:
                    print(e)
                    retry = (prompt(['retry', 'skip']) == 'retry')
    return 0


def diff_and_apply(helmfile: Path, env: str, dry_run: bool) -> bool:
    service = helmfile.parent.relative_to(ROOT)
    start_time = time.time()
    diffs = diff(helmfile, env)
    if not diffs:
        print(f'[{service} {env}] No diffs.')
        return False
    for line in diffs.splitlines():
        print(f'[{service} {env}] {line}')
    if dry_run:
        print('Dry run. ', end='')
    if prompt(['apply', 'skip']) == 'skip':
        return False

    apply_command = 'apply --context 5'
    if files_modified_since(start_time):
        # In principle this kind of race condition is always possible, but we check for it here
        # specifically because we were just sitting at an interactive prompt. If the user was
        # distracted, we could have been waiting for minutes or days.
        print('Repo was modified since the diffs ran. Rechecking...')
        new_diffs = diff(helmfile, env)
        if new_diffs != diffs:
            print('WARNING: Diffs have changed! Review carefully before applying.')
            if prompt(['apply interactively', 'skip']) == 'skip':
                return False
            apply_command += ' -i'
        else:
            print(f'No changes that affect {service}, proceeding.')

    # capture is False here, so helmfile's output is directly on the terminal.
    # TODO: It'd be nice to prepend with [service env] like we do in the diff stage, but here we'll
    #  want to stream it instead of buffering it all until the process completes.
    process = _exec_helmfile(helmfile, env, apply_command, dry_run=dry_run)
    if process.returncode:
        print(f'helmfile exited with status {process.returncode}.')
        return prompt(['retry', 'next']) == 'retry'
    return False


def diff(helmfile: Path, env: str) -> Optional[str]:
    """Return the diffs for a single service in a single environment."""
    process = _exec_helmfile(
        helmfile, env, 'diff --color --detailed-exitcode --context 5', capture=True)
    if process.returncode == 0:
        # No diffs.
        return None
    if process.returncode == 2:
        # Exited successfully with diffs.
        return process.stdout
    # Real error.
    service = helmfile.parent.relative_to(ROOT)
    for line in process.stdout.splitlines():
        print(f'[{service} {env}] {line}')
    raise Error(f'Exit: {process.returncode}')


def _exec_helmfile(helmfile: Path, env: str, subcommand: str, capture: bool = False,
                   dry_run: bool = False) -> subprocess.CompletedProcess[str]:
    """Shell out to helmfile, returning the CompletedProcess."""
    cmd = ['/usr/bin/helmfile', '--file', str(helmfile), '--environment', env,
           *shlex.split(subcommand)]
    if dry_run:
        # Shell out to echo, instead of just printing cmd, because it means we can return a
        # CompletedProcess here consistently. In the dry run case, the return code is always 0.
        cmd = ['echo', 'Dry run. Would execute:', *cmd]
    if capture:
        return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    else:
        return subprocess.run(cmd, text=True)


def files_modified_since(start_time: float) -> bool:
    """Return True if, since the given timestamp, a file has changed that might alter the diffs.

    This produces plenty of false positives -- for example, it returns True if some Helm chart has
    been modified, even if it's not the chart for the service we're looking at. If it returns True,
    we'll just rerun `helmfile diff` and see if it's actually changed. This is much simpler than
    parsing the helmfile to work out what files it really depends on.

    False negatives should be rare, but are possible if the helmfile refers to a chart outside the
    repo, or a values file that's neither in the repo nor in DEFAULTS, or if ChartMuseum is delayed
    in updating the chart and finally does so at an inopportune time, etc.
    """
    # The repo root is ROOT or its nearest ancestor containing a .git directory.
    for parent in [ROOT, *ROOT.parents]:
        if parent.glob('.git/'):
            repo_root = parent
            break
    else:
        raise UnretriableError(f'{ROOT} is not in a git repository.')
    return _tree_modified_since(repo_root, start_time) or _tree_modified_since(DEFAULTS, start_time)


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
