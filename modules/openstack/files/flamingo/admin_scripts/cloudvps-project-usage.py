#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path
import sys

import mwopenstackclients
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile


osclients = mwopenstackclients.clients(oscloud="novaobserver")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export openstack resource use, split out by project"
    )
    parser.add_argument(
        "--outfile",
        type=Path,
        default=Path("/var/lib/prometheus/node.d/openstack_project_usage.prom"),
        help="Output file (e.g., /var/lib/prometheus/node.d/openstack_project_usage.prom)",
    )
    return parser.parse_args()


def export_project_usage_metrics(registry: CollectorRegistry):
    vcpu_gauge = Gauge(
        "project_usage_vcpu_count",
        "Number of vcpus used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    ram_gauge = Gauge(
        "project_usage_ram_gb",
        "GB of RAM used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    instance_gauge = Gauge(
        "project_usage_instance_count",
        "Number of instances used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    ephemeral_gauge = Gauge(
        "project_usage_ephemeral_gb",
        "GB of ephemeral storage used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    disk_gauge = Gauge(
        "project_usage_disk_gb",
        "GB of root storage used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    cinder_gauge = Gauge(
        "project_usage_cinder_gb",
        "GB of cinder storage used by the project",
        labelnames=["project"],
        namespace="openstack",
        registry=registry,
    )
    flavor_gauge = Gauge(
        "project_usage_instance_flavor_count",
        "Number of instances per flavor",
        labelnames=["project", "flavor"],
        namespace="openstack",
        registry=registry,
    )

    for project in osclients.allprojects():
        project_id = project.id
        project_name = project.name
        novaclient = osclients.novaclient(project=project_id)
        project_flavors = novaclient.flavors.list()
        flavor_dict = {flavor.id: flavor for flavor in project_flavors}

        instances = 0
        vcpus = 0
        ram = 0
        disk = 0
        ephemeral_disk = 0
        cinder_gb = 0
        flavor_count = {}

        for instance in osclients.allinstances(projectid=project_id):
            if instance.flavor["id"] not in flavor_dict:
                flavor_count["unknown"] = flavor_count.get("unknown", 0) + 1
                print(
                    "Unknown flavor %s for instance %s"
                    % (instance.flavor["id"], instance.name)
                )
                continue
            instance_flavor = flavor_dict[instance.flavor["id"]]
            flavor_count[instance_flavor.name] = (
                flavor_count.get(instance_flavor.name, 0) + 1
            )
            vcpus += instance_flavor.vcpus
            ram += instance_flavor.ram
            disk += instance_flavor.disk
            instances += 1
            ephemeral_disk += instance_flavor._info["OS-FLV-EXT-DATA:ephemeral"]

        for volume in osclients.allvolumes(projectid=project_id):
            cinder_gb += volume.size

        vcpu_gauge.labels(project_name).set(vcpus)
        ram_gauge.labels(project_name).set(int(ram / 1024))
        disk_gauge.labels(project_name).set(disk)
        ephemeral_gauge.labels(project_name).set(ephemeral_disk)
        instance_gauge.labels(project_name).set(instances)
        cinder_gauge.labels(project_name).set(cinder_gb)
        for flavor_name in flavor_count:
            flavor_gauge.labels(project_name, flavor_name).set(
                flavor_count[flavor_name]
            )


def main() -> int:
    args = parse_args()

    registry = CollectorRegistry()

    export_project_usage_metrics(registry)
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    sys.exit(main())
