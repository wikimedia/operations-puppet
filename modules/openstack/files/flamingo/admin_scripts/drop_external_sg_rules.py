#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""Remove security group rules that allow traffic from or to OUTSIDE the
project, keeping intra-project rules (remote group in the same project, or a
single-host CIDR matching a VM of the same project).

Ingress: only SSH is allowed from outside. Each deleted rule that allowed
tcp/22 is replaced with a tcp/22 rule from the same remote.

Egress: only essential traffic is allowed to outside: DNS (tcp/udp 53) and the
metadata service (tcp/80 to 169.254.169.254), plus --keep-egress entries. Each
deleted rule is replaced with the part of it that the allow list permits, so a
replacement never allows more than the deleted rule.

Replacement rules have a description that starts with "drop_external_sg_rules".
Dry run unless --execute. To undo, use restore_sg_rules.py with the backup file."""
import argparse
import ipaddress
import json
import sys
from collections import defaultdict
from datetime import datetime

import openstack
from openstack import exceptions

ICMP = {"icmp", "ipv6-icmp", "icmpv6"}
# Neutron accepts protocol numbers as well as names
PROTO_NAMES = {"1": "icmp", "6": "tcp", "17": "udp", "58": "ipv6-icmp"}
ALL_PORTS = (1, 65535)
METADATA = ipaddress.ip_network("169.254.169.254/32")

# Allow-list entries: (protocol, (port_min, port_max), destination network or None)
INGRESS_ALLOW = [("tcp", (22, 22), None)]
EGRESS_ALLOW = [
    ("udp", (53, 53), None),
    ("tcp", (53, 53), None),
    ("tcp", (80, 80), METADATA),
]


def proto(r):
    p = (r.protocol or "any").lower()
    return PROTO_NAMES.get(p, p)


def ports(r):
    if r.port_range_min is None:
        return ALL_PORTS
    return (r.port_range_min, r.port_range_max)


def parse_keep(spec):
    spec, _, cidr = spec.lower().partition("@")
    proto, _, port_spec = spec.partition("/")
    net = ipaddress.ip_network(cidr, strict=False) if cidr else None
    if not port_spec:
        return (proto, ALL_PORTS, net)
    lo, _, hi = port_spec.partition("-")
    return (proto, (int(lo), int(hi or lo)), net)


def within(r, entry):
    """True if allow-list entry permits all the traffic that rule r allows."""
    eproto, (elo, ehi), enet = entry
    if eproto != "any" and proto(r) != eproto:
        return False
    lo, hi = ports(r)
    if not elo <= lo <= hi <= ehi:
        return False
    if enet is None:
        return True
    if not r.remote_ip_prefix:
        return False
    net = ipaddress.ip_network(r.remote_ip_prefix, strict=False)
    return net.version == enet.version and net.subnet_of(enet)


def intersect(r, entry, project_id):
    """Rule (as kwargs) that allows the traffic permitted by both rule r and
    allow-list entry, or None if there is no such traffic."""
    eproto, (elo, ehi), enet = entry
    if eproto == "any":
        p = proto(r)
    elif proto(r) in ("any", eproto):
        p = eproto
    else:
        return None
    lo, hi = ports(r)
    lo, hi = max(lo, elo), min(hi, ehi)
    if lo > hi:
        return None
    remote = {
        k: v
        for k, v in (
            ("remote_ip_prefix", r.remote_ip_prefix),
            ("remote_group_id", r.remote_group_id),
            ("remote_address_group_id", r.remote_address_group_id),
        )
        if v
    }
    if enet is not None:
        if f"IPv{enet.version}" != r.ether_type:
            return None
        if r.remote_group_id or r.remote_address_group_id:
            return None
        if not r.remote_ip_prefix:
            remote = {"remote_ip_prefix": str(enet)}
        else:
            net = ipaddress.ip_network(r.remote_ip_prefix, strict=False)
            if enet.subnet_of(net):
                remote = {"remote_ip_prefix": str(enet)}
            elif not net.subnet_of(enet):
                return None
    rule = dict(
        security_group_id=r.security_group_id,
        direction=r.direction,
        ether_type=r.ether_type,
        project_id=project_id,
        description=f"drop_external_sg_rules: replacement for {r.id}",
        **remote,
    )
    if p != "any":
        rule["protocol"] = p
    if (lo, hi) != ALL_PORTS:
        rule["port_range_min"], rule["port_range_max"] = lo, hi
    return rule


def describe(r):
    if r.port_range_min is None:
        port_str = "all"
    elif r.port_range_min == r.port_range_max:
        port_str = str(r.port_range_min)
    else:
        port_str = f"{r.port_range_min}-{r.port_range_max}"
    return f"{r.direction} {r.ether_type} {proto(r)} {port_str}"


def describe_new(rule):
    port_str = rule.get("port_range_min", "all")
    if rule.get("port_range_max", port_str) != port_str:
        port_str = f"{port_str}-{rule['port_range_max']}"
    remote = (
        rule.get("remote_ip_prefix")
        or rule.get("remote_group_id")
        or rule.get("remote_address_group_id")
        or "anywhere"
    )
    return f"{rule.get('protocol', 'any')}/{port_str} {remote}"


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
        help="never delete ingress rules for this port, e.g. tcp/9100 or tcp/80-90 or udp",
    )
    ap.add_argument(
        "--keep-egress",
        action="append",
        default=[],
        metavar="PROTO/PORT[@CIDR]",
        help="also allow this egress traffic, e.g. udp/123 or tcp/389@172.16.0.0/12",
    )
    ap.add_argument(
        "--drop-icmp", action="store_true", help="also remove external ICMP rules"
    )
    ap.add_argument("--backup-dir", default="/root")
    args = ap.parse_args()

    if not args.project and not args.all_projects:
        sys.exit(
            "Refusing to run without a scope: pass --project NAME or --all-projects"
        )
    keeps = [parse_keep(k) for k in args.keep_port]
    allow = {
        "ingress": INGRESS_ALLOW,
        "egress": EGRESS_ALLOW + [parse_keep(k) for k in args.keep_egress],
    }

    conn = openstack.connect(cloud=args.cloud) if args.cloud else openstack.connect()

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
        # external remote from here on
        if proto(r) in ICMP and not args.drop_icmp:
            continue
        if any(within(r, e) for e in allow[r.direction]):
            continue
        if r.direction == "ingress" and any(within(r, k) for k in keeps):
            continue
        to_delete.append(r)
        replacements[r.id] = [
            rule
            for rule in (intersect(r, e, sg.project_id) for e in allow[r.direction])
            if rule
        ]

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

    failed = created = 0
    for r in sorted(
        to_delete,
        key=lambda r: (
            project_names.get(groups[r.security_group_id].project_id, ""),
            sg_names.get(r.security_group_id, ""),
        ),
    ):
        sg = groups[r.security_group_id]
        remote = r.remote_ip_prefix or (
            f"sg:{sg_names.get(r.remote_group_id, r.remote_group_id)}"
            if r.remote_group_id
            else r.remote_address_group_id or "anywhere"
        )
        label = (
            f"{r.id} project={project_names.get(sg.project_id, sg.project_id)} "
            f"sg={sg.name} {describe(r)} "
            f"{'from' if r.direction == 'ingress' else 'to'} {remote}"
        )
        repl = replacements[r.id]
        repl_str = (
            f" (+ replaced by {', '.join(describe_new(x) for x in repl)})" if repl else ""
        )
        if not args.execute:
            print(f"[dry-run] would delete {label}{repl_str}")
            continue
        try:
            for rule in repl:
                try:
                    conn.network.create_security_group_rule(**rule)
                    created += 1
                except exceptions.ConflictException:
                    pass  # an equivalent rule already exists
            print(f"DELETING {label}{repl_str}")
            conn.network.delete_security_group_rule(r.id)
        except Exception as exc:
            failed += 1
            print(f"  FAILED {label}: {exc}", file=sys.stderr)

    if args.execute:
        summary = f"Deleted {len(to_delete) - failed} rules; created {created} replacements"
    else:
        planned = sum(len(x) for x in replacements.values())
        summary = f"Would delete {len(to_delete)} rules; would create {planned} replacements"
    print(
        f"{summary}; kept {kept_internal} intra-project rules; {failed} failed",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
