#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Load lists of open proxies into netmapper files."""
import argparse
import json
import logging
import os
import pathlib
import subprocess
from typing import Dict, List

import requests
from netaddr import IPNetwork, cidr_merge


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser("proxy2netmapper")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Can be passed multiple times to encrease log level",
    )
    parser.add_argument(
        "--datadir",
        default="/srv/dataimport",
        help="Path where to download/unzip the feeds.",
    )
    parser.add_argument(
        "--config", "-c", default="config.json", help="Path of the configuration file."
    )
    parser.add_argument("--outfile", "-o", default="proxies.json")
    parser.add_argument("proxy_families", nargs="+", help="List of proxy network to select.")
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Configure logging"""
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


class ProxyFetcher:
    """Allows fetching proxy family information."""

    def __init__(
        self, configpath: pathlib.Path, families: List[str], data_path: pathlib.Path
    ) -> None:
        self.config = json.loads(configpath.read_text())
        self.selected_proxies = families
        self.data_path = data_path

    def download(self):
        r = requests.get(
            self.config["url"],
            headers=self.config["headers"],
            allow_redirects=True,
            timeout=120,
        )
        destfile = self.data_path / os.path.basename(self.config["url"])
        destfile.write_bytes(r.content)
        if destfile.suffix == ".gz":
            logging.info("Decompressing %s", destfile)
            try:
                subprocess.check_call(["gunzip", str(destfile)])
                destfile_uncompressed = destfile.with_suffix("")
            except subprocess.CalledProcessError as exc:
                logging.exception(exc)
                # TODO: change when not running on debian buster/python3.7
                # to using missing_ok
                for path in [destfile, destfile_uncompressed]:
                    if path.exists():
                        path.unlink()
        return destfile_uncompressed

    def load_data(self, path: pathlib.Path) -> Dict[str, List[IPNetwork]]:
        proxy_ips: Dict[str, List[IPNetwork]] = {k: [] for k in self.selected_proxies}
        loaded = 0
        try:
            with path.open("r") as fh:
                while True:
                    line = fh.readline()
                    if not line:
                        break
                    loaded += 1
                    if loaded % 10000 == 0:
                        print(".", end="")
                        logging.debug("Loaded %d lines", loaded)
                    try:
                        ip_data = json.loads(line)
                        proxies = ip_data.get("client", {}).get("proxies", [])
                        if not proxies:
                            continue
                        for proxy in proxy_ips.keys():
                            proxy_tag = f"{proxy.upper()}_PROXY"
                            if proxy_tag in proxies:
                                proxy_ips[proxy].append(IPNetwork(ip_data["ip"]))
                    except Exception:
                        logging.error("Unable to parse line: %s", line)
            print()
        finally:
            if path.exists():
                path.unlink()
        return proxy_ips

    def fetch(self):
        logging.info("Downloading data from %s", self.config["url"])
        dest = self.download()
        logging.info("Now loading and consolidating ip information")
        data = self.load_data(dest)
        for tag, ips in data.items():
            logging.info("Loaded %d entries for proxy family %s", len(ips), tag)
            merged_ips = list(map(lambda x: str(x), cidr_merge(ips)))
            logging.info("Reduced to %d CIDRs for proxy family %s", len(merged_ips), tag)
            data[tag] = merged_ips
        return data


if __name__ == "__main__":
    args = parse_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    configpath = pathlib.Path(args.config)
    fetcher = ProxyFetcher(configpath, args.proxy_families, args.datadir)
    ip_data = fetcher.fetch()
    out = pathlib.Path(args.outfile)
    tempout = out.with_suffix(".temp")
    with tempout.open("w", encoding="utf-8") as fh:
        json.dump(ip_data, fh)
    tempout.rename(out)
