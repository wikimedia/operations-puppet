#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
Export summary metrics from the NFS kernel server (/proc/fs/nfsd) as a
prometheus node exporter textfile collector.

The node_exporter "nfsd" collector only reads /proc/net/rpc/nfsd, so this
adds the metrics which are otherwise unexported: NFSv4 clients and open
stateids counts, per-export statistics (labelled by the exported path) and
the NFSd file cache statistics.

No per-client series are produced; the remaining labels are "version"
(enabled NFS protocol versions), "type" (stateid type) and "path"
(exported directory), so the per-export series count grows linearly with
the number of exports.

Meant to be run as root from a cron job or systemd timer, e.g.:

    /usr/bin/python3 /usr/local/bin/nfsd-textfile-exporter \
        --outfile /var/lib/prometheus/node.d/nfsd.prom
"""

# python3.9 compat. Remove once
# https://phabricator.wikimedia.org/T403154 is done
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

from prometheus_client import CollectorRegistry, Counter, Gauge, write_to_textfile

NAMESPACE = "nfsd"

# A stateid entry line starts with the 8-hex-digit stateid generation.
STATEID_ENTRY_RE = re.compile(r"^[-\s]*0x[0-9a-fA-F]{8}")
TYPE_RE = re.compile(r"\btype:\s*(open|lock|deleg)\b")
# The kernel's seq_path()/seq_escape() encode specials as "\t"/"\n"/"\"/"\ "
# or " \xNN" for non-alphanumerics.
SEQ_ESCAPE_RE = re.compile(r"\\(?:x([0-9a-fA-F]{2})|(t|n|\\| ))")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--nfsd-dir",
        type=Path,
        default=Path("/proc/fs/nfsd"),
        help="NFSd pseudo-filesystem directory (default: %(default)s)",
    )
    parser.add_argument(
        "--outfile",
        type=Path,
        metavar="FILE.prom",
        required=True,
        help="Output file (e.g., /var/lib/prometheus/node.d/nfsd.prom)",
    )
    return parser.parse_args()


def read_text(path: Path) -> str | None:
    try:
        return path.read_text()
    except OSError as e:
        print(f"warning: cannot read {path}: {e}", file=sys.stderr)
        return None


def collect_clients(nfsd_dir: Path) -> tuple[int, dict[str, int]] | None:
    """Number of NFSv4 clients and open stateids count by stateid type."""
    clients_dir = nfsd_dir / "clients"
    try:
        client_ids = [
            entry.name
            for entry in os.scandir(clients_dir)
            if entry.is_dir() and entry.name.isdigit()
        ]
    except OSError as e:
        print(f"warning: cannot list {clients_dir}: {e}", file=sys.stderr)
        return None

    type_counts: dict[str, int] = {}
    old_format_files = 0
    for cid in client_ids:
        text = read_text(clients_dir / cid / "states")
        if text is None:
            continue
        types = TYPE_RE.findall(text)
        if types:
            for state_type in types:
                type_counts[state_type] = type_counts.get(state_type, 0) + 1
        else:
            lines = tuple(line for line in text.splitlines() if line.strip())
            entries = sum(1 for line in lines if STATEID_ENTRY_RE.match(line))
            if entries or lines:
                # Unrecognized states format: count entry lines, else all lines.
                type_counts["unknown"] = type_counts.get("unknown", 0) + (entries or len(lines))
                old_format_files += 1
    if old_format_files:
        print(
            f"warning: unrecognized states format in {old_format_files} "
            f"client(s); stateids counted as type=\"unknown\"",
            file=sys.stderr,
        )
    return len(client_ids), type_counts


def unescape_seq_path(value: str) -> str:
    """Undo the kernel's seq_path()/seq_escape() special character escaping."""
    if "\\" not in value:
        return value

    def _replace(match: re.Match) -> str:
        escaped = match.group(0)[1:]
        if escaped[0] == "x":
            return chr(int(escaped[1:3], 16))
        return {"t": "\t", "n": "\n", "\\": "\\", " ": " "}[escaped]

    return SEQ_ESCAPE_RE.sub(_replace, value)


def collect_export_stats(nfsd_dir: Path) -> tuple[int, list[dict]]:
    """Number of exports and their stats, keyed by the exported path.

    Each stats dict carries "fh_stale", "io_read", "io_write" counters and
    "start_time", the wall clock epoch seconds when the export was created.
    """
    count = 0
    text = read_text(nfsd_dir / "exports")
    if text is not None:
        count = sum(1 for line in text.splitlines() if line and not line.startswith("#"))

    exports: dict[str, dict] = {}
    current: dict | None = None
    text = read_text(nfsd_dir / "export_stats")
    if text is not None:
        fields = re.compile(r"^\s+(fh_stale|io_read|io_write):\s+(-?\d+)\s*$")
        for line in text.splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            match = fields.match(line)
            if match and current is not None:
                current[match.group(1)] += int(match.group(2))
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            # "<path>\t<client>[\t<start-time>]"
            path = unescape_seq_path(parts[0].strip())
            current = exports.setdefault(
                path,
                {"fh_stale": 0, "io_read": 0, "io_write": 0, "start_time": None},
            )
            if len(parts) >= 3 and parts[2].strip().isdigit():
                current["start_time"] = int(parts[2].strip())

    return count, [{**stats, "path": path} for path, stats in exports.items()]


