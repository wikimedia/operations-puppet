#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Script to download address ranges for various cloud providers and store them in a json file"""
import csv
import json
import logging
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass, field
from pathlib import Path
from typing import Set

import yaml
from conftool.extensions.reqconfig import (
    Requestctl,
    RequestctlError,
    parse_args as reqctl_args,
)
from git import Repo
from lxml import html
from netaddr import IPNetwork, cidr_merge
from requests import Session
from requests.exceptions import RequestException
from wmflib.requests import http_session


@dataclass
class ExternalCloudVendor:
    """Data class for external cloud provider metadata"""

    name: str
    url: str
    subkeys: Set = field(default_factory=set)
    prefixes: str = "prefixes"

    def get_networks(self, session: Session) -> Set[str]:
        """Get and parse a list of IP blocks from a public url

        This function downloads the url, which is expected to be a json file with
        the appropriate IP blocks placed in
        $json_data[$prefixes][$subkeys]

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        data = session.get(self.url, allow_redirects=True).json()
        nets = {
            prefix.get(key) for key in self.subkeys for prefix in data[self.prefixes]
        }
        nets.discard(None)
        return nets


class ExternalCloudVendorOci:
    """class to fetch OCI nets"""

    name: str = "OCI"
    url: str = "https://docs.cloud.oracle.com/en-us/iaas/tools/public_ip_ranges.json"

    def get_networks(self, session: Session) -> Set[str]:
        """Get and parse a list of IP blocks from a public url

        This function downloads the url, which is expected to be a json file with
        the appropriate IP blocks placed in
        $json_data[$prefixes][$subkeys]

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        nets = set()
        data = session.get(self.url, allow_redirects=True).json()
        for region in data["regions"]:
            nets |= {net["cidr"] for net in region["cidrs"]}
        return nets


class ExternalCloudVendorAzure:
    """Class to fetch data from  Azure"""

    name: str = "Azure"
    url: str = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"

    def get_networks(self, session: Session) -> Set[str]:
        """Fetch Azure networks

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        page = session.get(self.url)
        tree = html.fromstring(page.content)
        download_url = tree.xpath(
            "//a[contains(@class, 'failoverLink') and "
            "contains(@href,'download.microsoft.com/download/')]/@href"
        )[0]

        ips = session.get(download_url, allow_redirects=True).json()
        nets = {
            prefix
            for item in ips["values"]
            for prefix in item["properties"]["addressPrefixes"]
        }
        return nets


@dataclass
class CSVExternalCloudVendor:
    """Class to fetch networks from a CSV file formatted to RFC 8805"""

    name: str
    url: str

    def get_networks(self, session: Session) -> Set[str]:
        """Fetch networks in CSV format

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        ips_request = session.get(self.url, allow_redirects=True)
        lines = (
            line for line in ips_request.text.splitlines()
            if not line.startswith("#")
        )
        ips = csv.DictReader(
            lines,
            fieldnames=["range", "country", "region", "city", "postcode"],
        )
        nets = {item["range"] for item in ips}
        return nets


def merge_adjacent(nets: Set[str]) -> Set[str]:
    """Merge adjacent networks

    Arguments:
        nets (Set[str]): A set of network ranges

    Returns
        Set(str): A set of network ranges with ajacent prefixes merged
    """
    merged = cidr_merge([IPNetwork(net) for net in nets])
    return {str(net) for net in merged}


