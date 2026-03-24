#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
IPIP encapsulation checker. Sends SYN packets to LVS pool nodes via IPIP/IP6IP6
encapsulation and pushes results to a Prometheus Pushgateway.
"""

import argparse
import logging
import random
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from ipaddress import IPv4Address, IPv6Address, ip_address
from typing import Any

import yaml
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from scapy.layers.inet import IP, TCP
from scapy.layers.inet6 import IPv6
from scapy.all import conf as scapyconf, L3RawSocket, L3RawSocket6

scapyconf.checkIPinIP = False
scapyconf.sniff_promisc = False


log = logging.getLogger(__name__)

JOB = os.path.basename(__file__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check IPIP encapsulation traffic to LVS pool nodes "
            "and push metrics to Prometheus Pushgateway."
        )
    )
    parser.add_argument(
        "--config",
        required=True,
        metavar="PATH",
        help="Path to the pools YAML config file (e.g. /etc/myconfig/pools-eqiad.yaml)",
    )
    parser.add_argument(
        "--pushgateway",
        required=True,
        metavar="URL",
        help="Prometheus Pushgateway URL (e.g. http://pushgateway.example.org:9091)",
    )
    parser.add_argument(
        "--inner-src-ipv4",
        required=True,
        metavar="IPV4",
        help="Inner source IPv4 of the probe host",
    )
    parser.add_argument(
        "--inner-src-ipv6",
        required=True,
        metavar="IPV6",
        help="Inner source IPv6 of the probe host",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=3.0,
        metavar="SECONDS",
        help="Timeout in seconds for each SYN probe (default: 3)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Dump metrics to stdout instead of pushing to the Pushgateway",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging",
    )
    return parser.parse_args()


def load_config(path: str) -> dict[str, Any]:
    with open(path) as f:
        return yaml.safe_load(f)


def ipip_traffic_accepted(
    *,
    outer_src_ip: IPv4Address | IPv6Address,
    outer_dst_ip: IPv4Address | IPv6Address,
    inner_src_ip: IPv4Address | IPv6Address,
    inner_dst_ip: IPv4Address | IPv6Address,
    dport: int,
    timeout: float,
) -> bool:
    """Send a single SYN packet using IPIP/IP6IP6 encapsulation."""
    if inner_dst_ip.version == 6:
        L3 = IPv6
        sock = L3RawSocket6()
    else:
        L3 = IP
        sock = L3RawSocket()

    sport = random.randint(1024, 65535)
    syn_packet = (
        L3(src=str(outer_src_ip), dst=str(outer_dst_ip))
        / L3(src=str(inner_src_ip), dst=str(inner_dst_ip))
        / TCP(sport=sport, dport=dport, flags="S", seq=1000, options=[("MSS", 1400)])
    )
    try:
        response = sock.sr1(syn_packet, timeout=timeout, verbose=False)
    finally:
        sock.close()

    return response is not None


def run_checks(
    pools: dict[str, Any],
    inner_src_ipv4: IPv4Address,
    inner_src_ipv6: IPv6Address,
    timeout: float,
    registry: CollectorRegistry,
) -> None:
    """Run IPIP checks for all pools and nodes, recording results into the registry."""
    ipip_check = Gauge(
        "ipip_check_success",
        (
            "Whether the IPIP encapsulated SYN probe to an LVS pool node "
            "succeeded (1=success, 0=failure)"
        ),
        ["pool", "node", "hostname", "vip", "port"],
        registry=registry,
    )
    ipip_check_duration = Gauge(
        "ipip_check_duration_seconds",
        "Time taken to complete the IPIP encapsulated SYN probe",
        ["pool", "node", "hostname", "vip", "port"],
        registry=registry,
    )

    for pool_name, pool in pools.items():
        inner_dst_ip = ip_address(pool["vip"])
        inner_src_ip = inner_src_ipv6 if inner_dst_ip.version == 6 else inner_src_ipv4
        if inner_dst_ip.version == 6:
            outer_src_ip = IPv6Address("0100::1")
        else:
            outer_src_ip = IPv4Address("172.16.1.1")
        port = pool["port"]
        nodes = pool["nodes"]

        def probe_node(node: dict) -> tuple[str, str, bool, float]:
            hostname = node["hostname"]
            ip = ip_address(node["ip"])
            success = False
            start = time.monotonic()
            try:
                success = ipip_traffic_accepted(
                    outer_src_ip=outer_src_ip,
                    outer_dst_ip=ip,
                    inner_src_ip=inner_src_ip,
                    inner_dst_ip=inner_dst_ip,
                    dport=port,
                    timeout=timeout,
                )

            except Exception as e:
                log.warning(
                    "probe failed pool=%s hostname=%s ip=%s error=%s", pool_name, hostname, ip, e
                )
            elapsed = time.monotonic() - start
            return hostname, ip, success, elapsed

        # probe all nodes concurrently
        with ThreadPoolExecutor() as executor:
            futures = {executor.submit(probe_node, node): node for node in nodes}
            for future in as_completed(futures):
                hostname, ip, success, elapsed = future.result()
                labels = {
                    "pool": pool_name,
                    "node": ip,
                    "hostname": hostname,
                    "vip": inner_dst_ip,
                    "port": port,
                }
                ipip_check.labels(**labels).set(1 if success else 0)
                ipip_check_duration.labels(**labels).set(elapsed)
                log.info(
                    "pool=%s hostname=%s, node=%s vip=%s success=%s duration=%.3fs",
                    pool_name, hostname, ip, inner_dst_ip, success, elapsed,
                )


def main() -> None:
    args = parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    log.info("Loading config from %s", args.config)
    try:
        pools = load_config(args.config)
    except OSError as e:
        log.error("Failed to load config: %s", e)
        sys.exit(1)

    registry = CollectorRegistry()

    run_checks(
        pools=pools,
        inner_src_ipv4=IPv4Address(args.inner_src_ipv4),
        inner_src_ipv6=IPv6Address(args.inner_src_ipv6),
        timeout=args.timeout,
        registry=registry,
    )

    if args.dry_run:
        from prometheus_client import generate_latest
        sys.stdout.buffer.write(generate_latest(registry))
        return

    log.info("Pushing metrics to %s (job=%s)", args.pushgateway, JOB)
    try:
        push_to_gateway(args.pushgateway, JOB, registry=registry)
        log.info("Metrics pushed successfully")
    except Exception as e:
        log.error("Failed to push metrics to Pushgateway: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
