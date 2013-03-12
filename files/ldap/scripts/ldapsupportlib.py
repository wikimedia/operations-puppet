#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/ldap/scripts/ldapsupportlib.py
#####################################################################

import os
import traceback
import getpass
import sys
sys.path.append('/etc/ldap')

try:
    import ldap
except ImportError:
    sys.stderr.write("Unable to import LDAP library.\n")
    sys.exit(1)


# TODO: move all configuration to scriptconfig
class LDAPSupportLib:
    def __init__(self):
        self.base = self.getLdapInfo("base")
        self.ldapHost = self.getLdapInfo("uri")
        self.sslType = self.getLdapInfo("ssl")
        self.binddn = self.getLdapInfo("binddn")
        self.bindpw = self.getLdapInfo("bindpw")
        self.defaults = {}

    def addParserOptions(self, parser, default="proxy"):
        parser.add_option("-s", "--self", action="store_true", dest="useself", help="Use your credentials")
        parser.add_option("-D", "--bindas", action="store", dest="bindas", help="Specify user to bind as")
        parser.add_option("-m", "--directorymanager", action="store_true", dest="directorymanager", help="Use the Directory Manager's credentials")
        parser.add_option("--scriptuser", action="store_true", dest="scriptuser", help="Use the scriptusers' credentials")
        self.defaults['authuser'] = "proxy"
        if (default == "user"):
            self.defaults['authuser'] = "user"
        if (default == "Directory Manager"):
            self.defaults['authuser'] = "Directory Manager"
        if (default == "scriptuser"):
            self.defaults['authuser'] = "scriptuser"

    def getUsers(self, ds, username):
        PosixData = ds.search_s("ou=people," + self.base, ldap.SCOPE_SUBTREE, "(&(objectclass=inetOrgPerson)(uid=" + username + "))", attrlist=['*', '+'])
        return PosixData

    def getKeys(self, ds, username):
        user = self.getUsers(ds, username)
        if 'sshPublicKey' in user[0][1].keys():
            return user[1]['sshPublicKey']
        else:
            return []

    def setHost(self, host):
        self.ldapHost = host

    def setBase(self, base):
        self.base = base

    def setBindInfoByOptions(self, options, parser):
        if not (options.useself or options.directorymanager):
            if self.defaults['authuser'] == "user":
                options.useself = True
            if self.defaults['authuser'] == "Directory Manager":
                options.directorymanager = True
            if self.defaults['authuser'] == "scriptuser":
                options.scriptuser = True
        if options.useself:
            self.binddn = "uid=" + os.environ['USER'] + ",ou=people," + self.base
            self.bindpw = getpass.getpass()
        elif options.directorymanager:
            self.binddn = "cn=Directory Manager"
            self.bindpw = getpass.getpass()
        elif options.bindas:
            self.binddn = "uid=" + options.bindas + ",ou=people," + self.base
            self.bindpw = getpass.getpass()
        elif options.scriptuser:
            self.binddn = self.getLdapInfo('USER', '/etc/ldap/.ldapscriptrc')
            self.bindpw = self.getLdapInfo('PASS', '/etc/ldap/.ldapscriptrc')

    def setBindDN(self, binddn):
        self.binddn = binddn

    def setBindPW(self, bindpw):
        self.bindpw = bindpw

    def getBase(self):
        return self.base

    def getHost(self):
        return self.ldapHost

    def getLdapInfo(self, attr, conffile="/etc/ldap.conf"):
        try:
            f = open(conffile)
        except IOError:
            if conffile == "/etc/ldap.conf":
                # fallback to /etc/ldap/ldap.conf, which will likely
                # have less information
                f = open("/etc/ldap/ldap.conf")
        for line in f:
            if line.strip() == "":
                continue
            if line.split()[0].lower() == attr.lower():
                return line.split(None, 1)[1].strip()
                break

    def connect(self):
        try:
            ds = ldap.initialize(self.ldapHost)
            ds.protocol_version = ldap.VERSION3
            if self.sslType == "start_tls":
                ds.start_tls_s()
        except Exception:
            sys.stderr.write("Unable to connect to LDAP host: %s\n" % self.ldapHost)
            traceback.print_exc(file=sys.stderr)
            sys.exit(1)

        try:
            ds.simple_bind_s(self.binddn, self.bindpw)
            return ds
        except ldap.CONSTRAINT_VIOLATION:
            sys.stderr.write("You typed your password incorrectly too many times, and are now locked out. Please try again later.\n")
            sys.exit(1)
        except ldap.INVALID_DN_SYNTAX:
            sys.stderr.write("The bind DN is incorrect... \n")
            sys.exit(1)
        except ldap.NO_SUCH_OBJECT:
            sys.stderr.write("Unable to locate the bind DN account.\n")
            sys.exit(1)
        except ldap.UNWILLING_TO_PERFORM, msg:
            sys.stderr.write("The LDAP server was unwilling to perform the action requested.\nError was: %s\n" % msg[0]["info"])
            sys.exit(1)
        except ldap.INVALID_CREDENTIALS:
            sys.stderr.write("Password incorrect.\n")
            #traceback.print_exc(file=sys.stderr)
            sys.exit(1)
