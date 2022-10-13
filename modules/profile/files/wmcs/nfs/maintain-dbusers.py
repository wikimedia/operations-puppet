#!/usr/bin/python3
"""
This script keeps canonical source of mysql clouddb accounts in a
database, and ensures that it is kept up to date with reality.

The code pattern here is that you have a central data store (the db),
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

## populate_new_accounts ##

 - Find list of tools/users (From LDAP) that aren't in the `accounts` table
 - Create a replica.my.cnf for each of these tools/users
 - Make an entry in the `accounts` table for each of these tools/users
 - Make entries in `account_host` for each of these tools/users, marking them as
   absent

## create_accounts ##

 - Look through `account_host` table for accounts that are marked as 'absent'
 - Create those accounts, and mark them as present.

If we need to add a new clouddb, we can do so the following way:
 - Add it to the config file
 - Insert entries into `account_host` for each tool/user with the new host.
 - Run `create_accounts`

In normal usage, just a continuous process running `populate_new_accounts` and
`create_accounts` in a loop will suffice.

TODO:
  - Support for maintaining per-tool restrictions (number of connections + time)
"""

import argparse
import configparser
from hashlib import sha1
import io
import logging
import random
import re
import string
import subprocess
import sys
import os
import time
from typing import Any, Dict, List, Tuple
import yaml

import ldap3
import pymysql
import netifaces
import requests


PROJECT = "tools"
PAWS_RUNTIME_UID = 52771
PASSWORD_LENGTH = 16
PASSWORD_CHARS = string.ascii_letters + string.digits
DEFAULT_MAX_CONNECTIONS = 10
ACCOUNT_CREATION_SQL = {
    "role": """
        GRANT USAGE ON *.* TO '{username}'@'%'
              IDENTIFIED BY PASSWORD '{password_hash}'
              WITH MAX_USER_CONNECTIONS {max_connections};
        GRANT labsdbuser TO '{username}'@'%';
        SET DEFAULT ROLE labsdbuser FOR '{username}'@'%';
    """,
    "legacy": r"""
        CREATE USER '{username}'@'%'
               IDENTIFIED BY PASSWORD '{password_hash}';
        GRANT SELECT, SHOW VIEW ON `%\_p`.* TO '{username}'@'%';
        GRANT ALL PRIVILEGES ON `{username}\_\_%`.* TO '{username}'@'%';
    """,
}
Account = Tuple[str, int]
Config = Dict[str, Any]
USER_AGENT = (
    "WMCS Maintain-DBUsers/1.0 "
    "(https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/"
    "Shared_storage#maintain-dbusers;"
    " cloudservices@wikimedia.org) "
    "python-requests/2.12"
)


def get_headers():
    """
    update default headers with recommended user-agent
    """
    headers = requests.utils.default_headers()
    # https://meta.wikimedia.org/wiki/User-Agent_policy
    headers.update({"User-Agent": USER_AGENT})
    return headers


def generate_new_pw() -> str:
    """
    Generate a new random password
    """
    sysrandom = random.SystemRandom()  # Uses /dev/urandom
    return "".join([sysrandom.choice(PASSWORD_CHARS) for _ in range(PASSWORD_LENGTH)])


def mysql_hash(password: str) -> str:
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return "*" + sha1(sha1(password.encode("utf-8")).digest()).hexdigest()


def write_replica_cnf(file_path: str, uid: int, mysql_username: str, password: str):
    """
    Write a replica.my.cnf file.

    Will also set the 'immutable' attribute on the file, so users
    can not fuck up their own replica.my.cnf files accidentally.
    """
    replica_config = configparser.ConfigParser()

    replica_config["client"] = {"user": mysql_username, "password": password}
    # Because ConfigParser can only write to a file
    # and not just return the value as a string directly
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    c_file = os.open(file_path, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW)
    try:
        os.write(c_file, replica_buffer.getvalue().encode("utf-8"))
        # uid == gid
        os.fchown(c_file, uid, uid)
        os.fchmod(c_file, 0o400)

        # Prevent removal or modification of the credentials file by users
        subprocess.check_output(["/usr/bin/chattr", "+i", file_path])
    except Exception:
        os.remove(file_path)
        raise
    finally:
        os.close(c_file)