def collect_filecache(nfsd_dir: Path) -> dict[str, int]:
    """NFSd open-file cache: "key: value" lines with cumulative counters."""
    text = read_text(nfsd_dir / "filecache")
    if text is None:
        return {}
    cache: dict[str, int] = {}
    for line in text.splitlines():
        match = re.match(r"^\s*([^:]+):\s*(-?\d+)\s*$", line)
        if match:
            cache[match.group(1)] = int(match.group(2))
    return cache


def export_nfsd_metrics(registry: CollectorRegistry, nfsd_dir: Path) -> None:
    # NFSv4 clients and open stateids
    clients = collect_clients(nfsd_dir)
    if clients is not None:
        client_count, type_counts = clients
        if client_count or type_counts:
            Gauge(
                "clients",
                "Number of known NFSv4 clients (by clientid)",
                namespace=NAMESPACE,
                registry=registry,
            ).set(client_count)
        if type_counts:
            states = Gauge(
                "states",
                "Number of open NFSv4 stateids by type",
                namespace=NAMESPACE,
                registry=registry,
                labelnames=["type"],
            )
            for state_type, count in type_counts.items():
                states.labels(state_type).set(count)

    # Per-export statistics, labelled by the exported path
    exports_count, per_export = collect_export_stats(nfsd_dir)
    if exports_count:
        Gauge(
            "exports",
            "Number of NFS exports (size of the export table)",
            namespace=NAMESPACE,
            registry=registry,
        ).set(exports_count)
    if per_export:
        fh_stale = Counter(
            "export_stats_fh_stale",
            "Stale filehandle errors per export",
            namespace=NAMESPACE,
            registry=registry,
            labelnames=["path"],
        )
        io_read = Counter(
            "export_stats_io_read_bytes",
            "Bytes read per export",
            namespace=NAMESPACE,
            registry=registry,
            labelnames=["path"],
        )
        io_write = Counter(
            "export_stats_io_write_bytes",
            "Bytes written per export",
            namespace=NAMESPACE,
            registry=registry,
            labelnames=["path"],
        )
        created = Gauge(
            "export_created_timestamp_seconds",
            "Wall clock time of when the export was created",
            namespace=NAMESPACE,
            registry=registry,
            labelnames=["path"],
        )
        for entry in per_export:
            fh_stale.labels(entry["path"]).inc(entry["fh_stale"])
            io_read.labels(entry["path"]).inc(entry["io_read"])
            io_write.labels(entry["path"]).inc(entry["io_write"])
            if entry["start_time"] is not None:
                created.labels(entry["path"]).set(entry["start_time"])

    # NFSd open-file cache
    filecache = collect_filecache(nfsd_dir)
    if filecache:
        if "total inodes" in filecache:
            Gauge(
                "filecache_entries",
                "Number of inodes currently held in the NFSd file cache",
                namespace=NAMESPACE,
                registry=registry,
            ).set(filecache["total inodes"])
        for key, suffix, help_text in (
            ("cache hits", "filecache_hits_total", "NFSd file cache lookups with a cached entry"),
            ("acquisitions", "filecache_acquisitions_total", "NFSd file cache entries acquired"),
            ("evictions", "filecache_evictions_total", "NFSd file cache entries evicted"),
        ):
            value = filecache.get(key)
            if value is not None:
                Counter(suffix, help_text, namespace=NAMESPACE, registry=registry).inc(value)

    # Enabled NFS protocol versions
    text = read_text(nfsd_dir / "versions")
    if text is not None and text.split():
        version_enabled = Gauge(
            "version_enabled",
            "Enabled NFS protocol version",
            namespace=NAMESPACE,
            registry=registry,
            labelnames=["version"],
        )
        for version in sorted(text.split()):
            version_enabled.labels(version).set(1)


def main() -> int:
    args = parse_args()
    registry = CollectorRegistry()

    if not args.nfsd_dir.is_dir():
        print(f"warning: {args.nfsd_dir} not present, no metrics collected", file=sys.stderr)
    else:
        try:
            export_nfsd_metrics(registry, args.nfsd_dir)
        except Exception as e:
            print(f"error exporting NFSd metrics: {e}", file=sys.stderr)
            return 1

    args.outfile.parent.mkdir(parents=True, exist_ok=True)
    write_to_textfile(args.outfile, registry)
    return 0


if __name__ == "__main__":
    sys.exit(main())
