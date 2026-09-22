#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
This script displays a mapping of ceph OSD ids to physical controller/enclosure/slot.
It shoud be used in case of a failing OSD, to indicate to DC-Ops which physical disk needs
to be replaced.

"""

import argparse
import json
import re
import subprocess
from dataclasses import dataclass
from typing import Any


@dataclass
class PerccliDisk:
    controller: str
    enclosure: str
    slot: str
    interface: str
    medium: str
    serial: str
    wwn: str
    raw: dict[str, Any]

    @property
    def location(self) -> str:
        return f"c{self.controller}/e{self.enclosure}/s{self.slot}"

    @property
    def kernel_wwn(self) -> str:
        """
        Reproduce the transformation performed by Puppet.

        Puppet does:

            SATA       + 0
            SAS SSD    + 1
            SAS HDD    + 3
        """
        interface = self.interface.upper()
        medium = self.medium.upper()
        shift = 0
        if interface == "SAS":
            if medium == "SSD":
                shift = 1
            elif medium == "HDD":
                shift = 3

        return f"{int(self.wwn, 16) + shift:016X}"


@dataclass
class Osd:
    osd_id: str
    device: str
    kernel_wwn: str
    perccli: PerccliDisk | None = None


def run_command(command: list[str]) -> str:
    result = subprocess.run(
        command,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    return result.stdout


def get_ceph_osds() -> list[tuple[str, str]]:
    """
    Get all OSDs and their physical block devices from ceph-volume.

    Returns:
        [
            ("0", "/dev/sda"),
            ("1", "/dev/sdb"),
            ...
        ]
    """

    output = run_command(
        [
            "ceph-volume",
            "lvm",
            "list",
            "--format",
            "json",
        ]
    )

    data = json.loads(output)
    osds = []
    for osd_id, entries in data.items():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                continue

            # We want the block LV, not the DB LV.
            if entry.get("type") != "block":
                continue

            devices = entry.get("devices")
            if not devices:
                continue

            if isinstance(devices, str):
                devices = [devices]

            for device in devices:
                # We only want actual physical /dev/sdX devices.
                if re.fullmatch(r"/dev/sd[a-z]+", device):
                    osds.append(
                        (
                            str(osd_id),
                            device,
                        )
                    )

    return sorted(
        osds,
        key=lambda item: int(item[0]),
    )


def get_kernel_wwn(device: str) -> str | None:
    """
    Obtain ID_WWN from udev for /dev/sdX.
    """

    output = run_command(
        [
            "udevadm",
            "info",
            "--query=property",
            "--name",
            device,
        ]
    )

    for line in output.splitlines():

        if line.startswith("ID_WWN="):
            wwn = line.split("=", 1)[1]
            wwn = re.sub(
                r"^0x",
                "",
                wwn,
                flags=re.IGNORECASE,
            )

            return wwn.upper()

    return None


def get_perccli_disks() -> list[PerccliDisk]:
    """
    Parse:

        perccli64 /call show all J
    """

    output = run_command(
        [
            "perccli64",
            "/call",
            "show",
            "all",
            "J",
        ]
    )

    data = json.loads(output)

    disks = []

    for controller in data.get("Controllers", []):

        response = controller.get("Response Data", {})

        physical_devices = response.get(
            "Physical Device Information",
            {},
        )

        for key, value in physical_devices.items():

            match = re.fullmatch(
                r"Drive /c(\d+)/e(\d+)/s(\d+) - Detailed Information",
                key,
            )

            if not match:
                continue

            controller_id = match.group(1)
            enclosure = match.group(2)
            slot = match.group(3)

            if not isinstance(value, dict):
                continue

            device_attributes = value.get(
                f"Drive /c{controller_id}" f"/e{enclosure}/s{slot} Device attributes",
                {},
            )

            if not device_attributes:
                for attr_key, attr_value in value.items():
                    if "Device attributes" in attr_key:
                        device_attributes = attr_value
                        break

            if not isinstance(device_attributes, dict):
                continue

            # Find the corresponding summary entry to get Intf/Med.
            summary_key = f"Drive /c{controller_id}" f"/e{enclosure}/s{slot}"
            summary = physical_devices.get(summary_key, [])
            interface = ""
            medium = ""

            if isinstance(summary, list) and summary:
                interface = str(summary[0].get("Intf", ""))
                medium = str(summary[0].get("Med", ""))

            serial = str(device_attributes.get("SN", ""))
            wwn = normalize_wwn(device_attributes.get("WWN", ""))

            if not wwn:
                continue

            disks.append(
                PerccliDisk(
                    controller=controller_id,
                    enclosure=enclosure,
                    slot=slot,
                    interface=interface,
                    medium=medium,
                    serial=serial,
                    wwn=wwn,
                    raw={
                        "summary": summary,
                        "details": value,
                    },
                )
            )

    return disks


def normalize_wwn(value: Any) -> str:
    """
    Normalize a WWN to:

        5000C500D9BB6978
    """

    if value is None:
        return ""

    value = str(value).strip()
    value = re.sub(
        r"^0x",
        "",
        value,
        flags=re.IGNORECASE,
    )
    value = value.replace(":", "")
    value = value.replace("-", "")
    return value.upper()


def build_wwn_index(
    disks: list[PerccliDisk],
) -> dict[str, PerccliDisk]:
    """
    Build:

        kernel WWN -> perccli disk

    by reproducing the Puppet transformation.
    """

    index = {}
    for disk in disks:
        index[disk.kernel_wwn] = disk
    return index


def map_osd(
    osd_id: str,
    device: str,
    wwn_index: dict[str, PerccliDisk],
) -> Osd:

    kernel_wwn = get_kernel_wwn(device)

    if not kernel_wwn:
        return Osd(
            osd_id=osd_id,
            device=device,
            kernel_wwn="NOT FOUND",
            perccli=None,
        )

    disk = wwn_index.get(kernel_wwn)

    return Osd(
        osd_id=osd_id,
        device=device,
        kernel_wwn=kernel_wwn,
        perccli=disk,
    )


def print_table(osds: list[Osd]) -> None:

    headers = [
        "OSD",
        "DEVICE",
        "ID_WWN",
        "PERC_WWN",
        "INTF",
        "MEDIUM",
        "SERIAL",
        "LOCATION",
    ]

    rows = []
    for osd in osds:
        if osd.perccli:
            disk = osd.perccli
            rows.append(
                [
                    f"osd.{osd.osd_id}",
                    osd.device,
                    osd.kernel_wwn,
                    disk.wwn,
                    disk.interface,
                    disk.medium,
                    disk.serial,
                    disk.location,
                ]
            )
        else:
            rows.append(
                [
                    f"osd.{osd.osd_id}",
                    osd.device,
                    osd.kernel_wwn,
                    "-",
                    "-",
                    "-",
                    "-",
                    "NOT FOUND",
                ]
            )

    if not rows:
        print("No OSDs found.")
        return

    widths = []

    for column in range(len(headers)):
        widths.append(
            max(
                len(headers[column]),
                *[len(row[column]) for row in rows],
            )
        )

    def format_row(row):
        return "  ".join(value.ljust(widths[i]) for i, value in enumerate(row))

    print(format_row(headers))
    print("  ".join("-" * width for width in widths))

    for row in rows:
        print(format_row(row))


def print_json(osds: list[Osd]) -> None:

    output = []
    for osd in osds:
        item = {
            "osd": f"osd.{osd.osd_id}",
            "device": osd.device,
            "id_wwn": osd.kernel_wwn,
        }
        if osd.perccli:
            disk = osd.perccli
            item["perccli"] = {
                "controller": disk.controller,
                "enclosure": disk.enclosure,
                "slot": disk.slot,
                "location": disk.location,
                "interface": disk.interface,
                "medium": disk.medium,
                "serial": disk.serial,
                "wwn": disk.wwn,
                "kernel_wwn": disk.kernel_wwn,
            }

        else:
            item["perccli"] = None

        output.append(item)

    print(
        json.dumps(
            output,
            indent=2,
        )
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    osds = get_ceph_osds()
    disks = get_perccli_disks()
    wwn_index = build_wwn_index(disks)
    results = [
        map_osd(
            osd_id,
            device,
            wwn_index,
        )
        for osd_id, device in osds
    ]
    if args.json:
        print_json(results)
    else:
        print_table(results)


if __name__ == "__main__":
    main()
