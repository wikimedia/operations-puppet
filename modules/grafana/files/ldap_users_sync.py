#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2020 Wikimedia Foundation, Inc.
#                    Filippo Giunchedi

# Sync groups of users from WMF LDAP tree to Grafana.

import argparse
import configparser
import logging
import sys
import uuid

import ldap
from wmflib.requests import http_session

LOG = logging.getLogger(__name__)
GRAFANA_ORG = 1
PROTECTED_LOGINS = ["admin"]  # Grafana users to never delete
# LDAP groups and their roles to sync.
# Order matters: users synced first won't be synced again (e.g. a user in two
# groups will have its role set according to which group comes first)
GROUP_ROLES = [
    {"group": "ops", "role": "Admin"},
    {"group": "grafana-admin", "role": "Admin"},
    {"group": "wmf", "role": "Editor"},
    {"group": "nda", "role": "Editor"},
]
RETRY_METHODS = ("PUT", "POST", "PATCH", "DELETE")


class WikimediaLDAP(object):
    def __init__(self, uri):
        self.uri = uri

    def group_uids(self, group):
        ldap_conn = ldap.initialize(self.uri)
        ldap_conn.protocol_version = ldap.VERSION3

        members = []
        ldapdata = ldap_conn.search_s(
            "ou=groups,dc=wikimedia,dc=org",
            ldap.SCOPE_SUBTREE,
            f"(&(objectclass=groupOfNames)(cn={group}))",
            attrlist=["member"],
        )

        for member_dn in ldapdata[0][1]["member"]:
            rdn, _ = str(member_dn).split(",", 1)
            members.append(rdn.split("=", 1)[1])

        return members

    def uid_meta(self, uid):
        ldap_conn = ldap.initialize(self.uri)
        ldap_conn.protocol_version = ldap.VERSION3

        result = ldap_conn.search_s(
            "ou=people,dc=wikimedia,dc=org",
            ldap.SCOPE_SUBTREE,
            f"(&(objectclass=organizationalPerson)(uid={uid}))",
        )
        return result[0][1]


class GrafanaAPI(object):
    def __init__(self, url, auth, timeout=10.0, tries=3, backoff=1.0):
        self.url = url
        self.session = http_session(
            __file__,
            timeout=timeout,
            tries=tries,
            backoff=backoff,
            retry_methods=RETRY_METHODS
        )
        self.session.auth = auth

    def get(self, path, *args, **kwargs):
        return self.session.get(f"{self.url}/api/{path}", *args, **kwargs)

    def put(self, path, *args, **kwargs):
        return self.session.put(f"{self.url}/api/{path}", *args, **kwargs)

    def post(self, path, *args, **kwargs):
        return self.session.post(f"{self.url}/api/{path}", *args, **kwargs)

    def patch(self, path, *args, **kwargs):
        return self.session.patch(f"{self.url}/api/{path}", *args, **kwargs)

    def delete(self, path, *args, **kwargs):
        return self.session.delete(f"{self.url}/api/{path}", *args, **kwargs)


class GrafanaSyncer(object):
    """Sync Grafana with Wikimedia LDAP users."""

    def __init__(self, api, ldap, commit=False, orgid=1):
        self.api = api
        self.ldap = ldap
        self.commit = commit
        self.orgid = orgid
        self.seen_users = set()

    def grafana_users(self):
        res = {}
        r = self.api.get("users")
        for user in r.json():
            login = user["login"]
            if login in res:
                raise ValueError("Duplicate login", login)
            res[login] = user
        return res

    def _create_user(self, login, name, email):
        create_user = {
            "OrgId": self.orgid,
            "email": email,
            "login": login,
            "name": name,
            # Required by the API. Not used when users are logged in via HTTP headers.
            "password": uuid.uuid4().hex,
        }
        r = self.api.post("admin/users", json=create_user)
        r.raise_for_status()
        return r.json()

    def _update_user(self, login, name, email):
        """Update a user's login meta information (name, email) if needed."""

        r = self.api.get(f"users/lookup?loginOrEmail={login}")
        r.raise_for_status()
        meta = r.json()

        if meta["name"] == name and meta["email"] == email:
            return meta

        update_user = {"email": email, "name": name, "login": login, "id": meta["id"]}
        r = self.api.put(f"users/{meta['id']}", json=update_user)
        r.raise_for_status()
        return update_user

    def set_role(self, uid, role):
        r = self.api.patch(f"orgs/{self.orgid}/users/{uid}", json={"role": role})
        r.raise_for_status()
        return r.json()

    def set_grafana_admin(self, uid, status):
        r = self.api.put(
            f"admin/users/{uid}/permissions", json={"isGrafanaAdmin": status}
        )
        r.raise_for_status()
        return r.json()

    def delete_user(self, uid):
        LOG.debug(f"Deleting user {uid}")
        if self.commit:
            r = self.api.delete(f"admin/users/{uid}")
            r.raise_for_status()
            return r.json()

    def sync_ldap_users(self, users, role):
        existing_users = self.grafana_users()

        for user in users:
            if user in self.seen_users:
                LOG.debug(f"User {user} already synced, skipping")
                continue
            meta = self.ldap.uid_meta(user)
            name = meta["cn"][0].decode("utf-8")
            email = meta["mail"][0].decode("utf-8")

            if user not in existing_users:
                LOG.debug(f"Creating user {user} name {name} email {email}")
                if self.commit:
                    grafana_uid = self._create_user(user, name, email)["id"]
            else:
                LOG.debug(f"Updating user {user} name {name} email {email}")
                if self.commit:
                    grafana_uid = self._update_user(user, name, email)["id"]

            LOG.debug(f"Setting role {role} for {user}")
            if self.commit:
                self.set_role(grafana_uid, role)

            if role == "Admin":  # special case, both grafana admin and org admin
                LOG.debug(f"Setting admin for {user}")
                if self.commit:
                    self.set_grafana_admin(grafana_uid, True)
            else:
                LOG.debug(f"Unsetting admin for {user}")
                if self.commit:
                    self.set_grafana_admin(grafana_uid, False)

            self.seen_users.add(user)