def read_replica_cnf(file_path: str) -> Tuple[str, str]:
    """
    Parse a given replica.my.cnf file

    Return a tuple of mysql username, password_hash
    """
    cp = configparser.ConfigParser()
    cp.read(file_path)
    # sometimes these values have quotes around them
    return (cp["client"]["user"].strip("'"), mysql_hash(cp["client"]["password"].strip("'")))


def find_tools(config: Config) -> List[Account]:
    """
    Return list of tools, from canonical LDAP source

    Return a list of tuples of toolname, uid
    """
    with get_ldap_conn(config=config) as conn:
        conn.search(
            "ou=people,ou=servicegroups,dc=wikimedia,dc=org",
            "(cn=%s.*)" % PROJECT,
            ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
            attributes=["uidNumber", "cn"],
            time_limit=5,
            paged_size=1000,
        )

        users = []
        for resp in conn.response:
            attrs = resp["attributes"]
            users.append((attrs["cn"][0], int(attrs["uidNumber"][0])))

        cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]
        while cookie:
            conn.search(
                "ou=people,ou=servicegroups,dc=wikimedia,dc=org",
                "(cn=%s.*)" % PROJECT,
                ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                attributes=["uidNumber", "cn"],
                time_limit=5,
                paged_size=1000,
                paged_cookie=cookie,
            )
            cookie = conn.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]
            for resp in conn.response:
                attrs = resp["attributes"]
                users.append((attrs["cn"][0], int(attrs["uidNumber"][0])))

    return users


def find_tools_users(config: Config) -> List[Account]:
    """
    Return list of tools project users, from LDAP

    Return a list of tuples of username, uid
    """

    with get_ldap_conn(config=config) as conn:
        conn.search(
            "ou=groups,dc=wikimedia,dc=org",
            "(&(objectclass=groupOfNames)(cn=project-tools))",
            ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
            attributes=["member"],
        )
        members = conn.response[0]["attributes"]["member"]
        users = []
        # TODO: should we support paging here?
        for member_dn in members:
            conn.search(
                member_dn,
                "(objectclass=*)",
                ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                attributes=["uidNumber", "uid"],
                time_limit=5,
            )
            for resp in conn.response:
                attrs = resp["attributes"]
                # uid is username/shell name of user in ldap
                users.append((attrs["uid"][0], int(attrs["uidNumber"][0])))

        return users


def get_global_wiki_user(uid: str) -> Dict:
    api_url = (
        "https://meta.wikimedia.org/w/api.php?action=query&format=json&"
        "meta=globaluserinfo&guiid="
    )
    headers = get_headers()
    resp = requests.get(api_url + uid, headers=headers)
    return resp.json()


def find_paws_users(config: Config) -> List[Account]:
    """
    Return list of PAWS users, from their userhomes

    Return a list of tuples of username, uid
    """
    user_ids = os.listdir("/srv/misc/shared/paws/project/paws/userhomes/")

    paws_users = []
    for uid in user_ids:
        try:
            user_info = get_global_wiki_user(uid=uid)
            paws_users.append((user_info["query"]["globaluserinfo"]["name"], int(uid)))
        except Exception:  # pylint: disable=broad-except
            # If it doesn't respond with a nice happy reply, assume this is
            # either a blocked user, or the API is not behaving. Should be safe
            # enough to skip.
            # TODO: add a finer point to this
            continue

    return paws_users


