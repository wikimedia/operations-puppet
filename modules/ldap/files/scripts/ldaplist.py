#!/usr/bin/python
import ldapsupportlib
from optparse import OptionParser
import re
from signal import signal, SIGPIPE, SIG_DFL
import sys

try:
    import ldap
except ImportError:
    sys.stderr.write("Unable to import LDAP library.\n")
    sys.exit(1)

# Avoid "IOError: [Errno 32] Broken pipe" when piping to head & Co.
signal(SIGPIPE, SIG_DFL)


def main():
    "An application that implements the functionality of Solaris's ldaplist."

    print '\033[91m'
    print 'If you are still relying on ldaplist and not using ldapsearch,'
    print 'please comment on https://phabricator.wikimedia.org/T114063'
    print 'before 30 August 2016. If nobody comments, ldaplist will be removed!'
    print '\033[0m'
    parser = OptionParser(conflict_handler="resolve")
    parser.set_usage(
        "ldaplist [options] [database] [object-name]\n\nexample: ldaplist -l passwd ldap_user")

    ldap_support_lib = ldapsupportlib.LDAPSupportLib()
    ldap_support_lib.addParserOptions(parser)

    parser.add_option("-v", "--verbose", action="store_true", dest="verbose",
                      help="Show the database and search filter used for this search")
    parser.add_option("-l", "--longlisting", action="store_true", dest="longlisting",
                      help=('List all the attributes for each entry matching the search',
                            ' criteria.  By default, ldaplist lists only the Distinguished',
                            ' Name of the entries found.'))
    parser.add_option("-h", action="store_true", dest="helpme",
                      help="Show available databases to search")
    parser.add_option("-d", "--showdatabase", action="store_true", dest="showdatabase",
                      help="Show the base dn being used for this database")
    parser.add_option("-a", "--showattributes", dest="showattributes",
                      help="Show the given attributes")
    parser.add_option("-r", "--recursive", action="store_true", dest="recursive",
                      help="Recurse netgroups")
    parser.add_option("--like", action="store_true", dest="like",
                      help="Search for objects that equal or sound like [object-name]")
    (options, args) = parser.parse_args()

    ldap_support_lib.setBindInfoByOptions(options, parser)

    base = ldap_support_lib.getBase()

    objectbasedns = {"base": base,
                     "passwd": "ou=people," + base,
                     "group": "ou=groups," + base,
                     "netgroup": "ou=netgroup," + base,
                     "automount": base,
                     "auto_*": "nisMapName=auto_AUTO," + base,
                     "uids": "ou=uids," + base,
                     "servicegroups": "ou=servicegroups," + base,
                     "projects": "ou=projects," + base,
                     "projectroles": "ou=projects," + base}
    objectdefaulttypes = {"base": "none",
                          "passwd": "uid",
                          "group": "cn",
                          "netgroup": "cn",
                          "automount": "nisMapName",
                          "auto_*": "cn",
                          "uids": "cn",
                          "servicegroups": "cn",
                          "projects": "cn",
                          "projectroles": "cn:dn:"}
    objectobjectclasses = {"base": "none",
                           "passwd": "posixaccount",
                           "group": "posixgroup",
                           "netgroup": "nisNetGroup",
                           "automount": "nisMap",
                           "auto_*": "nisObject",
                           "uids": "inetOrgPerson",
                           "servicegroups": "posixgroup",
                           "projects": "groupofnames",
                           "projectroles": "organizationalrole"}

    if options.showdatabase:
        showdatabase(objectbasedns, args)
        sys.exit()

    if options.helpme:
        print ""
        print 'database'.ljust(17) + 'default type'.ljust(20) + 'objectclass'
        print '============='.ljust(17) + '================='.ljust(20) + '============='

        for a, b, c in zip(objectbasedns.keys(),
                           objectdefaulttypes.values(),
                           objectobjectclasses.values()):
            print '%s%s%s' % (a.ljust(17), b.ljust(20), c)
        sys.exit()

    if len(args) >= 1:
        if args[0].find('auto_') != -1:
            objectbasedns["auto_*"] = objectbasedns["auto_*"].replace("auto_AUTO", args[0])
            # searchkeysave = args[0]
            args[0] = "auto_*"
        if args[0] in objectbasedns:
            database = args[0]
            base = objectbasedns[args[0]]
            objectclass = objectobjectclasses[args[0]]
            attribute = objectdefaulttypes[args[0]]
            if len(args) > 1:
                searchlist = args
                del searchlist[0]
                first = True
                for key in searchlist:
                    if first is True:
                        searchkey = key
                        first = False
                    else:
                        searchkey = searchkey + " " + key
            # elif args[0] == "auto_*":
                # searchkey = searchkeysave
            else:
                searchkey = "*"
        else:
            print('The database you selected does not exist. Please use ',
                  '"ldaplist -h" to see available databases.')
            sys.exit(1)
    else:
        database = "base"
        objectclass = "*"
        attribute = ""

    ds = ldap_support_lib.connect()

    # w00t We're in!
    try:
        if database == "uids":
            options.like = True
            if options.showattributes is not None:
                options.showattributes += " cn uid departmentNumber employeeType seeAlso"
            else:
                options.showattributes = "cn uid departmentNumber employeeType seeAlso"
            options.longlisting = True
        if options.like and searchkey != "*":
            searchoperator = "~="
        else:
            searchoperator = "="
        if attribute != "":
            attrlist = []
            if options.showattributes is not None:
                attrlist = re.split(" ", options.showattributes)
            if options.verbose:
                if options.showattributes is None:
                    attributes = ""
                else:
                    attributes = options.showattributes
                search_str = '(&(objectclass={objectclass})({search})) {attributes}'.format(
                    objectclass,
                    attribute + searchoperator + searchkey,
                    attributes)
                print "+++ database=" + database
                print "+++ filter=" + search_str
            posix_data = ds.search_s(base, ldap.SCOPE_SUBTREE, search_str, attrlist)
        else:
            if options.verbose:
                print "(objectclass=" + objectclass + ")"
            posix_data = ds.search_s(base, ldap.SCOPE_SUBTREE,
                                     "(objectclass=" + objectclass + ")")
    except ldap.NO_SUCH_OBJECT:
        sys.stderr.write("Object not found. If you are trying to use * in your search, make ",
                         "sure that you wrap your string in single quotes to avoid shell ",
                         "expansion.\n")
        ds.unbind()
        sys.exit(1)
    except ldap.PROTOCOL_ERROR:
        sys.stderr.write("The search returned a protocol error, this shouldn't ever happen, ",
                         "please submit a trouble ticket.\n")
        ds.unbind()
        sys.exit(1)
    except Exception:
        sys.stderr.write("The search returned an error.\n")
        ds.unbind()
        sys.exit(1)

    posix_data.sort()
    # /End of stolen stuff

    # posix_data is a list of lists where:
    # index 0 of posix_data[N]: contains the distinquished name
    # index 1 of posix_data[N]: contains a dictionary of lists hashed by the following keys:
    #               telephoneNumber, departmentNumber, uid, objectClass, loginShell,
    #               uidNumber, gidNumber, sn, homeDirectory, givenName, cn

    if options.recursive:
        members_array = []
        triples = []

        # get the members and triples from the entry we are looking for
        for i in range(len(posix_data)):
            if 'memberNisNetgroup' in posix_data[i][1]:
                members_array.extend(posix_data[i][1]['memberNisNetgroup'])
            if 'nisNetgroupTriple' in posix_data[i][1]:
                triples.extend(posix_data[i][1]['nisNetgroupTriple'])

        # get triples from any sub-members
        triples = recursenetgroups(base, ds, members_array, triples)

        for str in triples:
            print str

        # clean up
        ds.unbind()
        sys.exit(0)

    for i in range(len(posix_data)):
        print ""
        if not options.longlisting:
            print "dn: " + posix_data[i][0]
        else:
            print "dn: " + posix_data[i][0]
            for (k, v) in posix_data[i][1].items():
                if len(v) > 1:
                    for v2 in v:
                        print "\t%s: %s" % (k, v2)
                else:
                    print "\t%s: %s" % (k, v[0])

    ds.unbind()


