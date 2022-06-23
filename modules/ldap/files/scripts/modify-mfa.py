#!/usr/bin/env python3
import sys

from optparse import OptionParser

import ldapsupportlib

from ldap import SCOPE_SUBTREE
from ldap.modlist import modifyModlist


class LdapUserNotFound(Exception):
    """raised when no valid ldap user is found"""


class LdapUser:
    """Simple class to manage LDAP users"""

    def __init__(self, username, ldap_support_lib):
        """initialise"""
        self.base = ldap_support_lib.getBase()
        self.conn = ldap_support_lib.connect()
        self.uid = 'uid={}'.format(username)
        self.dname = '{},ou=people,{}'.format(self.uid, self.base)
        self._attributes = None

    @property
    def attributes(self):
        """return the dict of attributes"""
        if self._attributes is None:
            ldap_info = self.conn.search_s(self.base, SCOPE_SUBTREE, self.uid)
            for dname, attributes in ldap_info:
                if dname == self.dname:
                    self._attributes = attributes
                    break
            else:
                raise LdapUserNotFound
        return self._attributes

    @property
    def mfa_method(self):
        """Return the current mfa value"""
        return self.attributes.get('mfa-method')

    @property
    def wikimedia_person(self):
        """indicate if the user has the wikimediaPerson objectClass"""
        return b'wikimediaPerson' in self.attributes['objectClass']

    def update_mfa(self, enable, mfa_method):
        """update the ldap object with the correct mfa method"""
        mfa_method = [mfa_method.encode()]
        oldldif = {}
        newldif = {}
        # Always add the wikimediaPerson object class
        if not self.wikimedia_person:
            oldldif['objectClass'] = self.attributes['objectClass']
            newldif['objectClass'] = self.attributes['objectClass'] + [b'wikimediaPerson']

        if enable:
            if self.mfa_method is None:
                newldif['mfa-method'] = mfa_method
            elif self.mfa_method != mfa_method:
                oldldif['mfa-method'] = self.mfa_method
                newldif['mfa-method'] = mfa_method
        else:
            if self.mfa_method is not None:
                oldldif['mfa-method'] = self.mfa_method
        if oldldif != newldif:
            modlist = modifyModlist(oldldif, newldif)
            print('making the following change:\n{}'.format(modlist))
            self.conn.modify_s(self.dname, modlist)
        else:
            print('no change')


def main():
    """main script entry"""

    ldap_support_lib = ldapsupportlib.LDAPSupportLib(enable_rw=True)

    parser = OptionParser(conflict_handler="resolve")
    parser.set_usage(
        'modify-mfa [--enable/--disable] <username>\nexample: modify-mfa --enable jbond')
    parser.add_option('--enable', action='store_true', help='enable mfa')
    parser.add_option('--disable', action='store_true', help='disable mfa')
    parser.add_option('--method', default='mfa-u2f', choices=['mfa-u2f', 'mfa-webauthn'],
                      help='the MFA type, currently only mfa-u2f is supported')
    ldap_support_lib.addParserOptions(parser, "scriptuser")

    (options, args) = parser.parse_args()
    if len(args) != 1:
        parser.error("must pass a username")
    username = args[0]

    if options.enable and options.disable:
        parser.error("options --enable and --disable are mutually exclusive")
    if not options.enable and not options.disable:
        parser.error("one of --enable or --disable must be specified")
    enable = options.enable if options.enable else False

    ldap_support_lib.setBindInfoByOptions(options, parser)
    ldap_user = LdapUser(username, ldap_support_lib)
    try:
        ldap_user.update_mfa(enable, options.method)
    except LdapUserNotFound:
        print('user ({}): Not Found'.format(username), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
