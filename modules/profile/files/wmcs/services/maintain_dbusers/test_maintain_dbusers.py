#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# pylint: disable=missing-class-docstring,missing-function-docstring
from __future__ import annotations

import unittest
from typing import Any, cast
from unittest import mock

import maintain_dbusers
import pymysql
import pytest
import requests


class MockResponse:
    def __init__(self, json_data: dict[str, Any], status_code: int = 200):
        self.json_data = json_data
        self.status_code = status_code

    def json(self):
        return self.json_data

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise requests.HTTPError(response=cast(requests.Response, self))


class StubLdapConnection:
    def __init__(self, mocked_response_pages: list[Any]):
        self._cur_response = 0
        self._responses = mocked_response_pages
        self._initialized = False

    @property
    def response(self) -> list[Any]:
        return self._responses[self._cur_response]

    @property
    def result(self) -> dict[str, Any]:
        return {
            "controls": {
                "1.2.840.113556.1.4.319": {"value": {"cookie": None if self._finished else "12345"}}
            }
        }

    def _increment_response(self):
        if self._finished:
            return

        self._cur_response += 1

    @property
    def _finished(self):
        return self._cur_response + 1 == len(self._responses)

    def search(self, *_args, **_kwargs):
        if not self._initialized:
            self._initialized = True
            return

        self._increment_response()

    def __enter__(self):
        return self

    def __exit__(self, _1, _2, _3):
        pass


class TestStubLdapConnection:
    def test_stubldapconnection_with_one_page_has_false_cookie_on_one_search(self):
        myconn = StubLdapConnection(mocked_response_pages=[["page1-elem1", "page2-elem2"]])
        with myconn as conn:
            conn.search()
            cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]

        assert not cookie

    def test_stubldapconnection_returns_first_page(self):
        expected_response = ["page1-elem1", "page1-elem2"]
        myconn = StubLdapConnection(mocked_response_pages=[expected_response])
        with myconn as conn:
            conn.search()

        assert conn.response == expected_response

    def test_stubldapconnection_sets_cookie_false_when_having_two_pages(self):
        myconn = StubLdapConnection(mocked_response_pages=[["page1"], ["page2"]])
        with myconn as conn:
            conn.search()
            first_search_cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
                "cookie"
            ]

            conn.search()
            second_search_cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"][
                "cookie"
            ]

        assert first_search_cookie
        assert not second_search_cookie

    def test_stubldapconnection_returns_all_pages_results(self):
        expected_elements = [["page1"], ["page2"]]
        myconn = StubLdapConnection(mocked_response_pages=expected_elements)
        with myconn as conn:
            conn.search()
            first_page_elements = conn.response

            conn.search()
            second_page_elements = conn.response

        assert first_page_elements == expected_elements[0]
        assert second_page_elements == expected_elements[1]


def get_dummy_ldap_user(user_id: int):
    return {
        "attributes": {
            "member": [f"member-{user_id}"],
            "uid": [f"user-{user_id}"],
            "cn": [f"tool-{user_id}"],
            "uidNumber": user_id,
        }
    }


def get_dummy_ldap_config():
    return {
        "ldap": {
            "hosts": ["https://test-host.org"],
            "username": "test-username",
            "password": "test-password",
        }
    }


class CommitToDbTestCase(unittest.TestCase):
    def setUp(self):
        self.db = mock.MagicMock(spec=pymysql.connections.Connection)

    def test_should_call_rollback_method_when_dry_run_true(self):
        maintain_dbusers.commit_to_db(db=self.db, dry_run=True)

        self.assertTrue(self.db.rollback.called)
        self.assertFalse(self.db.commit.called)

    def test_should_call_commit_method_when_dry_run_false(self):
        maintain_dbusers.commit_to_db(db=self.db, dry_run=False)

        self.assertTrue(self.db.commit.called)
        self.assertFalse(self.db.rollback.called)


