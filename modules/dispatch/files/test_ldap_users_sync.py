# SPDX-License-Identifier: Apache-2.0
import unittest
from unittest.mock import MagicMock

import ldap_users_sync

LDAP_USERS = {"user1": {"cn": [b"user1"], "mail": [b"user1@domain.tld"]}}
DISPATCH_USERS = {
    "total": 1,
    "items": [
        {
            "email": "user1@domain.tld",
            "projects": [],
            "organizations": [],
            "id": 1,
            "role": "Member",
        },
    ],
}

DISPATCH_INDIVIDUALS = {
    "total": 1,
    "items": [
        {
            "email": "user1@domain.tld",
            "name": "typo",
            "id": 1,
        },
    ],
}


class MockResponse(object):
    def __init__(self, response, status):
        self.response = response
        self.status = status

    def json(self):
        return self.response


def dispatch_api_get(path, *args, **kwargs):
    if "users" in path:
        return MockResponse(DISPATCH_USERS, 200)
    if "individuals" in path:
        return MockResponse(DISPATCH_INDIVIDUALS, 200)


def get_ldap_users(uid):
    return LDAP_USERS[uid]


class SyncerTest(unittest.TestCase):
    def setUp(self):
        self.dispatch = MagicMock(spec=ldap_users_sync.DispatchAPI)
        self.dispatch.get = MagicMock(side_effect=dispatch_api_get)
        self.ldap = MagicMock(spec=ldap_users_sync.WikimediaLDAP)
        self.ldap.uid_meta = MagicMock(side_effect=get_ldap_users)
        self.syncer = ldap_users_sync.DispatchSyncer(self.dispatch, self.ldap)

    def test_sync_user_no_commit(self):
        self.syncer.sync_ldap_users(["user1"], "Owner")
        self.ldap.uid_meta.assert_called_with("user1")

    def test_sync_update_role(self):
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Owner")
        self.ldap.uid_meta.assert_called_with("user1")
        # PUT individuals/1 will be called last, thus use "assert_any_call"
        # instead of "assert_called_with"
        self.dispatch.put.assert_any_call(
            "users/1",
            json={
                "role": "Owner",
                "id": 1,
            },
        )

    def test_sync_update_name(self):
        self.syncer.commit = True
        self.syncer.sync_ldap_users(["user1"], "Owner")
        self.ldap.uid_meta.assert_called_with("user1")
        self.dispatch.put.assert_called_with(
            "individuals/1",
            json={
                "email": "user1@domain.tld",
                "name": "user1",
            },
        )
