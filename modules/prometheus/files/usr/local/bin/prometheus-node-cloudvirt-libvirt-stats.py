#!/usr/bin/env python3
import logging
import socket
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple, Union

import click
import libvirt
from lxml import etree

STATS_PREFIX = "node_nova_libvirt_"


class BadNovaMetadata(Exception):
    pass


@dataclass(frozen=True)
class PromStat:
    name: str
    tags: Dict[str, str]
    value: int

    def __str__(self):
        tags = ",".join(f'{name}="{value}"' for name, value in self.tags.items())
        return f"{STATS_PREFIX}{self.name}{{{tags}}} {self.value}"


@dataclass(frozen=True)
class NovaInfo:
    vm_name: str
    project: str

    @classmethod
    def from_xml_string(cls, xml_string: str) -> "NovaInfo":
        """

        Sometimes the owner metadata has no text value, but always has a property uuid.
        Example:
            <owner>
                ...
                <project uuid="tools">N/A</project>
            </owner>
        Other times it has text also:
            <owner>
                ...
                <project uuid="analytics">analytics</project>
            </owner>

        Prefer the uuid.
        """
        xml_nova_metadata = etree.fromstring(xml_string)
        return cls(
            vm_name=xml_nova_metadata.find("name").text,
            project=xml_nova_metadata.find("owner/project").attrib["uuid"],
        )


LOGGER = logging.getLogger(name=__name__)


def _parse_libvirt_block_or_net_stat_to_prom(
    hypervisor: str,
    domain_name: str,
    vm_name: str,
    project: str,
    stat_name: str,
    stat_value: int,
    other_stats: Dict[str, Union[int, str]],
) -> Optional[PromStat]:
    """
    Example of the stats given by libvirt:

    'block.count': 1,
    'block.0.name': 'vda',
    'block.0.backingIndex': 1,
    'block.0.rd.reqs': 2568643,
    'block.0.rd.bytes': 52688131072,
    'block.0.rd.times': 7134942405668,
    'block.0.wr.reqs': 4392683,
    'block.0.wr.bytes': 343622012928,
    'block.0.wr.times': 41463553113842,
    'block.0.fl.reqs': 1392797,
    'block.0.fl.times': 7853036221019,
    'block.0.allocation': 20935553536,
    'block.0.capacity': 85899345920,
    'block.0.physical': 85899345920,
    'net.count': 1,
    'net.0.name': 'tapd8dd4578-60',
    'net.0.rx.bytes': 4041206669,
    'net.0.rx.pkts': 31734228,
    'net.0.rx.errs': 0,
    'net.0.rx.drop': 0,
    'net.0.tx.bytes': 3662197262,
    'net.0.tx.pkts': 2316678,
    'net.0.tx.errs': 0,
    'net.0.tx.drop': 140997,
    """
    tags = {
        "hypervisor": hypervisor,
        "domain_name": domain_name,
        "project": project,
        "vm_name": vm_name,
    }
    tags_values = stat_name.split(".")[1:]
    base_prom_name = stat_name.split(".", 1)[0]
    if tags_values[0] == "count":
        prom_name = f"{base_prom_name}_count"
        return PromStat(name=prom_name, tags=tags, value=stat_value)

    if tags_values[1] == "name":
        # ignore non-numeric stats for now
        return None

    dev_index = tags_values[0]
    dev_name = other_stats[f"{base_prom_name}.{dev_index}.name"]
    tags.update(
        {
            f"{base_prom_name}_index": dev_index,
            f"{base_prom_name}_name": dev_name,
        }
    )
    if len(tags_values) == 2:
        # block.0.backingIndex or similar
        prom_name = f"{base_prom_name}_{tags_values[1]}"

    else:
        # block.0.rd.bytes or similar (with rd/fl/wr)
        prom_name = stat_name.split(".", 1)[0]
        tags.update(
            {
                "operation": tags_values[1],
                "type": tags_values[2],
            }
        )

    return PromStat(name=prom_name, tags=tags, value=stat_value)


def parse_stats(
    libvirt_stats: Dict[str, Union[int, str]],
    libvirt_nova_info: NovaInfo,
    hypervisor: str,
    domain_name: str,
) -> List[str]:
    prom_stats: List[str] = []
    for stat_name, stat_value in libvirt_stats.items():
        # currently only net and block are interesting
        if stat_name.startswith("net.") or stat_name.startswith("block."):
            stat = _parse_libvirt_block_or_net_stat_to_prom(
                domain_name=domain_name,
                stat_name=stat_name,
                stat_value=stat_value,
                hypervisor=hypervisor,
                project=libvirt_nova_info.project,
                vm_name=libvirt_nova_info.vm_name,
                other_stats=libvirt_stats,
            )
            if stat:
                prom_stats.append(stat)

    return prom_stats


def get_domain_stats() -> Dict[str, Tuple[libvirt.virDomain, Dict[str, Any]]]:
    conn = libvirt.openReadOnly()
    return conn.getAllDomainStats()


def get_nova_info(domain: libvirt.virDomain) -> NovaInfo:
    # Recently created VMs have their data under version 1.1, older ones under 1.0.
    # metadata() raises an exception if it doesn't find the requested key.
    try:
        raw_nova_metadata = domain.metadata(
            libvirt.VIR_DOMAIN_METADATA_ELEMENT, "http://openstack.org/xmlns/libvirt/nova/1.1"
        )
    except libvirt.libvirtError:
        raw_nova_metadata = domain.metadata(
            libvirt.VIR_DOMAIN_METADATA_ELEMENT, "http://openstack.org/xmlns/libvirt/nova/1.0"
        )
    try:
        return NovaInfo.from_xml_string(xml_string=raw_nova_metadata)
    except Exception as error:
        raise BadNovaMetadata(
            f"Unable to get nova metadata from domain metadata:\n{raw_nova_metadata}"
        ) from error


def get_libvirt_stats() -> Dict[str, Dict[str, int]]:
    hypervisor = socket.gethostname()
    domains_stats = get_domain_stats()
    stats: List[PromStat] = []
    for domain, domain_stats in domains_stats:
        nova_info = get_nova_info(domain=domain)
        stats.extend(
            parse_stats(
                domain_name=domain.name(),
                libvirt_stats=domain_stats,
                libvirt_nova_info=nova_info,
                hypervisor=hypervisor,
            )
        )

    return stats


@click.command()
@click.option("-v", "--verbose", is_flag=True)
def main(verbose: bool) -> None:
    # This avoids libvirt from internally printing to stdout when an exception
    # happens
    def libvirt_callback(userdata, err):
        pass

    libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)

    logging.basicConfig(level=logging.DEBUG if verbose else logging.INFO)
    stats = get_libvirt_stats()
    click.echo("\n".join(str(stat) for stat in stats))


if __name__ == "__main__":
    main()
