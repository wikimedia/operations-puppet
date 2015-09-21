#!/usr/bin/env python

# 2014 Chase Pettet
# 2015 Alex Monk
# Tests to perform basic validation on data.yaml

from collections import Counter
import itertools
import ldap
import os
import sys
import unittest
import yaml

sys.path.append('../../ldap/files/scripts')

import ldapsupportlib


class DataTest(unittest.TestCase):
    def flatten(self, lists):
        """flattens nested arrays"""
        return list(itertools.chain.from_iterable(lists))

    def all_assigned_users(self, admins):
        """unique assigned users
        :param admins: hash from valid data.yaml
        :returns: list
        """
        nested_users_list = map(
            lambda u: u['members'], admins['groups'].values()
        )
        return list(set(self.flatten(nested_users_list)))

    def open_data(self):
        with open(os.path.join(os.path.dirname(__file__), 'data.yaml')) as f:
            admins = yaml.safe_load(f)

        return admins

    def testDataDotYaml(self):
        admins = self.open_data()
        all_users = list(admins['users'])
        grouped_users = self.all_assigned_users(admins)

        # ensure all assigned users exist
        non_existent_users = [u for u in grouped_users if u not in all_users]
        self.assertEqual(
            [],
            non_existent_users,
            'Users assigned that do not exist'
        )

        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, 'Duplicate group GIDs')

    def testLabsSshKeys(self):
        # Make sure no users have the same ssh key in labs and production

        ldapSupportLib = ldapsupportlib.LDAPSupportLib()
        ds = ldapSupportLib.connect()
        base = "ou=people," + ldapSupportLib.getBase()

        keys = set()
        for entry in ds.search_s(base, ldap.SCOPE_SUBTREE, "(objectclass=inetOrgPerson)"):
            for k, v in entry[1].items():
                if k == "sshPublicKey":
                    for v2 in v:
                        key = ' '.join(v2.split(' ')[:2])
                        keys.update([key])

        prodData = self.open_data()
        for userName, userData in prodData['users'].items():
            badKeys = list(set(userData['ssh_keys']).intersection(keys))
            if len(badKeys) > 0:
                print('%s: %s' % (userName, userData))
            self.assertEqual(badKeys, 0)
        ds.unbind()

if __name__ == '__main__':
    unittest.main()
