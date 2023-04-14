#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
This script keeps canonical source of mysql clouddb (currently wikireplicas
and toolsdb) accounts in a database, and ensures that it is kept up to date
with reality.

The code pattern here is that you have a central data store (the accountsdb),
that is then read/written to by various independent functions. These
functions are not 'pure' - they could even be separate scripts. They
mutate the DB in some way. They are also supposed to be idempotent -
if they have nothing to do, they should not do anything.

Some of the functions are one-time only. These are:

## harvest_cnf_files ##

 - Look through NFS for replica.my.cnf files
 - For those found, but no entry in `accounts` table, make an entry

## harvest_dbaccounts ##
 - Look through all accounts in account db
 - Look through all users in all provisioned clouddbs
 - Make entries in `account_host` table with status of all accounts.

Most of these functions should be run in a continuous loop, maintaining
mysql accounts for new tool/user accounts as they appear.

## populate_accountsdb ##

 - Find list of tools/users (From LDAP) that aren't in the `accounts` table
 - Create a replica.my.cnf for each of these tools/users
 - Make an entry in the `accounts` table for each of these tools/users
 - Make entries in `account_host` for each of these tools/users, marking them as
   absent

## create_accounts_from_accountsdb ##

 - Look through `account_host` table for accounts that are marked as 'absent'
 - Create those accounts, and mark them as present.

If we need to add a new clouddb, we can do so the following way:
 - Add it to the config file
 - Insert entries into `account_host` for each tool/user with the new host.
 - Run `create_accounts_from_accountsdb`

In normal usage, just a continuous process running `populate_accountsdb` and
`create_accounts_from_accountsdb` in a loop will suffice.

TODO:
  - Support for maintaining per-tool restrictions (number of connections + time)
