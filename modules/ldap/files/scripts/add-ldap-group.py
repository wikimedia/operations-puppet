#!/usr/bin/python
import grp
import pwd
import sys
import traceback
from optparse import OptionParser

import ldapsupportlib

try:
    import ldap
    import ldap.modlist
except ImportError:
    sys.stderr.write("Unable to import LDAP library.\n")
    sys.exit(1)


def main():
    parser = OptionParser(conflict_handler="resolve")
    parser.set_usage('add-ldap-group [options] <groupname>\nexample: add-ldap-group wikidev')

    ldap_support_lib = ldapsupportlib.LDAPSupportLib()
    ldap_support_lib.addParserOptions(parser, "scriptuser")

    parser.add_option("-m", "--directorymanager", action="store_true", dest="directorymanager",
                      help="Use the Directory Manager's credentials, rather than your own")
    parser.add_option("--gid", action="store", dest="gid_number",
                      help="The group's gid (default: next available gid)")
    parser.add_option("--members", action="store", dest="members",
                      help="A comma separated list of group members to add to this group")
    (options, args) = parser.parse_args()

    if len(args) != 1:
        parser.error("add-ldap-group expects exactly one argument.")

    ldap_support_lib.setBindInfoByOptions(options, parser)

    base = ldap_support_lib.getBase()

    ds = ldap_support_lib.connect()

    # w00t We're in!
    try:
        groupname = args[0]

        dn = 'cn=' + groupname + ',ou=groups,' + base
        cn = groupname
        object_classes = ['posixGroup', 'groupOfNames', 'top']
        if options.gid_number:
            try:
                grp.getgrgid(options.gid_number)
                raise ldap.TYPE_OR_VALUE_EXISTS()
            except KeyError:
                gid_number = options.gid_number
        else:
            # Find the next gid
            # TODO: make this use LDAP calls instead of getent
            gids = []
            for group in grp.getgrall():
                tmpgid = group[2]
                if tmpgid < 50000:
                    gids.append(group[2])
            gids.sort()
            gid_number = gids.pop()
            gid_number = str(gid_number + 1)

        members = []
        if options.members:
            raw_members = options.members.split(',')
            for raw_member in raw_members:
                try:
                    # Ensure the user exists
                    # TODO: make this use LDAP calls instead of getent
                    pwd.getpwnam(raw_member)

                    # member expects DNs
                    members.append('uid=' + raw_member + ',ou=people,' + base)
                except KeyError:
                    sys.stderr.write(
                        raw_member + " doesn't exist, and won't be added to the group.\n")

        group_entry = {}
        group_entry['objectclass'] = object_classes
        group_entry['gidNumber'] = gid_number
        group_entry['cn'] = cn
        if members:
            group_entry['member'] = members

        modlist = ldap.modlist.addModlist(group_entry)
        ds.add_s(dn, modlist)
    except ldap.UNWILLING_TO_PERFORM as msg:
        sys.stderr.write("LDAP was unwilling to create the group. Error was: %s\n" % msg[0]["info"])
        ds.unbind()
        sys.exit(1)
    except ldap.TYPE_OR_VALUE_EXISTS:
        sys.stderr.write("The group or gid you are trying to add already exists.\n")
        traceback.print_exc(file=sys.stderr)
        ds.unbind()
        sys.exit(1)
    except ldap.PROTOCOL_ERROR:
        sys.stderr.write("There was an LDAP protocol error; see traceback.\n")
        traceback.print_exc(file=sys.stderr)
        ds.unbind()
        sys.exit(1)
    except Exception:
        try:
            sys.stderr.write("There was a general error, this is unexpected; see traceback.\n")
            traceback.print_exc(file=sys.stderr)
            ds.unbind()
        except Exception:
            sys.stderr.write("Also failed to unbind.\n")
            traceback.print_exc(file=sys.stderr)
        sys.exit(1)

    ds.unbind()
    sys.exit(0)


if __name__ == "__main__":
    main()
