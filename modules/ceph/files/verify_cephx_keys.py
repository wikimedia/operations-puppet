#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Compare the CephX keyring files on this host against the keys that the cluster holds.

Puppet writes each keyring file from the key data in the Puppet private repository.
The cluster keeps its own copy of every key. The two can disagree, for example after
somebody rotates a key by hand. This script finds those disagreements.

With no arguments it checks every keyring file in the standard locations and prints a
report. With --keyring it checks one file and reports the result as an exit code.
Puppet uses that second mode to decide if it must import a key.

Note that a key which Puppet does not import, i.e. one with import_to_ceph set to
false, is expected to be absent from the cluster. Use --ignore to hide those.

Exit codes:
  0  every key that was checked matches the cluster
  1  at least one key differs from the cluster, or is absent from it
  2  the check could not run
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Puppet writes keyrings to /etc/ceph, and to the data directory of each daemon.
KEYRING_GLOBS = [
    "/etc/ceph/*.keyring",
    "/var/lib/ceph/*/*/keyring",
    "/var/lib/ceph/bootstrap-*/*.keyring",
]

# Ceph creates these itself, so they have no keyring file for us to compare.
DEFAULT_IGNORE = [r"^client\.crash\."]

SECTION_RE = re.compile(r"^\[([^\]]+)\]\s*$")
KEY_RE = re.compile(r"^\s*key\s*=\s*(\S+)\s*$")
CAP_RE = re.compile(r'^\s*caps\s+(\w+)\s*=\s*"(.*)"\s*$')


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--keyring", type=Path, metavar="FILE",
        help="Check this one file instead of every file in the standard locations",
    )
    parser.add_argument(
        "--ignore", action="append", default=[], metavar="REGEX",
        help="Skip entities whose name matches. May be given more than once",
    )
    parser.add_argument(
        "--quiet", action="store_true", help="Report only the entities that disagree",
    )
    return parser.parse_args()


def read_keyring(path: Path) -> dict:
    """Return {entity: {"key": str, "caps": {name: value}}} for one keyring file."""
    entities = {}
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        section = SECTION_RE.match(line)
        if section:
            current = section.group(1)
            entities[current] = {"key": None, "caps": {}}
            continue
        if current is None:
            continue
        key = KEY_RE.match(line)
        if key:
            entities[current]["key"] = key.group(1)
            continue
        cap = CAP_RE.match(line)
        if cap:
            entities[current]["caps"][cap.group(1)] = cap.group(2)
    return entities


def ceph(args: list[str]) -> str:
    return subprocess.run(
        ["/usr/bin/ceph", *args], capture_output=True, check=True, encoding="utf-8"
    ).stdout


def cluster_entity(entity: str) -> dict | None:
    """Return the cluster's record for one entity, or None if it does not exist."""
    try:
        dump = json.loads(ceph(["auth", "get", entity, "-f", "json"]))
    except subprocess.CalledProcessError:
        # ceph auth get exits non-zero with ENOENT for an entity that is absent.
        return None
    return dump[0] if dump else None


def cluster_entities() -> dict:
    dump = json.loads(ceph(["auth", "ls", "-f", "json"]))
    if isinstance(dump, dict):
        dump = dump.get("auth_dump", [])
    return {record["entity"]: record for record in dump}


def compare(entity: str, local: dict, remote: dict | None) -> str | None:
    """Return a description of the disagreement, or None if the two match."""
    if remote is None:
        return "absent from the cluster"
    if local["key"] != remote.get("key"):
        return "key differs from the cluster"
    remote_caps = remote.get("caps", {})
    differing = sorted(
        name for name in set(local["caps"]) | set(remote_caps)
        if local["caps"].get(name, "").strip() != remote_caps.get(name, "").strip()
    )
    if differing:
        return f"caps differ: {', '.join(differing)}"
    return None


def report(status: str, entity: str, detail: str) -> None:
    print(f"{status:<8} {entity:<34} {detail}")


def check_one(path: Path) -> int:
    """Check a single keyring file. Print nothing when everything matches."""
    if not path.is_file():
        print(f"{path} does not exist", file=sys.stderr)
        return 2
    for entity, local in read_keyring(path).items():
        problem = compare(entity, local, cluster_entity(entity))
        if problem:
            print(f"{entity} in {path}: {problem}", file=sys.stderr)
            return 1
    return 0


def check_all(ignore: list[str], quiet: bool) -> int:
    patterns = [re.compile(p) for p in DEFAULT_IGNORE + ignore]
    remote = cluster_entities()
    seen = set()
    disagreements = 0

    for glob in KEYRING_GLOBS:
        for path in sorted(Path("/").glob(glob.lstrip("/"))):
            for entity, local in read_keyring(path).items():
                if any(p.search(entity) for p in patterns):
                    continue
                seen.add(entity)
                problem = compare(entity, local, remote.get(entity))
                if problem:
                    disagreements += 1
                    report("DIFFERS", entity, f"{path}: {problem}")
                elif not quiet:
                    report("OK", entity, str(path))

    for entity in sorted(set(remote) - seen):
        if any(p.search(entity) for p in patterns):
            continue
        report("EXTRA", entity, "in the cluster, but no keyring file on this host")

    print(f"\n{len(seen)} entities checked, {disagreements} disagree with the cluster")
    return 1 if disagreements else 0


def main() -> int:
    args = parse_args()
    try:
        if args.keyring:
            return check_one(args.keyring)
        return check_all(args.ignore, args.quiet)
    except subprocess.CalledProcessError as error:
        print(f"could not query the cluster: {error.stderr.strip()}", file=sys.stderr)
        return 2
    except OSError as error:
        print(f"could not read a keyring file: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