class ShouldExecuteForUserTestCase(unittest.TestCase):
    def setUp(self):
        self.only_users = ["user1", "user2", "user3"]

    def test_should_return_true_when_username_in_only_users(self):
        right_username = "user1"
        result = maintain_dbusers.should_execute_for_user(
            username=right_username, only_users=self.only_users
        )

        self.assertTrue(result)

    def test_should_return_true_when_only_users_is_empty(self):
        result = maintain_dbusers.should_execute_for_user(username="", only_users=[])
        self.assertTrue(result)

    def test_should_return_false(self):
        wrong_username = "wrong-username"
        result = maintain_dbusers.should_execute_for_user(
            username=wrong_username, only_users=self.only_users
        )

        self.assertFalse(result)


class GenerateNewPasswordTestCase(unittest.TestCase):
    def test_should_return_string(self):
        password = maintain_dbusers.generate_new_pw()
        self.assertTrue(isinstance(password, str))

    def test_should_return_unique_values(self):
        password_1 = maintain_dbusers.generate_new_pw()
        password_2 = maintain_dbusers.generate_new_pw()
        self.assertNotEqual(password_1, password_2)


class MysqlHashTestCase(unittest.TestCase):
    def test_should_return_expected_value(self):
        expected_hash = "*4414e26eded6d661b5386813ebba95065dbc4728"
        password = "test_password"
        self.assertEqual(maintain_dbusers.mysql_hash(password), expected_hash)


class FindToolsTestCase(unittest.TestCase):
    @mock.patch("maintain_dbusers.ldap3")
    @mock.patch(
        "maintain_dbusers.get_ldap_conn",
        return_value=StubLdapConnection(
            mocked_response_pages=[[get_dummy_ldap_user(user_id=1), get_dummy_ldap_user(user_id=2)]]
        ),
    )
    def test_should_return_correct_tools_if_all_in_one_page(self, _1, _2):
        expected_tools = [("tool-1", 1), ("tool-2", 2)]
        result = maintain_dbusers.find_tools(get_dummy_ldap_config())
        self.assertEqual(result, expected_tools)

    @mock.patch("maintain_dbusers.ldap3")
    @mock.patch(
        "maintain_dbusers.get_ldap_conn",
        return_value=StubLdapConnection(
            mocked_response_pages=[
                [get_dummy_ldap_user(user_id=1)],
                [get_dummy_ldap_user(user_id=2)],
            ]
        ),
    )
    def test_should_return_correct_tools_if_all_returned_in_many_pages(self, _1, _2):
        expected_tools = [("tool-1", 1), ("tool-2", 2)]

        gotten_tools = maintain_dbusers.find_tools(get_dummy_ldap_config())

        self.assertEqual(gotten_tools, expected_tools)


class FindToolsUsersTestCase(unittest.TestCase):
    @mock.patch("maintain_dbusers.ldap3")
    @mock.patch(
        "maintain_dbusers.get_ldap_conn",
        return_value=StubLdapConnection(
            mocked_response_pages=[[get_dummy_ldap_user(user_id=1), get_dummy_ldap_user(user_id=2)]]
        ),
    )
    def test_should_return_list_of_user_uid_and_uid_number_tuple(self, _1, _2):
        expected_tools_users = [("user-1", 1), ("user-2", 2)]
        config = {
            "ldap": {
                "hosts": ["https://test-host.org"],
                "username": "test-username",
                "password": "test-password",
            }
        }

        result = maintain_dbusers.find_tools_users(config)
        self.assertEqual(result, expected_tools_users)