def get_ldap_conn(config: Config):
    """
    Return a ldap connection

    Return value can be used as a context manager
    """
    servers = ldap3.ServerPool(
        [ldap3.Server(host, connect_timeout=1) for host in config["ldap"]["hosts"]],
        ldap3.POOLING_STRATEGY_ROUND_ROBIN,
        active=True,
        exhaust=True,
    )

    return ldap3.Connection(
        servers,
        read_only=True,
        user=config["ldap"]["username"],
        auto_bind=True,
        password=config["ldap"]["password"],
    )


def get_accounts_db_conn(config: Config):
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


def get_replica_path(account_type: str, name: str) -> str:
    """
    Return path to use for replica.my.cnf for a tool or user
    """
    if account_type == "tool":
        return os.path.join(
            "/srv/tools/shared/tools/project/",
            name[len(PROJECT) + 1 :],  # noqa: E203 Remove `PROJECT.` prefix
            "replica.my.cnf",
        )
    elif account_type == "paws":
        return os.path.join("/srv/misc/shared/paws/project/paws/userhomes/", name, ".my.cnf")
    else:
        return os.path.join("/srv/tools/shared/tools/home/", name, "replica.my.cnf")


def harvest_cnf_files(config: Config, account_type: str = "tool"):
    accounts_to_create = account_finder[account_type](config=config)
    try:
        acct_db = get_accounts_db_conn(config=config)
        cur = acct_db.cursor()
        try:
            for account_name, acc_id in accounts_to_create:
                if account_type == "paws":
                    replica_path = get_replica_path(account_type=account_type, name=str(acc_id))
                else:
                    replica_path = get_replica_path(account_type=account_type, name=account_name)
                if os.path.exists(replica_path):
                    mysql_user, password_hash = read_replica_cnf(file_path=replica_path)
                    cur.execute(
                        """
                    INSERT INTO account (mysql_username, type, username, password_hash)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    password_hash = %s
                    """,
                        (mysql_user, account_type, account_name, password_hash, password_hash),
                    )
                else:
                    logging.info(
                        "Found no replica.my.cnf to harvest for %s %s", account_type, account_name
                    )
            acct_db.commit()
        finally:
            cur.close()
    finally:
        acct_db.close


def harvest_replica_accounts(config: Config):
    labsdbs = []
    try:
        acct_db = get_accounts_db_conn(config=config)
        for host in config["labsdbs"]["hosts"]:
            if ":" in host:
                hostname = host.split(":")[0]
                port = int(host.split(":")[1])
            else:
                hostname = host
                port = 3306
            labsdbs.append(
                pymysql.connect(
                    hostname,
                    config["labsdbs"]["username"],
                    config["labsdbs"]["password"],
                    port=port,
                )
            )

        with acct_db.cursor() as read_cur:
            read_cur.execute(
                """
            SELECT id, mysql_username, type, username
            FROM account
            """
            )
            for row in read_cur:
                for labsdb in labsdbs:
                    sqlhost = labsdb.host
                    if labsdb.port != 3306:
                        sqlhost = "{}:{}".format(labsdb.host, labsdb.port)
                    with labsdb.cursor() as labsdb_cur:
                        try:
                            labsdb_cur.execute(
                                """
                            SHOW GRANTS FOR %s@'%%'
                            """,
                                (row["mysql_username"]),
                            )
                            labsdb_cur.fetchone()
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
                        write_cur.execute(
                            """
                        INSERT INTO account_host (account_id, hostname, status)
                        VALUES (%s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                        status = %s
                        """,
                            (row["id"], sqlhost, status, status),
                        )
        acct_db.commit()
    finally:
        acct_db.close()
        for ldb in labsdbs:
            ldb.close()


