#!/usr/bin/python3
"""Script to download addresses anges for various cloud provideres and store them in a json file"""
import csv
import json
import logging

from argparse import ArgumentParser, Namespace
from dataclasses import dataclass, field
from pathlib import Path
from typing import Set

from netaddr import cidr_merge, IPNetwork
from requests import Session
from requests.exceptions import RequestException
from lxml import html
from wmflib.requests import http_session

from conftool import configuration as confctl_cfg
from conftool.kvobject import KVObject
from conftool.loader import Schema


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


class ExternalCloudVendorDigitalOcean:
    """Class to fetch data from  DigitalOcean"""

    name: str = "DigitalOcean"
    # This is the file linked from the digitalocean platform documentation website:
    # https://www.digitalocean.com/docs/platform/
    url: str = "http://digitalocean.com/geo/google.csv"

    def get_networks(self, session: Session) -> Set[str]:
        """Fetch Azure networks

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        ips_request = session.get(self.url, allow_redirects=True)

        ips = csv.DictReader(
            ips_request.content.decode("utf-8").splitlines(),
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
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Configure logging"""
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def setup_conftool() -> Schema:
    """Get a conftool entity class correctly configured."""
    KVObject.setup(confctl_cfg.get("/etc/conftool/config.yaml"))
    schema = Schema.from_file("/etc/conftool/schema.yaml")
    return schema


def main() -> int:
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    data = dict()
    error = False

    providers = [
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
        ExternalCloudVendorDigitalOcean(),
    ]

    datafile = args.datafile
    if datafile.is_file():
        data = json.loads(datafile.read_text())
    session = http_session("dump-cloud-ip-ranges")
    for provider in providers:
        try:
            logging.info("fetching ranges for %s", provider.name)
            old_nets = data.get(provider.name, [])
            nets = list(merge_adjacent(provider.get_networks(session)))
            if len(nets) == 0:
                logging.error("Recived 0 nets from %s, not updating")
                error = True
                continue
            data[provider.name] = nets
            logging.debug("%s nets: %s", provider.name, data[provider.name])
            logging.info(
                "%s new nets: %d, old nets %d",
                provider,
                len(data[provider.name]),
                len(old_nets),
            )
        except RequestException as error:
            logging.error("%s: %s", provider.name, error)
            error = True

    datafile.write_text(json.dumps(data, indent=4, sort_keys=True))
    if args.conftool:
        schema = setup_conftool()
        for cloud_name, cidrs in data.items():
            name = cloud_name.lower()
            obj = schema.entities["request-ipblocks"]("cloud", name)
            # We don't want to mess with conftool-sync that would remove entries
            # not present in conftool-data. Once we have reqctl, we won't need this.
            if not obj.exists:
                logging.warning(
                    "Not importing data for cloud %s, not in conftool. "
                    "Please add it to conftool-data.",
                    name
                )
                error = True
                continue
            obj.update(
                {
                    "cidrs": cidrs,
                    "comment": f"Automatically generated IPs for {cloud_name}",
                }
            )

    return int(error)


if __name__ == "__main__":
    raise SystemExit(main())