class WriteReplicaCnfTestCase(unittest.TestCase):
    SERVER_ERROR_REPLY = MockResponse(
        json_data={"result": "error", "detail": {"reason": "this is an error"}}, status_code=500
    )
    SERVER_SKIP_REPLY = MockResponse(
        json_data={
            "result": "skip",
            "detail": {"replica_path": "path/skipped", "reason": "this is a skip reply"},
        },
        status_code=200,
    )
    SERVER_OK_REPLY = MockResponse(
        json_data={"result": "ok", "detail": {"replica_path": "/this/is/a/path"}}, status_code=200
    )

    @staticmethod
    def get_dummy_params(**kwargs):
        params = {
            "account_id": "account_id",
            "account_type": "tool",
            "uid": "uid",
            "mysql_username": "username",
            "password": "password",
            "dry_run": True,
            "config": {
                "replica_cnf": {
                    "paws": {
                        "root_url": "https://paws-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                    "tools": {
                        "root_url": "https://tools-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                }
            },
        }
        params.update(kwargs)
        return params

    @mock.patch("maintain_dbusers.requests.post")
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_raise_key_error_if_function_is_called_with_wrong_config_keys(self, _1, _2):
        with pytest.raises(KeyError):
            maintain_dbusers.write_replica_cnf(
                "right", "number", "of", "args", "where", "passed", {"but wrong config keys": ""}
            )

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_should_be_called_with_correct_user_agent(self, mocked_requests_post):
        maintain_dbusers.write_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        gotten_call_headers = mocked_requests_post.call_args[-1].get("headers", {})
        self.assertEqual(maintain_dbusers.USER_AGENT, gotten_call_headers.get("User-Agent", None))

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_should_be_called_with_correct_url(self, mocked_requests_post):
        kwargs = self.get_dummy_params()
        maintain_dbusers.write_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["tools"]["root_url"]))

        kwargs["account_type"] = "paws"
        maintain_dbusers.write_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["paws"]["root_url"]))

    @mock.patch("maintain_dbusers.requests.post", side_effect=Exception)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_post_raises_exception(
        self, mocked_logging_log, mocked_requests_post
    ):
        params = self.get_dummy_params(dry_run=False)
        with pytest.raises(Exception):
            maintain_dbusers.write_replica_cnf(**params)
        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_ERROR_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_server_returns_error(
        self, mocked_logging_log, mocked_requests_post
    ):
        params = self.get_dummy_params(dry_run=False)

        with pytest.raises(Exception):
            maintain_dbusers.write_replica_cnf(**params)
        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_SKIP_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_server_returns_skip(
        self, mocked_logging_log, mocked_requests_post
    ):
        params = self.get_dummy_params(dry_run=False)

        with pytest.raises(Exception):
            maintain_dbusers.write_replica_cnf(**params)
        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)


class ReadReplicaCnfTestCase(unittest.TestCase):
    SERVER_ERROR_REPLY = MockResponse(
        json_data={"result": "error", "detail": {"reason": "this is an error"}}, status_code=500
    )
    SERVER_OK_REPLY = MockResponse(
        json_data={"result": "ok", "detail": {"user": "test-user", "password": "test-password"}},
        status_code=200,
    )

    @staticmethod
    def get_dummy_params(**kwargs):
        params = {
            "account_id": "account_id",
            "account_type": "tool",
            "dry_run": False,
            "config": {
                "replica_cnf": {
                    "paws": {
                        "root_url": "https://paws-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                    "tools": {
                        "root_url": "https://tools-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                }
            },
        }
        params.update(kwargs)
        return params

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_ERROR_REPLY)
    def test_should_raise_key_error_if_function_is_called_with_wrong_config_keys(self, _):
        with pytest.raises(KeyError):
            maintain_dbusers.read_replica_cnf(
                "right", "args", "passed", {"but wrong config keys": ""}
            )

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_should_be_called_with_correct_kwargs(self, mocked_requests_post):
        maintain_dbusers.read_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        call_headers = mocked_requests_post.call_args[-1].get("headers", {})
        self.assertEqual(maintain_dbusers.USER_AGENT, call_headers.get("User-Agent", None))

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_should_be_called_with_correct_url(self, mocked_requests_post):
        kwargs = self.get_dummy_params()
        maintain_dbusers.read_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["tools"]["root_url"]))

        kwargs["account_type"] = "paws"
        maintain_dbusers.read_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["paws"]["root_url"]))

    @mock.patch("maintain_dbusers.requests.post", side_effect=Exception)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_post_raises(
        self, mocked_logging_log, mocked_requests_post
    ):
        with pytest.raises(Exception):
            maintain_dbusers.read_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", side_effect=SERVER_ERROR_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_server_replies_error(
        self, mocked_logging_log, mocked_requests_post
    ):
        with pytest.raises(Exception):
            maintain_dbusers.read_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_should_return_user_and_path_when_server_returns_ok(self, mocked_requests_post):
        expected_result = ("test-user", "test-password")

        gotten_result = maintain_dbusers.read_replica_cnf(**self.get_dummy_params())

        self.assertEqual(gotten_result, expected_result)
        self.assertTrue(mocked_requests_post.called)


