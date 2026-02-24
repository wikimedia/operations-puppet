#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import unittest
from unittest.mock import MagicMock

import ldap_users_sync

GRAFANA_USERS = [
    {"id": 1, "name": "admin", "email": "admin", "login": "admin"}
]
LDAP_USERS = {"user1": {"cn": [b"user1"], "mail": [b"user1@domain"]}}


class MockResponse(object):
    def __init__(self, response, status):
        self.response = response
        self.status = status

    def json(self):
        return self.response


def get_ldap_users(uid):
    return ldap_users_sync.WikimediaLDAP.normalize_metadata(LDAP_USERS[uid])


class SyncerTest(unittest.TestCase):
    def setUp(self):
        self.grafana = MagicMock(spec=ldap_users_sync.GrafanaAPI)
        self.grafana.get = MagicMock(
            return_value=MockResponse(GRAFANA_USERS, 200)
        )
        self.ldap = MagicMock(spec=ldap_users_sync.WikimediaLDAP)
        self.ldap.uid_meta = MagicMock(side_effect=get_ldap_users)
        self.syncer = ldap_users_sync.GrafanaSyncer(self.grafana, self.ldap)

    def test_sync_user_no_commit(self):
        self.syncer.sync_ldap_users(["user1"], "Editor")
        self.ldap.uid_meta.assert_called_with("user1")

    def test_sync_add_user(self):
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Editor")
        self.ldap.uid_meta.assert_called_with("user1")
        self.grafana.post.assert_called_with(
            "admin/users",
            json={
                "OrgId": 1,
                "email": "user1@domain",
                "login": "user1",
                "name": "user1",
                "password": unittest.mock.ANY,
            },
        )
        self.grafana.patch.assert_called_with(
            unittest.mock.ANY, json={"role": "Editor"}
        )

    def test_sync_user_once(self):
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Editor")
        self.ldap.uid_meta.assert_called_with("user1")

        self.ldap.uid_meta.reset_mock()

        self.syncer.sync_ldap_users(["user1"], "Editor")
        self.ldap.uid_meta.assert_not_called()

    def test_sync_user_with_trailing_whitespace(self):
        """Ensure emails with trailing spaces are normalized before being sent to Grafana."""
        LDAP_USERS["user_with_space"] = {
            "cn": [b"user_with_space"],
            "mail": [b"user@domain "],
        }

        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user_with_space"], "Editor")

        self.ldap.uid_meta.assert_called_with("user_with_space")

        self.grafana.post.assert_called_with(
            "admin/users",
            json={
                "OrgId": 1,
                "email": "user@domain",
                "login": "user_with_space",
                "name": "user_with_space",
                "password": unittest.mock.ANY,
            },
        )

    def test_create_user_with_empty_fields(self):
        """Ensure ValueError is raised when normalize_metadata receives empty or None fields."""
        with self.assertRaises(ValueError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"email": [b""]})
        self.assertEqual(
            str(context.exception), "Invalid email: cannot be empty or None"
        )

        with self.assertRaises(ValueError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"login": [""]})
        self.assertEqual(
            str(context.exception), "Invalid login: cannot be empty or None"
        )

        with self.assertRaises(ValueError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata(
                {"name": [b"   "]}
            )
        self.assertEqual(
            str(context.exception), "Invalid name: cannot be empty or None"
        )

        with self.assertRaises(TypeError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"email": [None]})
        self.assertIn("Unexpected LDAP value type", str(context.exception))

        with self.assertRaises(TypeError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"login": [None]})
        self.assertIn("Unexpected LDAP value type", str(context.exception))

        with self.assertRaises(TypeError) as context:
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"name": [None]})
        self.assertIn("Unexpected LDAP value type", str(context.exception))
