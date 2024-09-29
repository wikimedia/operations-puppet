#!/usr/bin/python3
# This is a simple validator for external pybal node
# definition files.  These are loaded and eval'd
# line by line.  A faulty eval will cause issues.
import os
import pwd
import grp
import sys
import socket


def die(msg):
    error = "[invalid]: %s" % (msg,)
    print(error, file=sys.stderr)
    sys.exit(1)


def drop_privileges(uid_name='nobody',
                    gid_name='nogroup',
                    umask=0o77):
    """ Drop privileges
    :param uid_name: str
    :param gid_name: str
    :param gid_name: int (ex: 022)
    :returns: tuple of typles for old and new"""

    begin_uid = os.getuid()
    begin_gid = os.getgid()
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

    with open(sys.argv[1], 'r') as f:
        clines = f.read()
    drop_privileges()

    eligible_servers = []
    for line in clines.splitlines():

        # this mimics internal pybal behavior
        line = line.rstrip('\n').strip()
        if line.startswith('#') or not line:
            continue

        try:
            server = eval(line)
            assert type(server) is dict
            assert all(map(lambda k: k in server,
                           ['host', 'enabled', 'weight']))
            socket.gethostbyname_ex(server['host'])
            eligible_servers.append(server)
        except Exception as e:
            die('%s %s' % (line, e))

    # We assume empty pools are errant
    if not eligible_servers:
        die("server pool cannot be empty!")


if __name__ == '__main__':
    print(main() or 'no issues')