def get_args() -> Namespace:
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "datafile", type=Path, help="location of the json data file to read/write"
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Can be passed multiple times to encrease log level",
    )
    parser.add_argument(
        "--conftool",
        "-c",
        action="store_true",
        help="If this is provided, the data will be saved to conftool and not just to file.",
    )
    parser.add_argument(
        "--repo",
        "-r",
        help="The puppet private repository path.",
        default="/srv/private",
    )
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Configure logging"""
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def main() -> int:
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    data = dict()
    runtime_error = False

    providers = {
        "cloud": [
            ExternalCloudVendor(
                "AWS", "https://ip-ranges.amazonaws.com/ip-ranges.json", {"ip_prefix"}
            ),
            ExternalCloudVendor(
                "GCP",
                "https://www.gstatic.com/ipranges/cloud.json",
                {"ipv4Prefix", "ipv6Prefix"},
            ),
            ExternalCloudVendorOci(),
            ExternalCloudVendorAzure(),
            CSVExternalCloudVendor(
                "DigitalOcean",
                # This is the file linked from the digitalocean platform documentation website:
                # https://www.digitalocean.com/docs/platform/
                "http://digitalocean.com/geo/google.csv"
            ),
            CSVExternalCloudVendor("Linode", "https://geoip.linode.com/"),
        ],
        "known-clients": [
            ExternalCloudVendor(
                "Googlebot",
                # https://developers.google.com/search/docs/advanced/crawling/verifying-googlebot
                "https://developers.google.com/search/apis/ipranges/googlebot.json",
                {"ipv4Prefix", "ipv6Prefix"},
            )
        ],
    }

    datafile = args.datafile
    if datafile.is_file():
        try:
            data = json.loads(datafile.read_text())
        except json.JSONDecodeError as error:
            logging.error("unable to parse current data, deleting: %s", error)
            datafile.unlink()

    session = http_session("dump-cloud-ip-ranges")
    for ipblock_type, entities in providers.items():
        for entity in entities:
            try:
                logging.info("fetching ranges for %s", entity.name)
                old_nets = data.get(ipblock_type, {}).get(entity.name, [])
                nets = sorted(merge_adjacent(entity.get_networks(session)))
                if len(nets) == 0:
                    logging.error("Received 0 nets from %s, not updating", entity.name)
                    runtime_error = True
                    continue
                data.setdefault(ipblock_type, {})[entity.name] = nets
                logging.debug("%s nets: %s", entity.name, data[ipblock_type][entity.name])
                logging.info(
                    "%s new nets: %d, old nets %d",
                    entity.name,
                    len(data[ipblock_type][entity.name]),
                    len(old_nets),
                )
            except RequestException as error:
                logging.error("%s: %s", entity.name, error)
                runtime_error = True

    if args.conftool:
        repo_base = Path(args.repo)
        requestctl_path = repo_base / "requestctl"
        ipblocks_path = requestctl_path / "request-ipblocks"
        git_repo = Repo(repo_base)
        for ipblock_type, ipblocks in data.items():
            (ipblocks_path / ipblock_type).mkdir(exist_ok=True)
            for ipblock_name, cidrs in ipblocks.items():
                name = ipblock_name.lower()
                # Save the data to a file on disk:
                file_path = ipblocks_path / ipblock_type / f"{name}.yaml"
                to_update = {
                    "cidrs": cidrs,
                    "comment": f"Automatically generated IPs for {ipblock_name}",
                }
                file_path.write_text(yaml.dump(to_update, default_flow_style=False))
        # safety measure: if there is an uncommitted object added to the index of the
        # repository, we won't add what follows to git. We will still sync it though.
        if git_repo.index.diff("HEAD"):
            logging.error(
                "The git index of %s is dirty, not adding/committing ipblocks.",
                repo_base,
            )
            runtime_error = True
        else:
            # Add and commit to the private repo if anything
            git_repo.index.add([str(ipblocks_path / ipblock_type) for ipblock_type in data])
            # We check the added stuff to HEAD, so that spurious changes leftover
            # in the repo won't create an issue.
            if git_repo.index.diff("HEAD"):
                git_repo.index.commit(
                    "Automatic commit of cloud IP ranges (dump_cloud_ip_ranges)"
                )
        # now sync it. The fastest way is to just pass an
        # argparse.Namespace to Requestctl.
        try:
            Requestctl(
                reqctl_args(
                    [
                        "-c",
                        "/etc/conftool/config.yaml",
                        "sync",
                        "-g",
                        str(requestctl_path),
                        "ipblock",
                    ]
                )
            ).run()
        except RequestctlError:
            runtime_error = True

    temp_datafile = Path(f"{datafile}.tmp")
    temp_datafile.write_text(json.dumps(data, indent=4, sort_keys=True))
    temp_datafile.rename(datafile)
    return int(runtime_error)


if __name__ == "__main__":
    raise SystemExit(main())
