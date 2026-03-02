#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import sys
import types
import unittest
from unittest.mock import MagicMock

# the module under test imports wmflib.requests; provide a tiny fake so that
# the import succeeds and the code can be exercised without pulling the real
# library.
wmflib = types.ModuleType("wmflib")
wmflib.requests = types.ModuleType("wmflib.requests")
wmflib.requests.http_session = lambda *args, **kwargs: None
wmflib.requests.DEFAULT_RETRY_METHODS = ()
sys.modules["wmflib"] = wmflib
sys.modules["wmflib.requests"] = wmflib.requests

import ldap_users_sync

GRAFANA_USERS = [
    {"id": 1, "name": "admin", "email": "admin", "login": "admin"}
]
# start with a couple of valid ldap entries; tests may add others later
LDAP_USERS = {
    "user1": {"cn": [b"user1"], "mail": [b"user1@domain"]},
    "user2": {"cn": [b"user2"], "mail": [b"user2@domain"]},
}


class MockResponse(object):
    def __init__(self, response, status):
        self.response = response
        self.status = status

    def json(self):
        return self.response


def get_ldap_users(uid):
    # mimic the API of WikimediaLDAP.normalize_metadata: return None for
    # unknown uids
    data = LDAP_USERS.get(uid)
    if data is None:
        return None
    return ldap_users_sync.WikimediaLDAP.normalize_metadata(data)


class SyncerTest(unittest.TestCase):
    def setUp(self):
        self.grafana = MagicMock(spec=ldap_users_sync.GrafanaAPI)
        self.grafana.get = MagicMock(
            return_value=MockResponse(GRAFANA_USERS, 200)
        )
        self.ldap = MagicMock(spec=ldap_users_sync.WikimediaLDAP)
        self.ldap.uid_meta = MagicMock(side_effect=get_ldap_users)
        self.syncer = ldap_users_sync.GrafanaSyncer(self.grafana, self.ldap)
        # list that the syncer will fill when metadata is invalid
        self.invalid = []

    def test_sync_user_no_commit(self):
        self.syncer.sync_ldap_users(["user1"], "Editor", self.invalid)
        self.ldap.uid_meta.assert_called_with("user1")

    def test_sync_add_user(self):
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Editor", self.invalid)
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
        self.syncer.sync_ldap_users(["user1"], "Editor", self.invalid)
        self.ldap.uid_meta.assert_called_with("user1")

        self.ldap.uid_meta.reset_mock()
        self.syncer.sync_ldap_users(["user1"], "Editor", self.invalid)
        self.ldap.uid_meta.assert_not_called()

    def test_sync_user_with_trailing_whitespace(self):
        """Ensure emails with trailing spaces are normalized before being sent to Grafana."""
        LDAP_USERS["user_with_space"] = {
            "cn": [b"user_with_space"],
            "mail": [b"user@domain "],
        }

        self.syncer.commit = True
        self.syncer.sync_ldap_users(
            ["user_with_space"], "Editor", self.invalid
        )

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

    def test_user_with_invalid_metadata(self):
        """When uid_meta returns None the login must be recorded and no API call made."""
        self.ldap.uid_meta.return_value = None
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["unknown"], "Editor", self.invalid)

        self.ldap.uid_meta.assert_called_with("unknown")
        self.assertIn("unknown", self.invalid)
        self.grafana.post.assert_not_called()
        self.grafana.patch.assert_not_called()

    def test_admin_flag_handling(self):
        # admin role sets grafana admin
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Admin", self.invalid)
        self.grafana.put.assert_called_with(
            unittest.mock.ANY, json={"isGrafanaAdmin": True}
        )
        # non-admin unsets it
        self.grafana.put.reset_mock()
        self.syncer.sync_ldap_users(["user2"], "Editor", self.invalid)
        self.grafana.put.assert_called_with(
            unittest.mock.ANY, json={"isGrafanaAdmin": False}
        )

    def test_normalize_meta_invalid(self):
        # invalid values should produce None rather than raising
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"email": [b""]})
        )
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"login": [""]})
        )
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata(
                {"name": [b"   "]}
            )
        )
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"email": [None]})
        )
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"login": [None]})
        )
        self.assertIsNone(
            ldap_users_sync.WikimediaLDAP.normalize_metadata({"name": [None]})
        )
