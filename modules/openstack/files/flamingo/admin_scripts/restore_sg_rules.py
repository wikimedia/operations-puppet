#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Restore security group rules from backup files for ONE project.

Rules that already exist (matched by content) are skipped, so passing multiple
overlapping backups to the script is safe.

Egress rules are restored first. Afterwards, stray egress tcp/22 rules created
since STRAY_SINCE are removed. (The stray egress rules were created by a bug in
drop_external_sg_rules.py)

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
# drop_external_sg_rules.py script
STRAY_SINCE = "2026-10-21T00:00:00Z"


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


def is_allow_all_egress(r):
    return (
        r["direction"] == "egress"
        and not r.get("protocol")
        and not r.get("remote_ip_prefix")
        and not r.get("remote_group_id")
    )


def is_stray(r, allow_all):
    """Egress tcp/22, no destination, no description, created since STRAY_SINCE,
    in a group that has allow-all egress for the same IP version."""
    return (
        r["direction"] == "egress"
        and r.get("protocol") == "tcp"
        and r.get("port_range_min") == 22
        and r.get("port_range_max") == 22
        and not r.get("remote_ip_prefix")
        and not r.get("remote_group_id")
        and not r.get("description")
        and r["created_at"] >= STRAY_SINCE
        and (r["security_group_id"], r["ether_type"]) in allow_all
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

    planned = {}
    skipped = set()
    for path in args.backups:
        with open(path) as f:
            for e in json.load(f):
                if e.get("project_id") != pid:
                    continue
                s = sig(e)
                if s in have:
                    skipped.add(s)
                elif s not in planned:
                    planned[s] = e

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
    # allow-all egress that exists now, or that this run restored / would restore
    basis = restored if args.execute else list(planned.values())
    allow_all = {
        (r["security_group_id"], r["ether_type"])
        for r in existing + basis
        if is_allow_all_egress(r)
    }
    for r in existing:
        if not is_stray(r, allow_all):
            continue
        desc = f"{label(r)} ({r['id']}, created {r['created_at']})"
        if not args.execute:
            print(f"[dry-run] would delete stray {desc}")
            removed += 1
            continue
        try:
            conn.network.delete_security_group_rule(r["id"])
            print(f"DELETED stray {desc}")
            removed += 1
        except Exception as exc:
            failed += 1
            print(f"FAILED deleting {r['id']}: {exc}", file=sys.stderr)

    if args.execute:
        print(
            f"Recreated {len(restored)} rules, deleted {removed} stray, "
            f"{len(skipped)} already present, {failed} failed",
            file=sys.stderr,
        )
    else:
        print(
            f"Would recreate {len(planned)} rules, would delete {removed} stray, "
            f"{len(skipped)} already present",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