"""
from __future__ import annotations

import argparse
import logging
import random
import re
import string
import sys
import time
from enum import Enum
from functools import wraps
from hashlib import sha1
from typing import Any

import ldap3
import pymysql
import requests
import yaml
from prometheus_client import Counter, start_http_server

PROJECT = "tools"
PAWS_RUNTIME_UID = 52771
PASSWORD_LENGTH = 16
PASSWORD_CHARS = string.ascii_letters + string.digits
DEFAULT_MAX_CONNECTIONS = 10
ACCOUNT_CREATION_SQL = {
    # For some reason newer versions don't like multistatements, so we split them
    "role": [
        """GRANT USAGE ON *.* TO '{username}'@'%'
            IDENTIFIED BY PASSWORD '{password_hash}'
            WITH MAX_USER_CONNECTIONS {max_connections};""",
        "GRANT labsdbuser TO '{username}'@'%';",
        "SET DEFAULT ROLE labsdbuser FOR '{username}'@'%';",
    ],
    "legacy": [
        r"""CREATE USER '{username}'@'%'
            IDENTIFIED BY PASSWORD '{password_hash}';""",
        r"GRANT SELECT, SHOW VIEW ON `%\_p`.* TO '{username}'@'%';",
        r"GRANT ALL PRIVILEGES ON `{username}\_\_%`.* TO '{username}'@'%';",
    ],
}
USER_AGENT = (
    "WMCS Maintain-DBUsers/1.0 "
    "(https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/"
    "Shared_storage#maintain-dbusers;"
    " cloudservices@wikimedia.org) "
    "python-requests/2.12"
)
MYSQL_USERNAME_RE = re.compile("^[su][0-9]")
PAWS_ACCOUNT_RE = re.compile("^p[0-9]")


class APIError(Exception):
    """Simple custom error class for replica_cnf endpoints api errors"""

    pass


class SkipAccount(Exception):
    """Raised when an account has to be skipped."""

    pass


class AccountState(Enum):
    CREATED = "created"
    DELETED = "deleted"
    SKIPPED = "skipped"
    ERRORED = "errored"


def get_headers():
    """
    update default headers with recommended user-agent
    """
    headers = requests.utils.default_headers()
    # https://meta.wikimedia.org/wiki/User-Agent_policy
    headers.update({"User-Agent": USER_AGENT})
    return headers


def should_execute_for_user(username: str, only_users: list[str] = []) -> bool:
    """
    returns True if only_users is empty array or if username is in only_users,
    else returns False.

    This is used when we want to test the code on Live vms but want to limit
    the side effects to only a few accounts (most likely test accounts)
    """
    return not only_users or username in only_users


def commit_to_db(db: pymysql.connections.Connection, dry_run: bool) -> None:
    """
    Conditionally calls the rollback or commit methods of a db client instance
    NOTE: before using this as a safety measure, make sure your sql statement
          is not of the type that causes implicit commit like DROP, GRANT, etc.
          see https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html for more info
    """
    if dry_run:
        db.rollback()
    else:
        db.commit()


def with_replica_cnf_api_logs():
    """
    Handles logging for *_replica_cnf endpoints
    """

    def decorator(fn):
        @wraps(fn)
        def inner(*args, **kwargs):
            try:
                return fn(*args, **kwargs)
            except APIError as error:
                logging.log(logging.ERROR, str(error))
                raise
            except SkipAccount as info:
                logging.log(logging.INFO, str(info))
                raise

        return inner

    return decorator


def generate_new_pw() -> str:
    """
    Generate a new random password
    """
    sysrandom = random.SystemRandom()  # Uses /dev/urandom
    return "".join(sysrandom.choice(PASSWORD_CHARS) for _ in range(PASSWORD_LENGTH))


def mysql_hash(password: str) -> str:
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return "*" + sha1(sha1(password.encode("utf-8")).digest()).hexdigest()


@with_replica_cnf_api_logs()
def write_replica_cnf(
    account_id: str,
    account_type: str,
    uid: str,
    mysql_username: str,
    password: str,
    dry_run: bool,
    config: dict[str, Any],
) -> None:
    """
    Create a replica.my.cnf file in the necessary account_type directory on the api server

    Raises a SkipAccount when the account is not yet ready to be populated.
    """

    if account_type == "paws":
        config_key = "paws"
    else:
        config_key = "tools"
    api_url = config["replica_cnf"][config_key]["root_url"] + "/write-replica-cnf"
    auth = (
        config["replica_cnf"][config_key]["username"],
        config["replica_cnf"][config_key]["password"],
    )
    headers = get_headers()
    data = {
        "account_id": account_id,
        "account_type": account_type,
        "uid": uid,
        "mysql_username": mysql_username,
        "password": password,
        "dry_run": dry_run,
    }

    try:
        response = requests.post(
            url=api_url,
            json=data,
            auth=auth,
            headers=headers,
            timeout=60,
        ).json()

    except Exception as err:  # pylint: disable=broad-except
        raise APIError(
            "Request to create replica.my.cnf file for account_type {0} and ".format(account_type)
            + "account_id {0} failed without response.".format(account_id)
        ) from err

    if response["result"] == "error":
        raise APIError(
            "Request to create replica.my.cnf file for account_type {0} and ".format(account_type)
            + "account_id {0} failed. Reason: {1}".format(account_id, response["detail"]["reason"])
        )

    if response["result"] == "skip":
        raise SkipAccount(response["detail"]["reason"])


@with_replica_cnf_api_logs()
def read_replica_cnf(
    account_id: str, account_type: str, dry_run: bool, config: dict[str, Any]
) -> tuple[str, str]:
    """
    Read the contents of a replica.my.cnf file on the api server
    """

    if account_type == "paws":
        config_key = "paws"
    else:
        config_key = "tools"
    api_url = config["replica_cnf"][config_key]["root_url"] + "/read-replica-cnf"
    auth = (
        config["replica_cnf"][config_key]["username"],
        config["replica_cnf"][config_key]["password"],
    )
    headers = get_headers()
    data = {"account_id": account_id, "account_type": account_type, "dry_run": dry_run}
    response = None

    try:
        response = requests.post(
            url=api_url,
            json=data,
            auth=auth,
            headers=headers,
            timeout=60,
        ).json()
        user_info = (response["detail"]["user"], response["detail"]["password"])
    except Exception as err:  # pylint: disable=broad-except
        if not response or response.get("result", None) != "error":
            response = {"result": "error", "detail": {"reason": str(err)}}

        raise APIError(
            "Request to parse replica.my.cnf file for for account_type {0} ".format(account_type)
            + "and account_id {0} failed. Reason: {1}".format(
                account_id, response["detail"]["reason"]
            )
        ) from err
    return user_info


@with_replica_cnf_api_logs()
def delete_replica_cnf(
    account_id: str, account_type: str, dry_run: bool, config: dict[str, Any]
) -> None:
    """
    Delete a replica.my.cnf file on the api server
    """

    if account_type == "paws":
        config_key = "paws"
    else:
        config_key = "tools"
    api_url = config["replica_cnf"][config_key]["root_url"] + "/delete-replica-cnf"
    auth = (
        config["replica_cnf"][config_key]["username"],
        config["replica_cnf"][config_key]["password"],
    )
    headers = get_headers()
    params = {"account_id": account_id, "account_type": account_type, "dry_run": dry_run}

    response_data = None
    try:
        response = requests.post(
            url=api_url,
            json=params,
            auth=auth,
            headers=headers,
            timeout=60,
        )
        response.raise_for_status()
        response_data = response.json()
    except Exception as err:  # pylint: disable=broad-except
        if not response_data or response_data.get("result", None) != "error":
            response_data = {"result": "error", "detail": {"reason": str(err)}}

        raise APIError(
            f"Request to delete replica.my.cnf file for for account_type {account_type} "
            f"and account_id {account_id} failed with reason '{response_data['detail']['reason']}'"
        ) from err


@with_replica_cnf_api_logs()
def fetch_paws_uids(config: dict[str, Any]) -> list[int]:
    api_url = config["replica_cnf"]["paws"]["root_url"] + "/paws-uids"
    auth = (
        config["replica_cnf"]["paws"]["username"],
        config["replica_cnf"]["paws"]["password"],
    )
    headers = get_headers()
    response = None

    try:
        response = requests.get(
            url=api_url,
            auth=auth,
            headers=headers,
            timeout=60,
        ).json()
        paws_uids = [int(maybe_uid) for maybe_uid in response["detail"]["paws_uids"]]
    except ValueError as err:
        raise APIError(
            "Got something unexpected from the api (non-int uid): {0}".format(str(err))
        ) from err
    except Exception as err:  # pylint: disable=broad-except
        if not response or response.get("result", None) != "error":
            response = {"result": "error", "detail": {"reason": str(err)}}

        raise APIError(
            "Request to fetch paws uids failed. Reason: {0}".format(response["detail"]["reason"])
        ) from err
    return paws_uids


def find_tools(config: dict[str, Any]) -> list[tuple[str, int]]:
    """
    Return list of tools, from canonical LDAP source

    Return a list of tuples of toolname, uid
    """
    with get_ldap_conn(config=config) as conn:
        conn.search(
            search_base="ou=people,ou=servicegroups,dc=wikimedia,dc=org",
            search_filter="(cn=%s.*)" % PROJECT,
            search_scope=ldap3.SUBTREE,
            attributes=["uidNumber", "cn"],
            time_limit=5,
            paged_size=1000,
        )

        users = []
        for response in conn.response:
            attrs = response["attributes"]
            users.append((attrs["cn"][0], attrs["uidNumber"]))

        cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]
        while cookie:
            conn.search(
                search_base="ou=people,ou=servicegroups,dc=wikimedia,dc=org",
                search_filter="(cn=%s.*)" % PROJECT,
                search_scope=ldap3.SUBTREE,
                attributes=["uidNumber", "cn"],
                time_limit=5,
                paged_size=1000,
                paged_cookie=cookie,
            )
            cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]
            for response in conn.response:
                attrs = response["attributes"]
                users.append((attrs["cn"][0], attrs["uidNumber"]))

    return users


def find_tools_users(config: dict[str, Any]) -> list[tuple[str, int]]:
    """
    Return list of tools project users, from LDAP

    Return a list of tuples of username, uid
    """

    with get_ldap_conn(config=config) as conn:
        conn.search(
            search_base="ou=groups,dc=wikimedia,dc=org",
            search_filter="(&(objectclass=groupOfNames)(cn=project-tools))",
            search_scope=ldap3.SUBTREE,
            attributes=["member"],
        )
        members = conn.response[0]["attributes"]["member"]
        users = []
        # TODO: should we support paging here?
        for member_dn in members:
            conn.search(
                search_base=member_dn,
                search_filter="(objectclass=*)",
                search_scope=ldap3.SUBTREE,
                attributes=["uidNumber", "uid"],
                time_limit=5,
            )
            for response in conn.response:
                attrs = response["attributes"]
                # uid is username/shell name of user in ldap
                users.append((attrs["uid"][0], attrs["uidNumber"]))

        return users


def find_paws_users(config: dict[str, Any]) -> list[tuple[str, int]]:
    """
    Return list of PAWS users, from their userhomes

    Return a list of tuples of username, uid
    """
    user_ids = fetch_paws_uids(config=config)
    paws_users: list[tuple[str, int]] = []

    if not user_ids:
        return paws_users

    for uid in user_ids:
        try:
            paws_users.append((str(uid), int(uid)))
        except Exception:  # pylint: disable=broad-except
            # If it doesn't respond with a nice happy reply, assume this is
            # either a blocked user, or the API is not behaving. Should be safe
            # enough to skip.
            # TODO: add a finer point to this
            continue

    return paws_users


def get_ldap_conn(config: dict[str, Any]):
    """
    Return a ldap connection

    Return value can be used as a context manager
    """
    servers = ldap3.ServerPool(
        [ldap3.Server(host, connect_timeout=1) for host in config["ldap"]["hosts"]],
        ldap3.ROUND_ROBIN,
        active=True,
        exhaust=True,
    )

    return ldap3.Connection(
        servers,
        read_only=True,
        user=config["ldap"]["username"],
        auto_bind="DEFAULT",
        password=config["ldap"]["password"],
    )


def get_accounts_db_conn(config: dict[str, Any]) -> pymysql.Connection:
    """
    Return a pymysql connection to the accounts database
    """
    return pymysql.connect(
        host=config["accounts-backend"]["host"],
        user=config["accounts-backend"]["username"],
        password=config["accounts-backend"]["password"],
        db="labsdbaccounts",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


account_finder = {"user": find_tools_users, "tool": find_tools, "paws": find_paws_users}


def harvest_cnf_files(
    dry_run: bool, only_users: list[str], config: dict[str, Any], account_type: str = "tool"
):
    accounts_to_create = account_finder[account_type](config=config)
    try:
        acct_db = get_accounts_db_conn(config=config)
        cur = acct_db.cursor()
        try:
            for account_name, acc_id in accounts_to_create:
                if should_execute_for_user(username=account_name, only_users=only_users):
                    if account_type == "paws":
                        account_id = str(acc_id)
                    else:
                        account_id = account_name
                    mysql_user, pwd_hash = read_replica_cnf(
                        account_id=account_id,
                        account_type=account_type,
                        dry_run=dry_run,
                        config=config,
                    )

                    if mysql_user and pwd_hash:
                        logging.info(
                            "read harvested replica.my.cnf for %s %s",
                            account_type,
                            account_name,
                        )

                    create_acct_sql_str = (
                        """
                        INSERT INTO account (mysql_username, type, username, password_hash)
                        VALUES ('{mysql_user}', '{account_type}', '{account_name}', '{pwd_hash}')
                        ON DUPLICATE KEY UPDATE
                        password_hash = '{pwd_hash}';
                        """
                    ).format(
                        mysql_user=mysql_user,
                        account_type=account_type,
                        account_name=account_name,
                        pwd_hash=pwd_hash,
                    )
                    cur.execute(create_acct_sql_str)
                else:
                    logging.info(
                        """
                        harvest_cnf_files: skipping user %s with account_type %s.
                        for test purposes, this user wasn't included in the list of target users
                        """,
                        account_name,
                        account_type,
                    )
            commit_to_db(db=acct_db, dry_run=dry_run)
        finally:
            cur.close()
    finally:
        acct_db.close()


def harvest_replica_accounts(dry_run: bool, only_users: list[str], config: dict[str, Any]):
    cloud_dbs = []
    try:
        acct_db = get_accounts_db_conn(config=config)
        for host in config["labsdbs"]["hosts"]:
            hostname = host.split(":")[0]
            port = int(host.split(":")[1])

            cloud_dbs.append(
                pymysql.connect(
                    host=hostname,
                    user=config["labsdbs"]["username"],
                    password=config["labsdbs"]["password"],
                    port=port,
                )
            )

        with acct_db.cursor() as read_cur:
            select_from_acct_sql_str = """
                SELECT id, mysql_username, type, username
                FROM account;
                """
            read_cur.execute(select_from_acct_sql_str)
            for row in read_cur:
                for cloud_db in cloud_dbs:
                    sqlhost = "{}:{}".format(cloud_db.host, cloud_db.port)
                    with cloud_db.cursor() as cloud_db_cur:
                        try:
                            show_grants_sql_str = (
                                """
                                SHOW GRANTS FOR '{mysql_username}'@'%%';
                                """
                            ).format(mysql_username=row["mysql_username"])
                            cloud_db_cur.execute(show_grants_sql_str)
                            cloud_db_cur.fetchone()
                            status = "present"
                        except pymysql.err.InternalError as err:
                            # Error code for when no grants exist for user
                            if err.args[0] != 1141:
                                raise
                            logging.info(
                                "No acct found for %s %s in %s",
                                row["type"],
                                row["username"],
                                sqlhost,
                            )
                            status = "absent"

                    with acct_db.cursor() as write_cur:
                        if should_execute_for_user(username=row["username"], only_users=only_users):
                            create_acct_host_sql_str = (
                                """
                                INSERT INTO account_host (account_id, hostname, status)
                                VALUES ('{row_id}', '{sqlhost}', '{status}')
                                ON DUPLICATE KEY UPDATE
                                status = '{status}';
                                """
                            ).format(row_id=row["id"], sqlhost=sqlhost, status=status)
                            write_cur.execute(create_acct_host_sql_str)
                        else:
                            logging.info(
                                """
                                harvest_replica_accounts: skipping user %s with account_type %s.
                                for test purposes, this user wasn't included in the list of target
                                users
                                """,
                                row["username"],
                                row["type"],
                            )
        commit_to_db(db=acct_db, dry_run=dry_run)
        logging.info("Successfully executed  harvest_replica_accounts")
    finally:
        acct_db.close()
        for cloud_db in cloud_dbs:
            cloud_db.close()


def _populate_new_account(
    account_type: str,
    acct_db: pymysql.connections.Connection,
    cur: pymysql.cursors.Cursor,
    new_account: str,
    new_account_id: int,
    dry_run: bool,
    config: dict[str, Any],
) -> None:
    password = generate_new_pw()
    prefix = {"tool": "s", "paws": "p", "user": "u"}
    mysql_username = "{0}{1:d}".format(prefix[account_type], new_account_id)
    create_acct_sql_str = (
        """
        INSERT INTO account (mysql_username, type, username, password_hash)
        VALUES ('{mysql_username}', '{account_type}', '{new_account}', '{mysql_hash}');
        """
    ).format(
        mysql_username=mysql_username,
        account_type=account_type,
        new_account=new_account,
        mysql_hash=mysql_hash(password=password),
    )
    cur.execute(create_acct_sql_str)
    acct_id = cur.lastrowid
    for hostname in config["labsdbs"]["hosts"]:
        create_acct_host_sql_str = (
            """
            INSERT INTO account_host (account_id, hostname, status)
            VALUES ('{acct_id}', '{hostname}', '{status}');
            """
        ).format(acct_id=acct_id, hostname=hostname, status="absent")
        cur.execute(create_acct_host_sql_str)
    # Do this *before* the commit to the db has succeeded
    if account_type == "paws":
        # PAWS users share an LDAP account on disk
        account_id = str(new_account_id)
        uid = str(PAWS_RUNTIME_UID)
    else:
        account_id = str(new_account)
        uid = str(new_account_id)

    kwargs = {
        "account_id": account_id,
        "account_type": account_type,
        "uid": uid,
        "mysql_username": mysql_username,
        "password": password,
        "dry_run": dry_run,
        "config": config,
    }

    try:
        write_replica_cnf(**kwargs)
    except SkipAccount:
        # if a homedir for this account does not exist yet, just ignore
        # it home directory creation (for tools) is currently handled by
        # maintain-kubeusers, and we do not want to race. Tool accounts
        # that get passed over like this will be picked up on the next
        # round
        return

    commit_to_db(db=acct_db, dry_run=dry_run)
    logging.info("Wrote replica.my.cnf for %s %s", account_type, new_account)


def populate_accountsdb(
    dry_run: bool,
    only_users: list[str],
    config: dict[str, Any],
    stats: Counter,
    account_type: str = "tool",
):
    """
    Populate new tools/users into meta db
    """
    all_accounts = account_finder[account_type](config=config)
    try:
        acct_db = get_accounts_db_conn(config=config)
        with acct_db.cursor() as cur:
            # TODO: merge those two when the 'username' column for old PAWS
            # users also has the user ID
            if account_type != "paws":
                select_username_sql_str = (
                    """
                    SELECT username FROM account WHERE type='{account_type}';
                    """
                ).format(account_type=account_type)
                cur.execute(select_username_sql_str)
                cur_accounts = set([r["username"] for r in cur])
                new_accounts = [t for t in all_accounts if t[0] not in cur_accounts]
                all_account_names = [y[0] for y in all_accounts]
                deleted_accts = [x for x in cur_accounts if x not in all_account_names]
            else:
                select_mysql_username_sql_str = (
                    """
                    SELECT mysql_username FROM account WHERE type='{account_type}';
                    """
                ).format(account_type=account_type)
                cur.execute(select_mysql_username_sql_str)
                cur_accounts = set([r["mysql_username"] for r in cur])
                new_accounts = [t for t in all_accounts if "p{}".format(t[1]) not in cur_accounts]
                deleted_accts = []  # Need to check the logic for this on PAWS

            logging.debug(
                "Found %s new %s accounts (%s) and %s removed %s accounts (%s)",
                len(new_accounts),
                account_type,
                ", ".join([t[0] for t in new_accounts]),
                len(deleted_accts),
                account_type,
                ", ".join([t[0] for t in deleted_accts]),
            )
            for new_account, new_account_id in new_accounts:
                if should_execute_for_user(username=new_account, only_users=only_users):
                    try:
                        _populate_new_account(
                            account_type=account_type,
                            acct_db=acct_db,
                            cur=cur,
                            new_account=new_account,
                            new_account_id=new_account_id,
                            dry_run=dry_run,
                            config=config,
                        )
                        stats.labels(
                            account_type=account_type,
                            status=AccountState.CREATED.value,
                            account=new_account,
                        ).inc()
                    except Exception as err:  # pylint: disable=broad-except
                        logging.error("problem populating new account: %s", str(err))
                        stats.labels(
                            account_type=account_type,
                            status=AccountState.ERRORED.value,
                            account=new_account,
                        ).inc()
                else:
                    logging.info(
                        """
                        populate_new_accounts: skipping user %s with account_type %s.
                        for test purposes, this user wasn't included in the list of target users
                        """,
                        new_account,
                        account_type,
                    )
                    stats.labels(
                        account_type=account_type,
                        status=AccountState.SKIPPED.value,
                        account=new_account,
                    ).inc()

            for del_account in deleted_accts:
                if account_type != "paws":  # TODO: consider PAWS
                    if should_execute_for_user(username=del_account, only_users=only_users):
                        try:
                            delete_account(
                                account=del_account,
                                account_type=account_type,
                                dry_run=dry_run,
                                config=config,
                            )
                            logging.info("Deleted account %s %s", account_type, del_account)
                            stats.labels(
                                account_type=account_type,
                                status=AccountState.DELETED.value,
                                account=new_account,
                            ).inc()
                        except Exception:
                            logging.exception(
                                "Unable to delete account %s (type %s)",
                                del_account,
                                account_type,
                            )
                            stats.labels(
                                account_type=account_type,
                                status=AccountState.ERRORED.value,
                                account=new_account,
                            ).inc()
                    else:
                        logging.info(
                            """
                            delete_account: skipping user %s with account_type %s.
                            for test purposes, this user wasn't included in the list of target users
                            """,
                            del_account,
                            account_type,
                        )
                        stats.labels(
                            account_type=account_type,
                            status=AccountState.SKIPPED.value,
                            account=new_account,
                        ).inc()

    finally:
        acct_db.close()


def _create_account(
    grant_type: str,
    mysql_username: str,
    password_hash: str,
    max_connections: int,
    dry_run: bool,
    cloud_db_cur: pymysql.cursors.Cursor,
):
    for statement in ACCOUNT_CREATION_SQL[grant_type]:
        create_acct_sql_str = statement.format(
            username=mysql_username,
            max_connections=max_connections,
            password_hash=password_hash,
        )
        # the norm is to pass dry_run to commit_to_db and let
        # it decide whether to commit or rollback sql queries.
        # For some sql statements that causes implicit commit
        # such as this one, only way to stop them from commiting
        # is not to execute them at all if dry_run is True.
        if not dry_run:
            cloud_db_cur.execute(create_acct_sql_str)


def _drop_user(dry_run: bool, cloud_db_cur: pymysql.cursors.Cursor, username: str):
    drop_user_sql_str = (
        """
        DROP USER '{mysql_username}'@'%';
        """
    ).format(mysql_username=username)
    # the norm is to pass dry_run to commit_to_db and let
    # it decide whether to commit or rollback sql queries.
    # For some sql statements that causes implicit commit
    # such as this one, only way to stop them from commiting
    # is not to execute them at all if dry_run is True.
    if not dry_run:
        cloud_db_cur.execute(drop_user_sql_str)


def _create_user_on_cloud_db(
    grant_type: str,
    mysql_username: str,
    password_hash: str,
    cloud_db: pymysql.Connection,
    dry_run: bool,
    config: dict[str, Any],
):
    max_connections = DEFAULT_MAX_CONNECTIONS
    if mysql_username in config["variances"]:
        # Leaving open the idea that there could be other
        # variances in the future
        max_connections = config["variances"][mysql_username].get(
            "max_connections", DEFAULT_MAX_CONNECTIONS
        )

    if PAWS_ACCOUNT_RE.match(mysql_username) and grant_type == "legacy":
        # Skip toolsdb account creation for PAWS
        return

    with cloud_db.cursor() as cloud_db_cur:
        try:
            _create_account(
                grant_type=grant_type,
                mysql_username=mysql_username,
                max_connections=max_connections,
                password_hash=password_hash,
                dry_run=dry_run,
                cloud_db_cur=cloud_db_cur,
            )
        except pymysql.err.InternalError as err:
            # When on a "legacy" server, it is possible
            # there is an old account that will need cleanup
            # before we create it anew.
            if (
                err.args[0] == 1396
                and grant_type == "legacy"
                and MYSQL_USERNAME_RE.match(mysql_username)
            ):
                _drop_user(dry_run=dry_run, cloud_db_cur=cloud_db_cur, username=mysql_username)
                _create_account(
                    grant_type=grant_type,
                    mysql_username=mysql_username,
                    max_connections=max_connections,
                    password_hash=password_hash,
                    dry_run=dry_run,
                    cloud_db_cur=cloud_db_cur,
                )
            else:
                raise

            commit_to_db(db=cloud_db, dry_run=dry_run)


def _set_as_present_on_accountsdb(acct_db: pymysql.Connection, dry_run: bool, account_host_id: str):
    with acct_db.cursor() as write_cur:
        update_acct_host_sql_str = (
            """
            UPDATE account_host
            SET status='present'
            WHERE id = '{acct_host_id}';
            """
        ).format(acct_host_id=account_host_id)
        write_cur.execute(update_acct_host_sql_str)
        commit_to_db(db=acct_db, dry_run=dry_run)


def _create_accounts_on_host(
    dry_run: bool,
    only_users: list[str],
    config: dict[str, Any],
    hostname: str,
    port: int,
    acct_db: pymysql.Connection,
    only_type: str,
    stats: Counter,
    host_stats: Counter,
):
    # This is needed so it's not undefined in the finally clause if an exception happens
    cloud_db: pymysql.Connection | None = None
    host_key = f"{hostname}:{port}"
    try:
        cloud_db = pymysql.connect(
            host=hostname,
            user=config["labsdbs"]["username"],
            password=config["labsdbs"]["password"],
            port=port,
        )

        grant_type = config["labsdbs"]["hosts"][host_key]["grant-type"]
        with acct_db.cursor() as cur:
            select_acct_sql_str = f"""
                SELECT mysql_username, password_hash, username, hostname, type,
                account_host.id as account_host_id
                FROM account JOIN account_host on account.id = account_host.account_id
                WHERE hostname = '{host_key}' AND status = 'absent';
                """
            cur.execute(select_acct_sql_str)
            for row in cur:
                if only_type != "all" and only_type != row["type"]:
                    logging.debug(
                        (
                            "Skipping user %s as it's account is of type %s but we only care "
                            "about type %s"
                        ),
                        row["username"],
                        row["type"],
                        only_type,
                    )
                    continue

                if should_execute_for_user(username=row["username"], only_users=only_users):
                    try:
                        _create_user_on_cloud_db(
                            password_hash=row["password_hash"].decode("utf-8"),
                            grant_type=grant_type,
                            dry_run=dry_run,
                            mysql_username=row["mysql_username"],
                            config=config,
                            cloud_db=cloud_db,
                        )
                        _set_as_present_on_accountsdb(
                            acct_db=acct_db,
                            account_host_id=row["account_host_id"],
                            dry_run=dry_run,
                        )
                        logging.info(
                            "Created account in %s:%d for %s %s",
                            hostname,
                            port,
                            row["type"],
                            row["username"],
                        )
                        stats.labels(
                            account_type=row["type"],
                            status=AccountState.CREATED.value,
                            host=host_key,
                            account=row["username"],
                        ).inc()
                    except Exception as err:
                        logging.exception(
                            "Unable to create user %s on %s:%d, got exception: %s",
                            row["username"],
                            hostname,
                            port,
                            str(err),
                        )
                        stats.labels(
                            account_type=row["type"],
                            status=AccountState.ERRORED.value,
                            host=host_key,
                            account=row["username"],
                        ).inc()
                        continue
                else:
                    logging.info(
                        """
                        create_accounts: skipping user %s with account_type %s.
                        for test purposes, this user wasn't included in the list of target
                        users
                        """,
                        row["username"],
                        row["type"],
                    )
                    stats.labels(
                        account_type=row["type"],
                        status=AccountState.SKIPPED.value,
                        host=host_key,
                        account=row["username"],
                    ).inc()

    except pymysql.err.OperationalError as exc:
        logging.warning("Could not connect to %s:%d due to %s.  Skipping.", hostname, port, exc)
        host_stats.labels(host=host_key).inc()
        return

    finally:
        try:
            if cloud_db:
                cloud_db.close()
        except pymysql.err.Error as err:
            logging.warning("Could not close connection to %s:%d: %s", hostname, port, err)


def create_accounts_from_accountsdb(
    dry_run: bool,
    only_users: list[str],
    config: dict[str, Any],
    only_type: str,
    stats: Counter,
    host_stats: Counter,
):
    """
    Find hosts with accounts in absent state, and creates them.
    """
    try:
        acct_db = get_accounts_db_conn(config=config)
        for host in config["labsdbs"]["hosts"]:
            hostname = host.split(":")[0]
            port = int(host.split(":")[1])

            _create_accounts_on_host(
                config=config,
                dry_run=dry_run,
                only_users=only_users,
                hostname=hostname,
                port=port,
                acct_db=acct_db,
                only_type=only_type,
                stats=stats,
                host_stats=host_stats,
            )
    finally:
        acct_db.close()


def delete_account(account: str, dry_run: bool, config: dict[str, Any], account_type: str = "tool"):
    """
    Deletes a mysql user account

    - Deletes replica.my.cnf
    - Removes them from accounts db
    - Drops users from labsdbs
    """
    if account_type == "paws":
        # Ensure people use the correct user ID.
        try:
            int(account)
        except ValueError:
            sys.exit("Enter the PAWS user's UID, not the on-wiki name")

    try:
        acct_db = get_accounts_db_conn(config=config)
        for host in config["labsdbs"]["hosts"]:
            hostname = host.split(":")[0]
            port = int(host.split(":")[1])
            cloud_db = pymysql.connect(
                host=hostname,
                user=config["labsdbs"]["username"],
                password=config["labsdbs"]["password"],
                port=port,
            )
            with acct_db.cursor() as cur:
                select_acct_sql_str = f"""
                    SELECT mysql_username, password_hash, username, hostname, type,
                    account_host.id as account_host_id
                    FROM account JOIN account_host on account.id = account_host.account_id
                    WHERE hostname = '{host}' AND username = '{account}' AND
                    type = '{account_type}' AND status = 'present';
                    """
                cur.execute(select_acct_sql_str)
                for row in cur:
                    try:
                        with cloud_db.cursor() as cloud_db_cur:
                            drop_user_sql_str = f" DROP USER '{row['mysql_username']}';"
                            # the norm is to pass dry_run to commit_to_db and let
                            # it decide whether to commit or rollback sql queries.
                            # For some sql statements that causes implicit commit
                            # such as this one, only way to stop them from commiting
                            # is not to execute them at all if dry_run is True.
                            if not dry_run:
                                cloud_db_cur.execute(drop_user_sql_str)
                    except pymysql.err.OperationalError as exc:
                        # Ignore if the user fails to delete, this generally
                        # means that the user already exists.
                        if exc.args[0] == 1396:  # CANNOT_USER
                            logging.warning(
                                "Ignoring deleting user %s on %s, user does not exist",
                                account,
                                host,
                            )
                        else:
                            raise
                    finally:
                        cloud_db.close()

                    with acct_db.cursor() as write_cur:
                        del_acct_host_sql_str = f"""
                            DELETE FROM account_host
                            WHERE id = '{row['account_host_id']}';
                            """
                        write_cur.execute(del_acct_host_sql_str)
                        commit_to_db(db=acct_db, dry_run=dry_run)
                        logging.info(
                            "Deleted %s account in %s for %s",
                            row["type"],
                            host,
                            row["username"],
                        )

        # Now we get rid of the file
        try:
            delete_replica_cnf(
                account_id=account,
                account_type=account_type,
                dry_run=dry_run,
                config=config,
            )

            logging.info("Deleted replica config for %s account %s", account_type, account)
        except Exception:  # pylint: disable=broad-except
            # don't interrupt program flow on error
            pass

        # Now we get rid of the account itself
        with acct_db.cursor() as write_cur:
            del_acct_sql_str = (
                """
                DELETE FROM account
                WHERE type='{type}' AND username='{username}';
                """
            ).format(type=account_type, username=account)
            write_cur.execute(del_acct_sql_str)
            commit_to_db(db=acct_db, dry_run=dry_run)

    finally:
        acct_db.close()


def main() -> None:
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "--config",
        default="/etc/dbusers.yaml",
        help="Path to YAML config file, default - /etc/dbusers.yaml",
    )

    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    argparser.add_argument(
        "--account-type",
        choices=["tool", "user", "paws"],
        help="""
        Type of accounts to harvest|delete|maintain
        default - all
        """,
        default="all",
    )

    argparser.add_argument(
        "action",
        choices=["harvest", "harvest-replicas", "maintain", "delete"],
        help="""
        What action to take.

        harvest:

        Collect information about all existing users from replica.my.cnf files
        and accounts already created in legacy databases, and put them into the
        account database. Runs as a one shot script.

        harvest-replicas:

        Collect information about all existing users account status on the database
        replicas and set the status to absent or present in the account host
        metadata tables.

        maintain:

        Runs as a daemon that watches for new tools and tool users being created,
        creates accounts for them in all the destination dbs, maintains state in the
        account database, and writes out replica.my.cnf files.

        delete:

        Deletes a given user. Provide a username like tools.admin or user shellname,
        not a mysql user name.
        """,
    )
    argparser.add_argument(
        "extra_args",
        nargs="?",
        help="""
        Optional argument used when more info needs to be passed in.

        Currently used with `delete` to pass in a username.
        """,
    )
    argparser_exclusive_group = argparser.add_mutually_exclusive_group()
    argparser_exclusive_group.add_argument(
        "--dry-run",
        action="store_true",
        help="""
        Allows running of the different actions (harvest, maintain, delete etc)
        without committing it to database.
        """,
    )
    argparser_exclusive_group.add_argument(
        "--only-users",
        action="append",
        help="""
        Allow running of the different actions (harvest, maintain, delete etc)
        while commiting only changes for specified users.
        e.g. --only-users user1 --only-users user2
        """,
    )
    args = argparser.parse_args()

    log_lvl = logging.DEBUG if (args.debug or args.dry_run or args.only_users) else logging.INFO

    log_format = "%(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s"
    if args.dry_run:
        log_format = "DRY_RUN:%s" % log_format

    logging.basicConfig(format=log_format, level=log_lvl)

    with open(args.config, encoding="utf8") as f:
        config = yaml.safe_load(f)

    if args.action == "harvest":
        harvest_cnf_files(
            account_type=args.account_type,
            dry_run=args.dry_run,
            only_users=args.only_users,
            config=config,
        )
        harvest_replica_accounts(dry_run=args.dry_run, only_users=args.only_users, config=config)
    elif args.action == "harvest-replicas":
        harvest_replica_accounts(dry_run=args.dry_run, only_users=args.only_users, config=config)
    elif args.action == "maintain":
        all_stats: dict[str, Counter] = {
            "populate": Counter(
                name="maintain_dbusers_populate",
                documentation=(
                    "Number of accounts added/deleted to the accountsdb database of the "
                    "maintain_dbusers process"
                ),
                labelnames=["account_type", "status", "account"],
            ),
            "create": Counter(
                name="maintain_dbusers_create",
                documentation=(
                    "Number of accounts added/deleted from the different clouddb databases "
                    "(replicas, toolsdb, ...) by the maintain_dbusers process"
                ),
                labelnames=["account_type", "status", "host", "account"],
            ),
            "clouddb_issues": Counter(
                name="maintain_dbusers_create_connection_errors",
                documentation=(
                    "Number of connection issues to the different clouddb databases "
                    "(replicas, tooldb, ...) by the maintain_dbusers process"
                ),
                labelnames=["host"],
            ),
        }
        start_http_server(port=config.get("metrics_port", 9090))
        while True:
            if args.account_type in ("tool", "all"):
                populate_accountsdb(
                    account_type="tool",
                    dry_run=args.dry_run,
                    only_users=args.only_users,
                    config=config,
                    stats=all_stats["populate"],
                )
            if args.account_type in ("user", "all"):
                populate_accountsdb(
                    account_type="user",
                    dry_run=args.dry_run,
                    only_users=args.only_users,
                    config=config,
                    stats=all_stats["populate"],
                )
            if args.account_type in ("paws", "all"):
                populate_accountsdb(
                    account_type="paws",
                    dry_run=args.dry_run,
                    only_users=args.only_users,
                    config=config,
                    stats=all_stats["populate"],
                )
            create_accounts_from_accountsdb(
                dry_run=args.dry_run,
                only_users=args.only_users,
                config=config,
                only_type=args.account_type,
                stats=all_stats["create"],
                host_stats=all_stats["clouddb_issues"],
            )
            time.sleep(60)
    elif args.action == "delete":
        if args.extra_args is None:
            logging.error("Need to provide username to delete")
            sys.exit(1)
        if should_execute_for_user(username=args.extra_args, only_users=args.only_users):
            delete_account(
                account=args.extra_args,
                account_type=args.account_type,
                dry_run=args.dry_run,
                config=config,
            )
        else:
            logging.info(
                """
                delete_account: skipping user %s with account_type %s.
                for test purposes, this user wasn't included in the list of target users
                """,
                args.extra_args,
                args.account_type,
            )


if __name__ == "__main__":
    main()
