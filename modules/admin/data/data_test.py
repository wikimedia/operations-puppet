#!/usr/bin/env python3

# 2014 Chase Pettet
# Tests to perform basic validation on data.yaml

import os
import re
import unittest
from collections import Counter, defaultdict
from collections.abc import Iterable
from datetime import datetime

import sshpubkeys
import yaml


def flatten(not_flat):
    """flatten a complex list of lists"""
    # https://stackoverflow.com/a/2158532/3075306
    for element in not_flat:
        if isinstance(element, Iterable) and not isinstance(element, str):
            yield from flatten(element)
        else:
            yield element


class DataTest(unittest.TestCase):

    admins = {}
    bad_privileges_re = [
        re.compile(r"systemctl (?:\*|edit)"),
        re.compile(r"(\s|^|\/)vi(m|ew)?(\s|$)"),
        re.compile(r"(\s|^|\/)strace(\s|$)"),
        re.compile(r"(\s|^|\/)tcpdump(\s|$)"),
    ]
    system_gid_min = 900
    system_gid_max = 950
    system_uid_min = 900
    system_uid_max = 950

    # This should never happen (as user IDs are originally assigned on LDAP account creation),
    # but let's enforce this here just in case
    user_uid_max = 49999

    @classmethod
    def setUpClass(cls):
        with open(os.path.join(os.path.dirname(__file__), "data.yaml")) as f:
            cls.admins = yaml.safe_load(f)
        with open(os.path.join(os.path.dirname(__file__), "system_users.txt")) as f:
            cls.system_users = set(i.strip() for i in f.readlines() if i[0] != "#")

    def _human_users(self):
        return set(
            username
            for username, val in self.admins["users"].items()
            if val["ensure"] == "present" and not val.get("system", False)
        )

    def test_shell_user_is_not_system_user(self):
        """
        Ensure shell accounts don't use one of the system user account usernames
        (unless explicitly declared as a system user in data.yaml).
        """

        human_users = self._human_users()

        # List of system users declared in Puppet but not in data.yaml.
        system_users = self.system_users.intersection(human_users)
        self.assertEqual(
            set(),
            system_users,
            "The following shell account(s) are reserve system users: %r"
            % system_users,
        )

    def test_humans_have_ssh_keys(self):
        """
        Ensure we're declaring ssh_keys for humans (even if empty)
        """

        for username in self._human_users():
            self.assertIn("ssh_keys", self.admins["users"][username])

    def test_ldap_user_is_not_system_user(self):
        """Ensure LDAP accounts don't use one of the system user account usernames"""
        present_users = set(
            username
            for username, val in self.admins["ldap_only_users"].items()
            if val["ensure"] == "present"
        )
        system_users = self.system_users.intersection(present_users)
        self.assertEqual(
            set(),
            system_users,
            "The following shell account(s) are reserved system users: %r"
            % system_users,
        )

    def test_for_backdoor_sudo(self):
        """Ensure sudo commands which are too permissive are not added"""
        bad_privileges = defaultdict(list)
        for group, val in self.admins["groups"].items():
            for privilege in val.get("privileges", []):
                for priv_re in self.bad_privileges_re:
                    if priv_re.search(privilege):
                        bad_privileges[group].append(privilege)
        self.assertEqual(
            {},
            bad_privileges,
            "The following groups define banned privileges: %r" % bad_privileges,
        )

    def test_group_system_gid_range(self):
        """Ensure system group GID's are in the correct range"""
        groups = [
            "%s (gid: %s)" % (group, config.get("gid"))
            for group, config in self.admins["groups"].items()
            if config.get("system")
            and not self.system_gid_min <= config.get("gid") <= self.system_gid_max
        ]
        self.assertEqual(
            [],
            groups,
            "System groups GID must be in range [%s-%s]: %r"
            % (self.system_gid_min, self.system_gid_max, groups),
        )

    def test_group_standard_gid_range(self):
        """Ensure groups GID's are in the correct range"""
        # some standard groups don't have a gid so we mock it as 1000 below
        groups = [
            "%s (gid: %s)" % (group, config.get("gid", "<unset assuming 1000>"))
            for group, config in self.admins["groups"].items()
            if not config.get("system")
            and self.system_gid_min <= config.get("gid", 1000) <= self.system_gid_max
        ]
        self.assertEqual(
            [],
            groups,
            "Standard groups GIDs must not be in system groups range [%s-%s]: %r"
            % (self.system_gid_min, self.system_gid_max, groups),
        )

    def test_group_gids_are_uniques(self):
        """Ensure no two groups uses the same gid"""
        gids = filter(
            None, [v.get("gid", None) for k, v in self.admins["groups"].items()]
        )
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, "Duplicate group GIDs: %r" % dupes)

    def test_user_system_gid_range(self):
        """Ensure system users UID's are in the correct range"""
        users = [
            "%s (uid: %s)" % (user, config.get("uid"))
            for user, config in self.admins["users"].items()
            if config.get("system")
            and not self.system_gid_min <= config.get("uid") <= self.system_gid_max
        ]
        self.assertEqual(
            [],
            users,
            "System users UID must be in range [%s-%s]: %r"
            % (self.system_uid_min, self.system_uid_max, users),
        )

    def test_user_standard_gid_range(self):
        """Ensure users UID's are in the correct range"""
        users = [
            "%s (uid: %s)" % (user, config.get("uid"))
            for user, config in self.admins["users"].items()
            if not config.get("system")
            and (
                self.system_gid_min <= config.get("uid") <= self.system_gid_max
                or config.get("uid") > self.user_uid_max
            )
        ]
        self.assertEqual(
            [],
            users,
            "Standard user UIDs must not be in system groups range [%s-%s, >%s]: %r"
            % (self.system_uid_min, self.system_uid_max, self.user_uid_max, users),
        )

    def test_absent_members(self):
        """Ensure absent users in the absent group and have ensure => absent"""
        absent_members = set(self.admins["groups"]["absent"]["members"])
        absentees = set(
            username
            for username, val in self.admins["users"].items()
            if val["ensure"] == "absent"
        )
        self.maxDiff = None
        self.longMessage = True
        self.assertSetEqual(
            absent_members,
            absentees,
            'Absent users are both in "absent" group (first set)'
            'and in marked "ensure: absent" (second set)',
        )

    def test_group_members(self):
        """Ensure group members are real users"""
        present_users = set(
            username
            for username, val in self.admins["users"].items()
            if val["ensure"] == "present"
        )
        present_group_members = set(
            user
            for user in flatten(
                value["members"]
                for group, value in self.admins["groups"].items()
                if group not in ["absent", "absent_ldap"]
            )
        )
        missing_users = present_group_members - present_users
        self.assertEqual(
            missing_users,
            set(),
            "The following users are members of a group but don't exist: {}".format(
                ",".join(missing_users)
            ),
        )

    def test_expiry_date_format(self):
        """Ensure that the expiry_date field, when present, has the correct %Y-%m-%d format."""
        bad_expiries = []
        for username, attrs in self.admins["users"].items():
            expiry = attrs.get("expiry_date")
            if expiry is None:
                continue

            try:
                datetime.strptime(str(attrs["expiry_date"]), "%Y-%m-%d")
            except Exception as e:
                bad_expiries.append((username, attrs["expiry_date"], e))

        if bad_expiries:
            bad_expiries_str = "\n".join(
                "{}: {} ({})".format(*bad_expiry) for bad_expiry in bad_expiries
            )
            raise ValueError(
                "The following users have an invalid expiry_date field:\n{}".format(
                    bad_expiries_str
                )
            )

    def test_expiry_date_has_contact(self):
        """Ensure that if there is an expiry_date field also an expiry_contact field is set."""
        wrong_expiries = {
            username
            for username, attrs in self.admins["users"].items()
            if "expiry_date" in attrs and "expiry_contact" not in attrs
        }

        if wrong_expiries:
            raise ValueError(
                "The following users have an expiry_date set without an expiry_contact: {}".format(
                    ", ".join(wrong_expiries)
                )
            )

    def test_expiry_contact_has_date(self):
        """Ensure that if there is an expiry_contact field also an expiry_date field is set."""
        wrong_expiries = {
            username
            for username, attrs in self.admins["users"].items()
            if "expiry_contact" in attrs and "expiry_date" not in attrs
        }

        if wrong_expiries:
            raise ValueError(
                "The following users have an expiry_contact set without an expiry_date: {}".format(
                    ", ".join(wrong_expiries)
                )
            )

    def test_ssh_keys_are_valid(self):
        users_with_invalid_keys = set()
        for username, attrs in self.admins["users"].items():
            for key in attrs.get("ssh_keys", []):
                try:
                    sshpubkeys.SSHKey(key, strict=True).parse()
                except sshpubkeys.InvalidKeyError:
                    users_with_invalid_keys.add(username)

        if len(users_with_invalid_keys) > 0:
            raise ValueError(
                "The following users have invalid SSH keys: {}".format(
                    ", ".join(users_with_invalid_keys)
                )
            )

    def test_deprecated_groups_have_no_members(self):
        """Ensure deprecated groups have no members"""
        deprecated = {
            group
            for group, attrs in self.admins["groups"].items()
            if attrs.get("deprecated", False) and attrs["members"]
        }
        if deprecated:
            raise ValueError(
                f"The following deprecated groups have members: {', '.join(deprecated)}"
            )


if __name__ == "__main__":
    unittest.main()
