#!/usr/bin/python3

"""
2020 Andrew Bogott

Check that every nova flavor has aggregate_instance_extra_specs set.
Without this, a flavor can be scheduler anywhere, including
on VMs that are marked as spare, maintenance, etc.

If a flavor is in the 'ceph' aggregate, make sure it has
IO throttling set.

Return 'critical' for any flavors that don't have the required
properties.
"""
import sys

import mwopenstackclients

SpecialProjects = ["admin", "wmflabsdotorg", "cloudinfra"]

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def check_flavors():
    orphan_flavors = []
    ceph_flavors_without_bytes_sec = []
    ceph_flavors_without_iops_sec = []

    clients = mwopenstackclients.clients("/etc/novaobserver.yaml")
    allprojects = clients.allprojects()
    allprojectslist = [project.name for project in allprojects]

    # these will always be weird; don't check them
    for project in SpecialProjects:
        allprojectslist.remove(project)

    for project in allprojectslist:
        novaclient = clients.novaclient(project)
        flavors = novaclient.flavors.list()
        for flavor in flavors:
            orphan_flavors.append(flavor.name)
            keys = flavor.get_keys()
            for key in keys:
                if key.startswith("aggregate_instance_extra_specs"):
                    orphan_flavors.remove(flavor.name)
                    if "ceph" in key:
                        # Make sure this is throttled properly
                        ceph_flavors_without_bytes_sec.append(flavor.name)
                        ceph_flavors_without_iops_sec.append(flavor.name)
                        for throttlekey in keys:
                            if throttlekey.startswith("quota:disk_total_bytes_sec"):
                                ceph_flavors_without_bytes_sec.remove(flavor.name)
                            elif throttlekey.startswith("quota:disk_total_iops_sec"):
                                ceph_flavors_without_iops_sec.remove(flavor.name)

                    break

    errstring = ""
    if orphan_flavors:
        errstring += (
            "Some flavors are not assigned to aggregates: "
            + ", ".join(orphan_flavors)
            + "\n"
        )
    if ceph_flavors_without_bytes_sec:
        errstring += (
            "Some ceph flavors lack quota:disk_total_bytes_sec: "
            + ", ".join(ceph_flavors_without_bytes_sec)
            + "\n"
        )
    if ceph_flavors_without_iops_sec:
        errstring += (
            "Some ceph flavors lack quota:disk_total_iops_sec: "
            + ", ".join(ceph_flavors_without_iops_sec)
            + "\n"
        )

    if errstring:
        return (CRITICAL, errstring)

    return OK, "All flavors are assigned to aggregates"


def main():
    state, text = check_flavors()
    print(text)

    sys.exit(state)


if __name__ == "__main__":
    main()