def parse_args():
    parser = argparse.ArgumentParser(
        prog="ldap-users-sync",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Sync users from LDAP to Grafana.",
    )

    parser.add_argument(
        "--ldap-uri",
        metavar="URI",
        help="The LDAP uri to use",
        default="ldaps://ldap-ro.eqiad.wikimedia.org:636",
    )
    parser.add_argument(
        "--ldaps-skip-check",
        help="When using LDAPS, skip certificate check (for testing only!)",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--grafana-config",
        metavar="PATH",
        help="Read Grafana config from PATH",
        default="/etc/grafana/grafana.ini",
    )
    parser.add_argument(
        "--delete-users",
        help="Delete users missing from LDAP but present in Grafana",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--timeout",
        help="Request timeout",
        type=float,
        default=10.0,
    )
    parser.add_argument(
        "--retry",
        help="How many retries to attempt",
        type=int,
        default=3,
    )
    parser.add_argument(
        "--retry-backoff-factor",
        help="Retry backoff factor",
        type=float,
        default=1.0,
    )
    parser.add_argument(
        "--commit", help="Commit changes to Grafana", action="store_true", default=False
    )
    parser.add_argument(
        "--debug", help="Turn on debug logging", action="store_true", default=False
    )
    return parser.parse_args(), parser


def main():
    opts, parser = parse_args()

    if opts.debug:
        logging.basicConfig(level=logging.DEBUG)

    if opts.ldaps_skip_check:
        ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

    ldap_api = WikimediaLDAP(opts.ldap_uri)

    # Parse Grafana configuration to get the admin password and port possibly
    grafana_cfg = configparser.ConfigParser()
    if not grafana_cfg.read(opts.grafana_config):
        parser.error(f"Unable to parse Grafana config at {opts.grafana_config}")
        return 1
    # Raise configparser.NoOptionError on password not found
    grafana_password = grafana_cfg.get("security", "admin_password")
    grafana_port = grafana_cfg.getint("server", "http_port", fallback=3000)
    grafana_api = GrafanaAPI(
        f"http://localhost:{grafana_port}", ("admin", grafana_password),
        timeout=opts.timeout,
        tries=opts.retry,
        backoff=opts.retry_backoff_factor
    )

    syncer = GrafanaSyncer(grafana_api, ldap_api, commit=opts.commit, orgid=GRAFANA_ORG)

    # Enforce 'admin' user as Org admin
    if opts.commit:
        syncer.set_role(1, "Admin")

    all_ldap_uids = set()

    for group_config in GROUP_ROLES:
        group = group_config["group"]
        role = group_config["role"]
        ldap_uids = ldap_api.group_uids(group)
        syncer.sync_ldap_users(ldap_uids, role)

        all_ldap_uids.update(ldap_uids)

    if opts.delete_users:
        for login, meta in syncer.grafana_users().items():
            if login in PROTECTED_LOGINS:
                LOG.info(f"User {login} is protected, not deleting")
                continue
            if login not in all_ldap_uids:
                syncer.delete_user(meta["id"])

    return 0


if __name__ == "__main__":
    sys.exit(main())