def _populate_new_account(
    account_type: str, new_account: str, new_account_id: int, acct_db: str, cur, config: Config
):
    # if a homedir for this account does not exist yet, just ignore
    # it home directory creation (for tools) is currently handled by
    # maintain-kubeusers, and we do not want to race. Tool accounts
    # that get passed over like this will be picked up on the next
    # round
    if account_type == "paws":
        replica_path = get_replica_path(account_type=account_type, name=str(new_account_id))
    else:
        replica_path = get_replica_path(account_type=account_type, name=new_account)

    if not os.path.exists(os.path.dirname(replica_path)):
        logging.debug(
            "Skipping %s account %s, since no home directory exists yet", account_type, new_account
        )
        return
    password = generate_new_pw()
    prefix = {"tool": "s", "paws": "p", "user": "u"}
    mysql_username = "{0}{1:d}".format(prefix[account_type], new_account_id)
    cur.execute(
        """
                INSERT INTO account (mysql_username, type, username, password_hash)
                VALUES (%s, %s, %s, %s)
                """,
        (mysql_username, account_type, new_account, mysql_hash(password)),
    )
    acct_id = cur.lastrowid
    for hostname in config["labsdbs"]["hosts"]:
        cur.execute(
            """
                    INSERT INTO account_host (account_id, hostname, status)
                    VALUES (%s, %s, %s)
                    """,
            (acct_id, hostname, "absent"),
        )
    # Do this *before* the commit to the db has succeeded
    if account_type == "paws":
        # PAWS users share an LDAP account on disk
        write_replica_cnf(
            file_path=replica_path,
            uid=PAWS_RUNTIME_UID,
            mysql_username=mysql_username,
            password=password,
        )
    else:
        write_replica_cnf(
            file_path=replica_path,
            uid=new_account_id,
            mysql_username=mysql_username,
            password=password,
        )
    acct_db.commit()
    logging.info("Wrote replica.my.cnf for %s %s", account_type, new_account)


def populate_new_accounts(config: Config, account_type: str = "tool"):
    """
    Populate new tools/users into meta db
    """
    all_accounts = account_finder[account_type](config=config)
    try:
        acct_db = get_accounts_db_conn(config=config)
        with acct_db.cursor() as cur:
            if account_type != "paws":
                cur.execute(
                    """
                SELECT username FROM account WHERE type=%s
                """,
                    account_type,
                )
                cur_accounts = set([r["username"] for r in cur])
                new_accounts = [t for t in all_accounts if t[0] not in cur_accounts]
                all_account_names = [y[0] for y in all_accounts]
                deleted_accts = [x for x in cur_accounts if x not in all_account_names]
            else:
                cur.execute(
                    """
                SELECT mysql_username FROM account WHERE type=%s
                """,
                    account_type,
                )
                cur_accounts = set([r["mysql_username"] for r in cur])
                new_accounts = [t for t in all_accounts if "p{}".format(t[1]) not in cur_accounts]
                deleted_accts = []  # Need to check the logic for this on PAWS

            logging.debug(
                "Found %s new %s accounts: %s and %s removed %s accounts: %s",
                len(new_accounts),
                account_type,
                ", ".join([t[0] for t in new_accounts]),
                len(deleted_accts),
                account_type,
                ", ".join([t[0] for t in deleted_accts]),
            )
            for new_account, new_account_id in new_accounts:
                try:
                    _populate_new_account(
                        account_type=account_type,
                        new_account=new_account,
                        new_account_id=new_account_id,
                        acct_db=acct_db,
                        cur=cur,
                        config=config,
                    )
                except Exception as err:  # pylint: disable=broad-except
                    logging.error("problem populating new account: %s", str(err))

            for del_account in deleted_accts:
                if account_type != "paws":  # TODO: consider PAWS
                    delete_account(config=config, account=del_account, account_type=account_type)
                    logging.info("Deleted account %s %s", account_type, del_account)

    finally:
        acct_db.close()