class DeleteReplicaCnfTestCase(unittest.TestCase):
    SERVER_ERROR_REPLY = MockResponse(
        json_data={"result": "error", "detail": {"reason": "this is an error"}}, status_code=500
    )
    SERVER_OK_REPLY = MockResponse(
        json_data={
            "result": "ok",
            "detail": {"result": "ok", "detail": {"ToolforgeToolFileBackend": "OK"}},
        },
        status_code=200,
    )

    @staticmethod
    def get_dummy_params(**kwargs):
        params = {
            "account_id": "account_id",
            "account_type": "tool",
            "dry_run": False,
            "config": {
                "replica_cnf": {
                    "paws": {
                        "root_url": "https://paws-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                    "tools": {
                        "root_url": "https://tools-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    },
                }
            },
        }
        params.update(kwargs)
        return params

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_should_raise_key_error_if_function_is_called_with_wrong_config_keys(self, _):
        with pytest.raises(KeyError):
            maintain_dbusers.delete_replica_cnf(
                "right", "args", "passed", {"but wrong config keys": ""}
            )

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_sets_the_user_agent_header(self, mocked_requests_post):
        maintain_dbusers.delete_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        call_headers = mocked_requests_post.call_args[-1].get("headers", {})
        self.assertEqual(maintain_dbusers.USER_AGENT, call_headers.get("User-Agent", None))

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_request_post_should_be_called_with_correct_url(self, mocked_requests_post):
        kwargs = self.get_dummy_params()
        maintain_dbusers.delete_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["tools"]["root_url"]))

        kwargs["account_type"] = "paws"
        maintain_dbusers.delete_replica_cnf(**kwargs)

        self.assertTrue(mocked_requests_post.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        url = mocked_requests_post.call_args[-1].get("url", "")
        self.assertTrue(url.startswith(kwargs["config"]["replica_cnf"]["paws"]["root_url"]))

    @mock.patch("maintain_dbusers.requests.post", side_effect=Exception)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_if_post_raises(
        self, mocked_logging_log, mocked_requests_post
    ):
        with pytest.raises(Exception):
            maintain_dbusers.delete_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", side_effect=SERVER_ERROR_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_if_server_returns_error(
        self, mocked_logging_log, mocked_requests_post
    ):
        with pytest.raises(Exception):
            maintain_dbusers.delete_replica_cnf(**self.get_dummy_params())

        self.assertTrue(mocked_requests_post.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.post", return_value=SERVER_OK_REPLY)
    def test_completes_successfully(self, mocked_requests_post):
        assert maintain_dbusers.delete_replica_cnf(**self.get_dummy_params()) is None


class FetchPawsUidsTestCase(unittest.TestCase):
    SERVER_ERROR_REPLY = MockResponse(
        json_data={"result": "error", "detail": {"reason": "this is an error"}}, status_code=500
    )
    SERVER_BADUID_REPLY = MockResponse(
        json_data={
            "result": "ok",
            "detail": {"paws_uids": ["nonnumeric-user1", "nonnumeric-user2"]},
        },
        status_code=200,
    )
    SERVER_OK_REPLY = MockResponse(
        json_data={"result": "ok", "detail": {"paws_uids": ["1", "2"]}}, status_code=200
    )

    @staticmethod
    def get_dummy_params(**kwargs):
        params = {
            "config": {
                "replica_cnf": {
                    "paws": {
                        "root_url": "https://paws-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    }
                }
            }
        }
        params.update(kwargs)
        return params

    @mock.patch("maintain_dbusers.requests.get", return_value=SERVER_OK_REPLY)
    def test_should_raise_key_error_if_function_is_called_with_wrong_config_keys(self, _):
        with pytest.raises(KeyError):
            maintain_dbusers.fetch_paws_uids(
                {"right number of function args but wrong config keys": ""}
            )

    @mock.patch("maintain_dbusers.requests.get", return_value=SERVER_OK_REPLY)
    def test_request_get_sends_correct_user_agent(self, mocked_requests_get):
        maintain_dbusers.fetch_paws_uids(**self.get_dummy_params())

        self.assertTrue(mocked_requests_get.called)
        # the kwargs property for mock.call is only python>=3.8, ci uses 3.7
        call_headers = mocked_requests_get.call_args[-1].get("headers", {})
        self.assertEqual(maintain_dbusers.USER_AGENT, call_headers.get("User-Agent", None))

    @mock.patch("maintain_dbusers.requests.get", side_effect=Exception)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_if_get_raises(
        self, mocked_logging_log, mocked_requests_get
    ):
        with pytest.raises(Exception):
            maintain_dbusers.fetch_paws_uids(**self.get_dummy_params())

        self.assertTrue(mocked_requests_get.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.get", side_effect=SERVER_ERROR_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_if_server_returns_error(
        self, mocked_logging_log, mocked_requests_get
    ):
        with pytest.raises(Exception):
            maintain_dbusers.fetch_paws_uids(**self.get_dummy_params())

        self.assertTrue(mocked_requests_get.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.get", return_value=SERVER_BADUID_REPLY)
    @mock.patch("maintain_dbusers.logging.log")
    def test_should_log_error_and_raise_exception_when_server_returns_nonnumeric_uids(
        self, mocked_logging_log, mocked_requests_get
    ):
        with pytest.raises(Exception):
            maintain_dbusers.fetch_paws_uids(**self.get_dummy_params())

        self.assertTrue(mocked_requests_get.called)
        self.assertTrue(mocked_logging_log.called)

    @mock.patch("maintain_dbusers.requests.get", return_value=SERVER_OK_REPLY)
    def test_should_return_string(self, mocked_requests_get):
        expected_result = [1, 2]

        gotten_result = maintain_dbusers.fetch_paws_uids(**self.get_dummy_params())

        self.assertEqual(gotten_result, expected_result)
        self.assertTrue(mocked_requests_get.called)


def get_dummy_wiki_user(username: str = "dummy-user1"):
    return {"query": {"globaluserinfo": {"name": username}}}


class FindPawsUsersTestCase(unittest.TestCase):
    @staticmethod
    def get_dummy_params(**kwargs):
        params = {
            "config": {
                "replica_cnf": {
                    "paws": {
                        "root_url": "https://paws-root-url.com",
                        "username": "auth-username",
                        "password": "auth-password",
                    }
                }
            }
        }
        params.update(kwargs)
        return params

    @mock.patch("maintain_dbusers.fetch_paws_uids", side_effect=Exception("Dummy error"))
    def test_should_re_raise_if_fetch_paws_uids_raises(self, mocked_fetch_paws_uids):
        with pytest.raises(Exception, match="Dummy error"):
            maintain_dbusers.find_paws_users({"wrong-config-key": ""})

        self.assertTrue(mocked_fetch_paws_uids.called)

    @mock.patch("maintain_dbusers.fetch_paws_uids", return_value=None)
    def test_should_return_empty_list_if_fetch_paws_uids_returns_none(self, mocked_fetch_paws_uids):
        expected_result: list[tuple[str, int]] = []
        gotten_result = maintain_dbusers.find_paws_users(**self.get_dummy_params())

        self.assertEqual(gotten_result, expected_result)
        self.assertTrue(mocked_fetch_paws_uids.called)

    @mock.patch("maintain_dbusers.fetch_paws_uids", return_value=[])
    def test_should_return_empty_list_if_fetch_paws_uids_returns_empty_list(
        self, mocked_fetch_paws_uids
    ):
        expected_result: list[tuple[str, int]] = []
        gotten_result = maintain_dbusers.find_paws_users(**self.get_dummy_params())

        self.assertEqual(gotten_result, expected_result)
        self.assertTrue(mocked_fetch_paws_uids.called)

    @mock.patch("maintain_dbusers.fetch_paws_uids", return_value=[1, 2])
    def test_should_return_happy_path(self, mocked_fetch_paws_uids):
        expected_result = [("1", 1), ("2", 2)]
        gotten_result = maintain_dbusers.find_paws_users(**self.get_dummy_params())

        self.assertEqual(gotten_result, expected_result)
        self.assertTrue(mocked_fetch_paws_uids.called)
