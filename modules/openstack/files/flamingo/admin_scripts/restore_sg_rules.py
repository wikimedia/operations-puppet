#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Restore security group rules from backup files for ONE project.

Rules that already exist (matched by content) are skipped, so passing multiple
overlapping backups to the script is safe. Backup entries created since
ROLLBACK_TO are ignored: they are not part of the state to restore (for
example, replacements that a later run of the drop script deleted).

Egress rules are restored first. Afterwards, the script deletes all rules of
the project created since ROLLBACK_TO. These include the tcp/22 rules that
drop_external_sg_rules.py created, and manual rules added while debugging.
The script does not delete:
- rules that are in the backups (an earlier run of this script restored them),
- rules managed by tofu.
If a rule fails to restore, the script deletes no rules.

Rules managed by tofu must be recreated with `tofu apply` first: the script
refuses to run with --execute while any are missing.

Dry run unless --execute."""
import argparse
import json
import sys

import openstack
from openstack import exceptions

KEYS = (
    "security_group_id",
    "direction",
    "ether_type",
    "protocol",
    "port_range_min",
    "port_range_max",
    "remote_ip_prefix",
    "remote_group_id",
    "remote_address_group_id",
    "description",
    "project_id",
)
TOFU = "managed by tofu-infra"

# State we are rolling back to: before the first time we ran the
# drop_external_sg_rules.py script. Rules created since then are deleted.
ROLLBACK_TO = "2026-10-21T00:00:00Z"


def sig(r):
    return (
        r["security_group_id"],
        r["direction"],
        r["ether_type"],
        r.get("protocol"),
        r.get("port_range_min"),
        r.get("port_range_max"),
        r.get("remote_ip_prefix"),
        r.get("remote_group_id"),
        r.get("remote_address_group_id"),
    )


def label(r):
    if r.get("port_range_min") is None:
        ports = "all"
    else:
        ports = f"{r['port_range_min']}-{r['port_range_max']}"
    src = r.get("remote_ip_prefix") or r.get("remote_group_id") or "any"
    return (
        f"{r['direction']} {r['ether_type']} {r.get('protocol') or 'any'} {ports} "
        f"from {src} sg={r['security_group_id'][:8]}"
    )


def is_new(r, backed_up):
    """Created since ROLLBACK_TO, and not restored or managed by tofu."""
    return (
        r["created_at"] >= ROLLBACK_TO
        and sig(r) not in backed_up
        and TOFU not in (r.get("description") or "")
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("backups", nargs="+", help="backup JSON file(s)")
    ap.add_argument("--project", required=True)
    ap.add_argument("--execute", action="store_true")
    ap.add_argument("--cloud")
    args = ap.parse_args()

    conn = openstack.connect(cloud=args.cloud) if args.cloud else openstack.connect()
    pid = conn.identity.find_project(args.project, ignore_missing=False).id

    existing = [r.to_dict() for r in conn.network.security_group_rules(project_id=pid)]
    have = {sig(r) for r in existing}

    backed_up, too_new = {}, {}
    for path in args.backups:
        with open(path) as f:
            for e in json.load(f):
                if e.get("project_id") != pid:
                    continue
                if e.get("created_at", "") >= ROLLBACK_TO:
                    too_new.setdefault(sig(e), e)
                else:
                    backed_up.setdefault(sig(e), e)
    # a rule restored and then dropped again also has an older entry
    too_new = {s: e for s, e in too_new.items() if s not in backed_up}
    if too_new:
        print(
            f"Ignoring {len(too_new)} backup entries created since {ROLLBACK_TO}:",
            file=sys.stderr,
        )
        for e in too_new.values():
            print(f"  {label(e)} (created {e['created_at']})", file=sys.stderr)
    planned = {s: e for s, e in backed_up.items() if s not in have}
    skipped = backed_up.keys() & have

    tofu_pending = [e for e in planned.values() if TOFU in (e.get("description") or "")]
    if tofu_pending:
        print(
            f"WARNING: {len(tofu_pending)} planned rules are managed by tofu and "
            f"missing from the project. Run tofu apply first:",
            file=sys.stderr,
        )
        for e in tofu_pending:
            print(f"  {label(e)}", file=sys.stderr)
        if args.execute:
            sys.exit("Refusing to recreate tofu-managed rules; run tofu apply and retry.")

    restored, failed = [], 0
    # egress first, so outbound access comes back before anything else
    for e in sorted(planned.values(), key=lambda e: e["direction"] != "egress"):
        if not args.execute:
            print(f"[dry-run] would recreate {label(e)}")
            continue
        try:
            conn.network.create_security_group_rule(
                **{k: e[k] for k in KEYS if e.get(k) is not None}
            )
            restored.append(e)
            print(f"RECREATED {label(e)}")
        except exceptions.ConflictException:
            restored.append(e)
            print(f"EXISTS {label(e)}")
        except Exception as exc:
            failed += 1
            print(f"FAILED {label(e)}: {exc}", file=sys.stderr)

    removed = 0
    to_delete = [r for r in existing if is_new(r, backed_up)]
    if failed and to_delete:
        # the tcp/22 replacements can be the only access left
        print(
            f"Not deleting {len(to_delete)} new rules: {failed} rules failed to "
            "restore. Fix the failures and run the script again.",
            file=sys.stderr,
        )
        to_delete = []
    for r in to_delete:
        desc = f"{label(r)} ({r['id']}, created {r['created_at']})"
        if not args.execute:
            print(f"[dry-run] would delete new {desc}")
            removed += 1
            continue
        try:
            conn.network.delete_security_group_rule(r["id"])
            print(f"DELETED new {desc}")
            removed += 1
        except Exception as exc:
            failed += 1
            print(f"FAILED deleting {r['id']}: {exc}", file=sys.stderr)

    if args.execute:
        print(
            f"Recreated {len(restored)} rules, deleted {removed} new, "
            f"{len(skipped)} already present, {failed} failed",
            file=sys.stderr,
        )
    else:
        print(
            f"Would recreate {len(planned)} rules, would delete {removed} new, "
            f"{len(skipped)} already present",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
