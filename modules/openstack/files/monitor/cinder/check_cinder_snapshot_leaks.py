#!/usr/bin/python3
"""
2022 Andrew Bogott

When our backup tool (wmcs-cinder-volume-backup) is backup up a volume attached
to a VM it first creates a snapshot, then backs up the snapshot.

Then, in theory, it deletes that snapshot.

Various mishaps can cause us to leak snapshots, which eventually fills our
quota and breaks backups.

This script is used to monitor these leaked backups and let someone know
before the problem is too serious.
"""
import sys
import mwopenstackclients

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

WARN_LEAKS = 4
CRIT_LEAKS = 12


def main():
    clients = mwopenstackclients.clients('/etc/novaobserver.yaml')
    cinder = clients.cinderclient(project='admin')
    snaps = cinder.volume_snapshots.list()

    print("%s snaps in the admin project" % len(snaps))
    if len(snaps) >= CRIT_LEAKS:
        sys.exit(CRITICAL)
    elif len(snaps) >= WARN_LEAKS:
        sys.exit(WARNING)

    sys.exit(OK)


if __name__ == '__main__':
    main()