def showdatabase(objectbasedns, args):
    print ""
    if len(args) < 1:
        print objectbasedns["base"]
    else:
        if args[0].find('auto_') != -1:
            objectbasedns["auto_*"] = objectbasedns["auto_*"].replace("auto_AUTO", args[0])
            args[0] = "auto_*"
        if args[0] in objectbasedns:
            print objectbasedns[args[0]]
        else:
            print "Database " + args[0] + " not found, use ldaplist -h to list database types."


def recursenetgroups(base, ds, members_array, triples, oldmembers=[]):
    # Base case. This netgroup has no netgroup members.
    if members_array == []:
        return triples

    # members_array is the total list of netgroup members from the previous search.
    for member in members_array:
        if member in oldmembers:
            # ensure we don't follow infinite recursion loops
            members_array.remove(member)
            continue
        else:
            # add this member to the oldmembers list to avoid infinite recursion loops
            oldmembers.extend(member)

        # we need to remove the member to avoid infinite recursion
        members_array.remove(member)

        # get the triples and members for this member, and add them to the current members list
        posix_data = ds.search_s(base,
                                 ldap.SCOPE_SUBTREE,
                                 "(&(objectclass=nisNetgroup)(cn=" + member + "))")
        for data in posix_data:
            if 'nisNetgroupTriple' in data[1]:
                triples.extend(data[1]['nisNetgroupTriple'])
            if 'memberNisNetgroup' in data[1]:
                members_array.extend(data[1]['memberNisNetgroup'])

        # Recurse iteratively (tail recursion)
        return recursenetgroups(base, ds, members_array, triples, oldmembers)


if __name__ == "__main__":
    main()
