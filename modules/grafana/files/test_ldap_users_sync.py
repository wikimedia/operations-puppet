# SPDX-License-Identifier: Apache-2.0
import unittest
from unittest.mock import MagicMock

import ldap_users_sync

GRAFANA_USERS = [{"id": 1, "name": "admin", "email": "admin", "login": "admin"}]
LDAP_USERS = {"user1": {"cn": [b"user1"], "mail": [b"user1@domain"]}}


class MockResponse(object):
    def __init__(self, response, status):
        self.response = response
        self.status = status

    def json(self):
        return self.response


def get_ldap_users(uid):
    return LDAP_USERS[uid]


class SyncerTest(unittest.TestCase):
    def setUp(self):
        self.grafana = MagicMock(spec=ldap_users_sync.GrafanaAPI)
        self.grafana.get = MagicMock(return_value=MockResponse(GRAFANA_USERS, 200))
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
