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

WARN_LEAKS = 3
CRIT_LEAKS = 6


def main():
    try:
        clients = mwopenstackclients.clients('/etc/novaobserver.yaml')
        instances = clients.allinstances(projectid='admin-monitoring')

        if len(instances) >= CRIT_LEAKS:
            print("Nova-fullstack has failed %s times" % len(instances))
            sys.exit(CRITICAL)
        elif len(instances) >= WARN_LEAKS:
            print("Nova-fullstack has failed %s times" % len(instances))
            sys.exit(WARNING)
        else:
            sys.exit(OK)
    except:
        sys.exit(UNKNOWN)


if __name__ == '__main__':
    main()
