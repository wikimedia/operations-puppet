#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Script to download address ranges for various cloud providers and store them in a json file"""
import csv
import json
import logging
import os
import subprocess
import tempfile
import time
import re
from datetime import datetime
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Set

import yaml

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

        JSON_REGEX = r'https://download\.microsoft\.com/download/[^"\']*ServiceTags_Public_\d{8}\.json'  # noqa: E501

        page = session.get(self.url)
        tree = html.fromstring(page.content)

        scripts = tree.xpath('//script')
        urls = []

        for script in scripts:
            script_content = script.text_content() if script.text_content() else ""
            if script_content:
                json_urls = re.findall(JSON_REGEX, script_content)
                urls.extend(json_urls)

        if not urls:
            # Try to use regex if the previoust method failed
            html_page = tree.text_content()
            matches = re.findall(JSON_REGEX, html_page)
            urls.extend(matches)

        if not urls:
            # return empty if nothing found
            return set()

        # Sort by date, as we *should* find at least two urls with
        # ServiceTags_Public_YYYYMMDD.json format
        url_timestamps = []
        for url in urls:
            timestamp = re.search(r'ServiceTags_Public_(\d{8})\.json', url)
            if timestamp:
                ts_str = timestamp.group(1)
                try:
                    date_obj = datetime.strptime(ts_str, '%Y%m%d')
                    url_timestamps.append((url, date_obj))
                except ValueError:
                    continue

        if not url_timestamps:
            return set()

        url_timestamps.sort(key=lambda x: x[1], reverse=True)
        # Pick the most recent one
        download_url = url_timestamps[0][0]

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

        # Use now - 24h as timeframe for obtaining prefixes
        for asn in self.asns:
            data = session.get("https://stat.ripe.net/data/announced-prefixes/data.json?"
                               f"data_overload_limit=ignore&resource=AS{asn}&starttime="
                               f"{int(time.time()-86400)}&min_peers_seeing=10").json()
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
    # If the network subnet is one of the following spurious values,
    # discard it and avoid failures.
    spurious_nets = ["None", "2002::/16"]
    merged = cidr_merge([IPNetwork(net) for net in nets if net not in spurious_nets])
    return {str(net) for net in merged}


def requestctl_apply(slug, data, api_token) -> subprocess.CompletedProcess:
    """Run requestctl apply on the requested ipblock"""
    try:
        tmp = tempfile.NamedTemporaryFile(mode="w+", delete=False)
        yaml.dump(data, tmp)
        cmd = ['/usr/bin/requestctl', 'apply', 'ipblock', slug, '-f', tmp.name]
        result = subprocess.run(
            cmd,
            check=True,
            text=True,
            capture_output=True,
            env={'REQUESTCTL_API_TOKEN': api_token}
        )
        logging.debug("Output of running requestctl apply: %s", result.stdout)
        return result
    finally:
        os.unlink(tmp.name)


def requestctl_fetch_all(api_token) -> subprocess.CompletedProcess:
    """Run requestctl to fetch all ipblock-source data"""
    cmd = ['/usr/bin/requestctl', 'fetch', '--all', '--verbose']
    result = subprocess.run(
        cmd,
        check=True,
        text=True,
        capture_output=True,
        env={'REQUESTCTL_API_TOKEN': api_token}
    )
    logging.debug("Output of running requestctl fetch: %s", result.stdout)
    return result


def requestctl_update_provenance_map(api_token) -> subprocess.CompletedProcess:
    """Run requestctl to commit ipblock map changes"""
    cmd = ['/usr/bin/requestctl', 'update-provenance-map']
    result = subprocess.run(
        cmd,
        check=True,
        text=True,
        capture_output=True,
        env={'REQUESTCTL_API_TOKEN': api_token}
    )
    logging.debug("Output of running requestctl update-provenance-map: %s", result.stdout)
    return result


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
    if args.conftool:
        # We need to have the API token defined, or this won't work
        api_token = os.environ.get('REQUESTCTL_API_TOKEN')
        if api_token is None:
            raise ValueError("Cannot write to conftool without an api token.")

    data = dict()
    runtime_error = False

    providers = {
        "cloud": [
            ExternalCloudVendor(
                "AWS", "https://ip-ranges.amazonaws.com/ip-ranges.json", {"ip_prefix"}
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
            ExternalCloudVendorRIPE(name="Anexia", asns=[42473]),
            ExternalCloudVendorRIPE(name="netcup", asns=[197540, 214996]),
            ExternalCloudVendorRIPE(name="Hetzner", asns=[24940]),
            ExternalCloudVendorRIPE(name="M247", asns=[9009]),
            ExternalCloudVendorRIPE(name="Datacamp", asns=[212238]),
            ExternalCloudVendorRIPE(name="DZCRD", asns=[132817]),
            ExternalCloudVendor(
                name="Vultr",
                url="https://geofeed.constant.com/?json",
                subkeys={"ip_prefix"},
                prefixes="subnets",
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
        api_token = os.environ.get('REQUESTCTL_API_TOKEN', None)
        if api_token is None:
            raise ValueError("you must define the env variable REQUESTCTL_API_TOKEN"
                             " in order to export data to requestctl.")

        for ipblock_type, ipblocks in data.items():
            for ipblock_name, cidrs in ipblocks.items():
                slug = f"{ipblock_type}/{ipblock_name.lower()}"
                to_update = {
                    "cidrs": cidrs,
                    "comment": f"Automatically generated IPs for {ipblock_name}",
                }

                try:
                    logging.info("Updating ipblock@%s", slug)
                    requestctl_apply(slug, to_update, api_token)
                    logging.info("ipblock imported correctly")
                except subprocess.CalledProcessError as error:
                    logging.error("Error updating %s: %s", slug, error)
                    runtime_error = True

        # Update ipblocks from ipblock-source objects
        try:
            logging.info("Fetching all ipblock-source objects")
            requestctl_fetch_all(api_token)
            logging.info("ipblock-source objects fetched correctly")
        except subprocess.CalledProcessError as error:
            logging.error("Error fetching ipblock-source objects: %s", error)
            runtime_error = True

        # Finally, commit the changes to update the provenance map
        try:
            logging.info("Updating provenance map")
            requestctl_update_provenance_map(api_token)
            logging.info("Provenance map updated correctly")
        except subprocess.CalledProcessError as error:
            logging.error("Error updating provenance map: %s", error)
            runtime_error = True

    temp_datafile = Path(f"{datafile}.tmp")
    temp_datafile.write_text(json.dumps(data, indent=4, sort_keys=True))
    temp_datafile.rename(datafile)
    return int(runtime_error)


if __name__ == "__main__":
    raise SystemExit(main())
