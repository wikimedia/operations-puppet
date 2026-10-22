#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""Remove security group rules that allow non-SSH traffic from OUTSIDE the
project, keeping intra-project rules (remote group in the same project, or a
single-host CIDR matching a VM of the same project). Dry run unless --execute."""
import argparse
import ipaddress
import json
import sys
from collections import defaultdict
from datetime import datetime

import openstack
from openstack import exceptions

ICMP = {"icmp", "ipv6-icmp", "icmpv6", "1", "58"}


def parse_keep(spec):
    proto, _, ports = spec.lower().partition("/")
    if not ports:
        return (proto, None, None)
    lo, _, hi = ports.partition("-")
    return (proto, int(lo), int(hi or lo))


def keep_listed(r, keeps):
    proto = (r.protocol or "any").lower()
    for kproto, klo, khi in keeps:
        if proto != kproto:
            continue
        if klo is None:
            return True
        if (
            r.port_range_min is not None
            and klo <= r.port_range_min
            and r.port_range_max <= khi
        ):
            return True
    return False


def covers_22(r):
    proto = (r.protocol or "any").lower()
    if proto == "any":
        return True
    if proto != "tcp":
        return False
    if r.port_range_min is None:
        return True
    return r.port_range_min <= 22 <= r.port_range_max


def is_ssh_only(r):
    return (
        r.protocol or ""
    ).lower() == "tcp" and r.port_range_min == 22 == r.port_range_max


def describe(r):
    proto = r.protocol or "any"
    if r.port_range_min is None:
        ports = "all"
    elif r.port_range_min == r.port_range_max:
        ports = str(r.port_range_min)
    else:
        ports = f"{r.port_range_min}-{r.port_range_max}"
    return f"{r.ether_type} {proto} {ports}"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--execute", action="store_true")
    ap.add_argument("--project", help="limit to one project (name or ID)")
    ap.add_argument("--all-projects", action="store_true")
    ap.add_argument("--cloud")
    ap.add_argument(
        "--keep-port",
        action="append",
        default=[],
        metavar="PROTO/PORT",
        help="never delete rules for this port, e.g. tcp/9100 or tcp/80-90 or udp",
    )
    ap.add_argument(
        "--drop-icmp", action="store_true", help="also remove external ICMP rules"
    )
    ap.add_argument("--backup-dir", default="/root")
    ap.add_argument("--restore", metavar="FILE")
    args = ap.parse_args()

    conn = openstack.connect(cloud=args.cloud) if args.cloud else openstack.connect()

    if args.restore:
        with open(args.restore) as f:
            for e in json.load(f):
                label = f"{e['id']} sg={e['security_group_id']} {e['ether_type']} {e['protocol']}"
                if not args.execute:
                    print(f"[dry-run] would recreate {label}")
                    continue
                keys = (
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
                conn.network.create_security_group_rule(
                    **{k: e[k] for k in keys if e.get(k) is not None}
                )
                print(f"RECREATED {label}")
        return

    if not args.project and not args.all_projects:
        sys.exit(
            "Refusing to run without a scope: pass --project NAME or --all-projects"
        )
    keeps = [parse_keep(k) for k in args.keep_port]

    project_names = {p.id: p.name for p in conn.identity.projects()}
    filters = {}
    if args.project:
        filters["project_id"] = conn.identity.find_project(
            args.project, ignore_missing=False
        ).id

    groups = {sg.id: sg for sg in conn.network.security_groups()}
    sg_names = {i: g.name for i, g in groups.items()}

    # fixed IPs of each project's own ports (for single-host CIDR rules)
    project_ips = defaultdict(set)
    for p in conn.network.ports():
        for fip in p.fixed_ips or []:
            project_ips[p.project_id].add(fip["ip_address"])

    to_delete, replacements = [], {}
    kept_internal = 0
    for r in conn.network.security_group_rules(**filters):
        sg = groups.get(r.security_group_id)
        if sg is None:
            continue
        # intra-project?
        if r.remote_group_id:
            rg = groups.get(r.remote_group_id)
            if rg is not None and rg.project_id == sg.project_id:
                kept_internal += 1
                continue
        elif r.remote_ip_prefix:
            net = ipaddress.ip_network(r.remote_ip_prefix, strict=False)
            if (
                net.num_addresses == 1
                and str(net.network_address) in project_ips[sg.project_id]
            ):
                kept_internal += 1
                continue
        # external source from here on
        proto = (r.protocol or "any").lower()
        if proto in ICMP and not args.drop_icmp:
            continue
        if is_ssh_only(r) or keep_listed(r, keeps):
            continue
        to_delete.append(r)
        if covers_22(r):
            replacements[r.id] = dict(
                security_group_id=r.security_group_id,
                direction=r.direction,
                ether_type=r.ether_type,
                protocol="tcp",
                port_range_min=22,
                port_range_max=22,
                project_id=sg.project_id,
                **{
                    k: v
                    for k, v in (
                        ("remote_ip_prefix", r.remote_ip_prefix),
                        ("remote_group_id", r.remote_group_id),
                    )
                    if v
                },
            )

    if not to_delete:
        print("Nothing to change.", file=sys.stderr)
        return

    stamp = f"{datetime.now():%Y%m%dT%H%M%S}"
    scope = args.project if args.project else "all-projects"
    scope = "".join(c if c.isalnum() or c in "-_." else "_" for c in scope)
    suffix = "" if args.execute else "-dryrun"
    backup = (
        f"{args.backup_dir.rstrip('/')}/sg-rules-backup-{scope}-{stamp}{suffix}.json"
    )
    with open(backup, "w") as f:
        json.dump([r.to_dict() for r in to_delete], f, indent=2, default=str)
    print(f"Backup of {len(to_delete)} rules written to {backup}", file=sys.stderr)

    failed = 0
    for r in sorted(
        to_delete,
        key=lambda r: (
            project_names.get(groups[r.security_group_id].project_id, ""),
            sg_names.get(r.security_group_id, ""),
        ),
    ):
        sg = groups[r.security_group_id]
        src = r.remote_ip_prefix or (
            f"sg:{sg_names.get(r.remote_group_id, r.remote_group_id)}"
            if r.remote_group_id
            else "anywhere"
        )
        label = (
            f"{r.id} project={project_names.get(sg.project_id, sg.project_id)} "
            f"sg={sg.name} {describe(r)} from {src}"
        )
        repl = replacements.get(r.id)
        if not args.execute:
            print(
                f"[dry-run] would delete {label}"
                + (" (+ tcp/22 replacement)" if repl else "")
            )
            continue
        try:
            if repl:
                try:
                    conn.network.create_security_group_rule(**repl)
                except exceptions.ConflictException:
                    pass  # an equivalent tcp/22 rule already exists
            print(f"DELETING {label}" + (" (+ tcp/22 replacement)" if repl else ""))
            conn.network.delete_security_group_rule(r.id)
        except Exception as exc:
            failed += 1
            print(f"  FAILED {label}: {exc}", file=sys.stderr)

    verb = "Deleted" if args.execute else "Would delete"
    print(
        f"{verb} {len(to_delete) - failed} rules ({len(replacements)} with tcp/22 replacement); "
        f"kept {kept_internal} intra-project rules; {failed} failed",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
