#!/usr/bin/python
"""
2019 Andrew Bogott

When the nova-fullstack test fails, an instance is leaked in the
admin_monitoring project.  This monitors the number of leaks
and warns if leaks are piling up.

"""
import sys
import mwopenstackclients

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

WARN_LEAKS = 4
CRIT_LEAKS = 6


def main():
    clients = mwopenstackclients.clients('/etc/novaobserver.yaml')
    instances = clients.allinstances(projectid='admin-monitoring')

    print("%s instances in the admin-monitoring project" % len(instances))
    if len(instances) >= CRIT_LEAKS:
        sys.exit(CRITICAL)
    elif len(instances) >= WARN_LEAKS:
        sys.exit(WARNING)

    sys.exit(OK)


if __name__ == '__main__':
    main()
