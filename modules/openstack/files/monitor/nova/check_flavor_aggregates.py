#!/usr/bin/python3

"""
2020 Andrew Bogott

Check that every nova flavor has aggregate_instance_extra_specs set.
Without this, a flavor can be scheduler anywhere, including
on VMs that are marked as spare, maintenance, etc.

We'll raise a warning if any flavors aren't associated
with an aggregate.
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
            for key in flavor.get_keys():
                if key.startswith("aggregate_instance_extra_specs"):
                    orphan_flavors.remove(flavor.name)
                    break

    if orphan_flavors:
        return (
            WARNING,
            "Some flavors are not assigned to aggregates: " + ", ".join(orphan_flavors),
        )

    return OK, "All flavors are assigned to aggregates"


def main():
    state, text = check_flavors()
    print(text)

    sys.exit(state)


if __name__ == "__main__":
    main()