def create_accounts(config: Config):
    """
    Find hosts with accounts in absent state, and creates them.
    """
    try:
        acct_db = get_accounts_db_conn(config=config)
        username_re = re.compile("^[su][0-9]")
        paws_account_re = re.compile("^p[0-9]")
        for host in config["labsdbs"]["hosts"]:
            if ":" in host:
                hostname = host.split(":")[0]
                port = int(host.split(":")[1])
            else:
                hostname = host
                port = 3306
            try:
                labsdb = pymysql.connect(
                    hostname,
                    config["labsdbs"]["username"],
                    config["labsdbs"]["password"],
                    port=port,
                )

                grant_type = config["labsdbs"]["hosts"][host]["grant-type"]
                with acct_db.cursor() as cur:
                    cur.execute(
                        """
                    SELECT mysql_username, password_hash, username, hostname, type,
                        account_host.id as account_host_id
                    FROM account JOIN account_host on account.id = account_host.account_id
                    WHERE hostname = %s AND status = 'absent'
                    """,
                        (host,),
                    )
                    for row in cur:
                        username = row["mysql_username"]
                        max_connections = DEFAULT_MAX_CONNECTIONS
                        if username in config["variances"]:
                            # Leaving open the idea that there could be other
                            # variances in the future
                            max_connections = config["variances"][username].get(
                                "max_connections", DEFAULT_MAX_CONNECTIONS
                            )

                        if paws_account_re.match(username) and grant_type == "legacy":
                            # Skip toolsdb account creation for PAWS
                            continue

                        with labsdb.cursor() as labsdb_cur:
                            create_acct_string = ACCOUNT_CREATION_SQL[grant_type].format(
                                username=username,
                                max_connections=max_connections,
                                password_hash=row["password_hash"].decode("utf-8"),
                            )
                            try:
                                labsdb_cur.execute(create_acct_string)
                            except pymysql.err.InternalError as err:
                                # When on a "legacy" server, it is possible
                                # there is an old account that will need cleanup
                                # before we create it anew.
                                if (
                                    err.args[0] == 1396
                                    and grant_type == "legacy"
                                    and username_re.match(row["mysql_username"])
                                ):
                                    labsdb_cur.execute(
                                        "DROP USER '{username}'@'%';".format(
                                            username=row["mysql_username"]
                                        )
                                    )
                                    labsdb_cur.execute(create_acct_string)
                                else:
                                    raise

                            labsdb.commit()

                        with acct_db.cursor() as write_cur:
                            write_cur.execute(
                                """
                            UPDATE account_host
                            SET status='present'
                            WHERE id = %s
                            """,
                                (row["account_host_id"],),
                            )
                            acct_db.commit()
                            logging.info(
                                "Created account in %s for %s %s",
                                host,
                                row["type"],
                                row["username"],
                            )

            except pymysql.err.OperationalError as exc:
                logging.warning("Could not connect to %s due to %s.  Skipping.", host, exc)
                continue
            finally:
                try:
                    labsdb.close()
                except pymysql.err.Error as err:
                    logging.warning("Could not close connection to %s: %s", host, err)
    finally:
        acct_db.close()


