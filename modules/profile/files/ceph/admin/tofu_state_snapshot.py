#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Take a snapshot of each OpenTofu state file that changed since its newest snapshot.

The script reads <resources dir>/<module>/terraform.tfstate for each root module. When the
content differs from the newest snapshot of the module, it writes the content to
<snapshot dir>/<module>/<UTC time>-serial-<serial>.tfstate. It never removes a snapshot.

The script only reads the state files. It does not take the OpenTofu lock.
"""

import argparse
import hashlib
import json
import logging
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Tuple

DEFAULT_RESOURCES_DIR = Path('/srv/tofu-infra/resources')
DEFAULT_STAGING_DIR = Path('/srv/tofu-state-snapshots/.staging')
STATE_FILE_NAME = 'terraform.tfstate'
SNAPSHOT_NAME = re.compile(r'^\d{8}T\d{6}Z-serial-\d+\.tfstate$')

log = logging.getLogger('tofu-state-snapshot')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        '--snapshot-dir',
        type=Path,
        required=True,
        help='the directory for the snapshots of this site, e.g. /srv/tofu-state-snapshots/eqiad',
    )
    parser.add_argument(
        '--resources-dir',
        type=Path,
        default=DEFAULT_RESOURCES_DIR,
        help=f'the directory of the OpenTofu root modules (default: {DEFAULT_RESOURCES_DIR})',
    )
    parser.add_argument(
        '--staging-dir',
        type=Path,
        default=DEFAULT_STAGING_DIR,
        help=('a directory on the same filesystem as the snapshot directory, '
              f'for snapshots that are not complete (default: {DEFAULT_STAGING_DIR})'),
    )
    parser.add_argument('--debug', action='store_true', help='also log the unchanged files')
    return parser.parse_args()


def is_complete_state(state: object) -> bool:
    """Return True if the parsed JSON has the fields of a complete OpenTofu state."""
    if not isinstance(state, dict):
        return False
    # A bool is also an int, so compare the types exactly.
    return (
        type(state.get('version')) is int
        and type(state.get('serial')) is int
        and isinstance(state.get('lineage'), str)
        and state['lineage'] != ''
    )


def read_state(path: Path) -> Optional[Tuple[bytes, dict]]:
    """Return the content and the parsed JSON of a complete state file.

    Return None if the file is empty, changes during the read or is not a complete state.
    OpenTofu writes the file in place, so a copy from the middle of a write is not complete.
    """
    try:
        with path.open('rb') as state_file:
            before = os.fstat(state_file.fileno())
            content = state_file.read()
        after = path.stat()
    except FileNotFoundError:
        log.info('%s no longer exists, skipping it', path)
        return None

    if (before.st_ino, before.st_size, before.st_mtime_ns) != (
        after.st_ino,
        after.st_size,
        after.st_mtime_ns,
    ) or len(content) != after.st_size:
        log.warning('%s changed during the read, skipping it', path)
        return None
    if not content:
        log.info('%s is empty, skipping it', path)
        return None

    try:
        state = json.loads(content)
    except ValueError:
        log.warning('%s is not valid JSON, skipping it', path)
        return None
    if not is_complete_state(state):
        log.warning('%s is not a complete OpenTofu state, skipping it', path)
        return None
    return content, state


def newest_snapshot(module_dir: Path) -> Optional[Path]:
    """Return the newest snapshot in a module directory, or None if there is no snapshot.

    The names start with the UTC time in a fixed format, so the last name is the newest.
    """
    if not module_dir.is_dir():
        return None
    names = sorted(entry.name for entry in module_dir.iterdir() if SNAPSHOT_NAME.match(entry.name))
    if not names:
        return None
    return module_dir / names[-1]


def check_history(state_path: Path, state: dict, newest: Path, newest_content: bytes) -> None:
    """Log a warning if the state does not follow on from the newest snapshot."""
    try:
        previous = json.loads(newest_content)
    except ValueError:
        log.warning('%s is not valid JSON', newest)
        return
    if not is_complete_state(previous):
        log.warning('%s is not a complete OpenTofu state', newest)
        return

    if state['lineage'] != previous['lineage']:
        log.warning(
            '%s has lineage %s, but the newest snapshot %s has lineage %s. '
            'Something replaced the state.',
            state_path, state['lineage'], newest, previous['lineage'],
        )
    elif state['serial'] < previous['serial']:
        log.warning(
            '%s has serial %d, which is lower than serial %d in the newest snapshot %s. '
            'Something rolled back or replaced the state.',
            state_path, state['serial'], previous['serial'], newest,
        )


def write_staged_file(path: Path, content: bytes) -> None:
    """Write the content to a new file and flush it to the disk."""
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, 'wb') as staged_file:
            staged_file.write(content)
            staged_file.flush()
            os.fsync(staged_file.fileno())
    except BaseException:
        path.unlink(missing_ok=True)
        raise


def fsync_dir(path: Path) -> None:
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def snapshot_state(state_path: Path, snapshot_dir: Path, staging_dir: Path, now: datetime) -> None:
    """Take a snapshot of one state file if it changed since the newest snapshot."""
    result = read_state(state_path)
    if result is None:
        return
    content, state = result
    digest = hashlib.sha256(content).hexdigest()

    module = state_path.parent.name
    module_dir = snapshot_dir / module
    newest = newest_snapshot(module_dir)
    if newest is not None:
        newest_content = newest.read_bytes()
        if hashlib.sha256(newest_content).hexdigest() == digest:
            log.debug('%s did not change since %s', state_path, newest)
            return
        check_history(state_path, state, newest, newest_content)

    module_dir.mkdir(mode=0o700, exist_ok=True)
    name = f'{now:%Y%m%dT%H%M%SZ}-serial-{state["serial"]}.tfstate'
    staged = staging_dir / f'{module}.{name}'
    write_staged_file(staged, content)
    try:
        # A hard link makes the complete file visible in one step, and it never replaces a file.
        os.link(staged, module_dir / name)
    finally:
        staged.unlink()
    fsync_dir(module_dir)
    log.info('saved %s as %s (sha256 %s)', state_path, module_dir / name, digest)


def clear_staging_dir(staging_dir: Path) -> None:
    """Create the staging directory, or remove the files that an earlier run left in it."""
    staging_dir.mkdir(mode=0o700, exist_ok=True)
    for leftover in staging_dir.iterdir():
        log.warning('removing %s, which an earlier run left behind', leftover)
        leftover.unlink()


def main() -> int:
    args = parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format='%(levelname)s: %(message)s',
    )

    if not args.snapshot_dir.is_dir():
        log.error('the snapshot directory %s does not exist', args.snapshot_dir)
        return 1
    try:
        clear_staging_dir(args.staging_dir)
    except OSError:
        log.exception('cannot prepare the staging directory %s', args.staging_dir)
        return 1

    state_paths = sorted(args.resources_dir.glob(f'*/{STATE_FILE_NAME}'))
    if not state_paths:
        log.info('found no state files in %s', args.resources_dir)

    now = datetime.now(timezone.utc)
    failed = False
    for state_path in state_paths:
        try:
            snapshot_state(state_path, args.snapshot_dir, args.staging_dir, now)
        except OSError:
            log.exception('cannot take a snapshot of %s', state_path)
            failed = True
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
