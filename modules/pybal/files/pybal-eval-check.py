#!/usr/bin/env python
# This is a simple validator for external pybal node
# definition files.  These are loaded and eval'd
# line by line.  A faulty eval will cause issues.
import os
import pwd
import grp
import sys
import socket


def drop_privileges(uid_name='nobody',
                    gid_name='nogroup',
                    umask=077):
    """ Drop privileges
    :param uid_name: str
    :param gid_name: str
    :param gid_name: int (ex: 022)
    :returns: tuple of typles for old and new"""

    begin_uid = os.getuid()
    begin_gid = os.getgid()
    begin_uid_name = pwd.getpwuid(begin_uid)[0]
    safe_uid = pwd.getpwnam(uid_name)[2]
    safe_gid = grp.getgrnam(gid_name)[2]

    os.setgid(safe_gid)
    os.setuid(safe_uid)
    old_umask = os.umask(umask)

    final_uid = os.getuid()
    final_gid = os.getgid()
    return ((begin_uid, begin_gid, oct(old_umask)),
            (final_uid, final_gid, oct(umask)))


def main():

    file = open(sys.argv[1], 'r').read()
    drop_privileges()

    eligible_servers = []
    for l in file.splitlines():

        # this mimics internal pybal behavior
        l = l.rstrip('\n').strip()
        if l.startswith('#') or not l:
            continue

        try:
            server = eval(l)
            assert type(server) == dict
            assert all(map(lambda k: k in server,
                           ['host', 'enabled', 'weight']))
            socket.gethostbyname_ex(server['host'])
            eligible_servers.append(server)
        except Exception as e:
            print 'Error: ', l, e
            sys.exit(1)

    # We assume empty pools are errant
    if not eligible_servers:
        print "Error: server pool cannot be empty!"
        sys.exit(1)

if __name__ == '__main__':
    print main() or 'no issues'