def delete_account(config: Config, account: str, account_type: str = "tool"):
    """
    Deletes a mysql user account

    - Deletes replica.my.cnf
    - Removes them from accounts db
    - Drops users from labsdbs
    """
    if account_type == "paws":
        # We have some special issues here. The file path is the UID, not username
        # and we really should enter the UID in general.
        try:
            int(account)
        except ValueError:
            sys.exit("Enter the PAWS user's UID, not the on-wiki name")

        # Intentionally shadow the account arg with what the rest of the script
        # thinks is right.
        acc_info = get_global_wiki_user(uid=account)
        uid = account
        account = acc_info["query"]["globaluserinfo"]["name"]

    try:
        acct_db = get_accounts_db_conn(config=config)
        for host in config["labsdbs"]["hosts"]:
            if ":" in host:
                hostname = host.split(":")[0]
                port = int(host.split(":")[1])
            else:
                hostname = host
                port = 3306
            labsdb = pymysql.connect(
                hostname, config["labsdbs"]["username"], config["labsdbs"]["password"], port=port
            )
            with acct_db.cursor() as cur:
                cur.execute(
                    """
                SELECT mysql_username, password_hash, username, hostname, type,
                    account_host.id as account_host_id
                FROM account JOIN account_host on account.id = account_host.account_id
                WHERE hostname = %s AND username = %s AND type = %s AND status = 'present'
                """,
                    (host, account, account_type),
                )
                for row in cur:
                    try:
                        with labsdb.cursor() as labsdb_cur:
                            labsdb_cur.execute("DROP USER %s" % row["mysql_username"])
                            labsdb.commit()
                        with acct_db.cursor() as write_cur:
                            write_cur.execute(
                                """
                            DELETE FROM account_host
                            WHERE id = %s
                            """,
                                (row["account_host_id"],),
                            )
                            acct_db.commit()
                            logging.info(
                                "Deleted %s account in %s for %s",
                                row["type"],
                                host,
                                row["username"],
                            )
                    finally:
                        labsdb.close()

        # Now we get rid of the file
        replica_file_path = (
            get_replica_path(account_type=account_type, name=account)
            if account_type != "paws"
            else get_replica_path(account_type=account_type, name=uid)
        )
        try:
            subprocess.check_output(["/usr/bin/chattr", "-i", replica_file_path])
            os.remove(replica_file_path)
            logging.info("Deleted %s", replica_file_path)
        except subprocess.CalledProcessError:
            logging.info("Could not delete %s, file probably missing", replica_file_path)

        # Now we get rid of the account itself
        with acct_db.cursor() as write_cur:
            write_cur.execute(
                """
            DELETE FROM account
            WHERE type=%s AND username=%s
            """,
                (account_type, account),
            )
            acct_db.commit()

    finally:
        acct_db.close()


def is_active_nfs(config: Config):
    """
    Return true if current host is the active NFS host

    It looks for an interface attached to the current host that has an IP
    that is the NFS cluster service IP.
    """
    for iface in netifaces.interfaces():
        ifaddress = netifaces.ifaddresses(iface)
        if netifaces.AF_INET not in ifaddress:
            continue
        if any([ip["addr"] == config["nfs-cluster-ip"] for ip in ifaddress[netifaces.AF_INET]]):
            return True
    return False


def main():
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
        Type of accounts to harvest|delete, not useful for maintain
        default - tool
        """,
        default="tool",
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
        creates accounts for them in all the labsdbs, maintains state in the
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
    args = argparser.parse_args()

    log_lvl = logging.DEBUG if args.debug else logging.INFO
    # this is here as the systemd dependency is not available on most dev environments, and not
    # really needed for testing
    from systemd import journal, daemon  # pylint: disable=import-error,import-outside-toplevel

    if daemon.booted():
        logging.basicConfig(
            format="%(message)s", level=log_lvl, handlers=[journal.JournalHandler()]
        )
    else:
        logging.basicConfig(format="%(message)s", level=log_lvl)

    with open(args.config, encoding="utf8") as f:
        config = yaml.safe_load(f)

    if args.action == "harvest":
        harvest_cnf_files(config=config, account_type=args.account_type)
        harvest_replica_accounts(config=config)
    elif args.action == "harvest-replicas":
        harvest_replica_accounts(config=config)
    elif args.action == "maintain":
        while True:
            # Check if we're the primary NFS server.
            # If we aren't, just loop lamely, not exit. This allows this script
            # to run continuously on both labstores, making for easier
            # monitoring given our puppet situation and also easy failover. When
            # NFS primaries are switched, nothing new needs to be done to
            # switch this over.
            if is_active_nfs(config=config):
                populate_new_accounts(config=config, account_type="tool")
                populate_new_accounts(config=config, account_type="user")
                populate_new_accounts(config=config, account_type="paws")
                create_accounts(config=config)
            time.sleep(60)
    elif args.action == "delete":
        if args.extra_args is None:
            logging.error("Need to provide username to delete")
            sys.exit(1)
        delete_account(config=config, account=args.extra_args, account_type=args.account_type)


if __name__ == "__main__":
    main()
