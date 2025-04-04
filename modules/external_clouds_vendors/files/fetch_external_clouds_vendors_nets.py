#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Script to download address ranges for various cloud providers and store them in a json file"""
import csv
import json
import logging
import time
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Set

from conftool.extensions.reqconfig import (
    api,
    RequestctlError,
)
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
    url: str = "https://www.microsoft.com/en-us/download/details.aspx?id=56519"

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
            "//a[contains(@class, 'download-btn') and "
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
class ExternalCloudVendorRIPE:
    """Class to fetch data from RIPE APIs to get all prefixes of a given ASN."""

    name: str
    asns: List[int]

    def get_networks(self, session: Session) -> Set[str]:
        """Fetch networks from RIPE

        Arguments:
            session: A request session to use for fetching data

        Returns:
            set[str]: A set of network prefixes
        """
        nets = set()
        for asn in self.asns:
            data = session.get("https://stat.ripe.net/data/announced-prefixes/data.json?"
                               f"data_overload_limit=ignore&resource=AS{asn}&starttime="
                               f"{int(time.time())}&min_peers_seeing=10").json()
            nets |= {prefix["prefix"] for prefix in data["data"]["prefixes"]}

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
            ExternalCloudVendorRIPE(name="Belcloud", asns=[44901]),
            ExternalCloudVendorRIPE(name="Alibaba", asns=[45102]),
            ExternalCloudVendorRIPE(name="Huawei", asns=[136907]),
            ExternalCloudVendorRIPE(name="Tencent", asns=[132203]),
            ExternalCloudVendorRIPE(name="Byteplus", asns=[150436]),
            ExternalCloudVendorRIPE(name="GeekyWorks", asns=[203999]),
            ExternalCloudVendorRIPE(name="Anexia", asns=[42473]),
            ExternalCloudVendorRIPE(name="netcup", asns=[197540, 214996]),
            ExternalCloudVendorRIPE(name="Hetzner", asns=[24940]),
            ExternalCloudVendor(
                name="Vultr",
                url="https://geofeed.constant.com/?json",
                subkeys={"ip_prefix"},
                prefixes="subnets",
            ),
        ],
        "known-clients": [
            ExternalCloudVendor(
                "Googlebot",
                # https://developers.google.com/search/docs/advanced/crawling/verifying-googlebot
                "https://developers.google.com/search/apis/ipranges/googlebot.json",
                {"ipv4Prefix", "ipv6Prefix"},
            ),
            ExternalCloudVendor(
                 "Google-SpecialCaseCrawlers",
                 # https://developers.google.com/search/docs/crawling-indexing/google-special-case-crawlers
                 "https://developers.google.com/static/search/apis/ipranges/special-crawlers.json",
                 {"ipv4Prefix", "ipv6Prefix"},
            ),
            ExternalCloudVendor(
                "OpenAI-SearchBot",
                "https://openai.com/searchbot.json",
                {"ipv4Prefix", "ipv6Prefix"},
            ),
            ExternalCloudVendor(
                "OpenAI-ChatGPT-user",
                "https://openai.com/chatgpt-user.json",
                {"ipv4Prefix", "ipv6Prefix"},
            ),
            ExternalCloudVendor(
                "OpenAI-GPTBot",
                "https://openai.com/gptbot.json",
                {"ipv4Prefix", "ipv6Prefix"},
            ),
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
        req_api = api.RequestctlApi(api.client(config="/etc/conftool/config.yaml"))
        for ipblock_type, ipblocks in data.items():
            for ipblock_name, cidrs in ipblocks.items():
                slug = f"{ipblock_type}/{ipblock_name.lower()}"
                try:
                    logging.info("Updating ipblock@%s", slug)
                    entity = req_api.get("ipblock", slug)
                    to_update = {
                        "cidrs": cidrs,
                        "comment": f"Automatically generated IPs for {ipblock_name}",
                    }
                    req_api.write(entity, to_update)
                except RequestctlError as error:
                    logging.error("Error updating %s: %s", slug, error)
                    runtime_error = True

    temp_datafile = Path(f"{datafile}.tmp")
    temp_datafile.write_text(json.dumps(data, indent=4, sort_keys=True))
    temp_datafile.rename(datafile)
    return int(runtime_error)


if __name__ == "__main__":
    raise SystemExit(main())
