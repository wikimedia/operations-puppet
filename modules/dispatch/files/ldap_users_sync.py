#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2020 Wikimedia Foundation, Inc.
#                    Filippo Giunchedi

# Sync WMF LDAP user info with Dispatch

import argparse
import logging
import sys

import ldap
from wmflib.requests import http_session

LOG = logging.getLogger(__name__)

# LDAP groups and their roles to sync.
# Order matters: users synced first won't be synced again (e.g. a user in two
# groups will have its role set according to which group comes first)
GROUP_ROLES = [
    {"group": "ops", "role": "Owner"},
    {"group": "wmf", "role": "Member"},
    {"group": "nda", "role": "Member"},
]
RETRY_METHODS = ("PUT", "POST", "DELETE")


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


class DispatchAPI(object):
    def __init__(self, url, user, org="wikimedia", timeout=10.0, tries=3, backoff=1.0):
        self.url = url
        self.org = org
        self.session = http_session(
            __file__,
            timeout=timeout,
            tries=tries,
            backoff=backoff,
            retry_methods=RETRY_METHODS,
        )
        self.session.headers = {"x-cas-mail": user}
        self.version = "v1"

    def get(self, path, *args, **kwargs):
        return self.session.get(
            f"{self.url}/api/{self.version}/{self.org}/{path}", *args, **kwargs
        )

    def put(self, path, *args, **kwargs):
        return self.session.put(
            f"{self.url}/api/{self.version}/{self.org}/{path}", *args, **kwargs
        )

    def post(self, path, *args, **kwargs):
        return self.session.post(
            f"{self.url}/api/{self.version}/{self.org}/{path}", *args, **kwargs
        )


class DispatchSyncer(object):
    """Sync Dispatch with Wikimedia LDAP users."""

    def __init__(self, api, ldap, commit=False, projects=None):
        self.api = api
        self.ldap = ldap
        self.commit = commit
        self.seen_users = set()
        if projects is None:
            self.projects = ["sre"]
        else:
            self.projects = projects

    def _collect_by_email(self, obj):
        # XXX add pagination
        params = {"page": 1, "itemsPerPage": 10000}
        res = {}
        r = self.api.get(obj, params=params)
        for item in r.json()["items"]:
            res[item["email"]] = item
        return res

    def dispatch_users(self):
        return self._collect_by_email("users")

    def dispatch_individuals(self):
        return self._collect_by_email("individuals")

    def _update_user_role(self, user, role):
        uid = user["id"]
        json = {"role": role, "id": uid}
        r = self.api.put(f"users/{uid}", json=json)
        r.raise_for_status()
        LOG.info(f"Updated {user['email']} role from {user['role']} to {role}")

    def _update_individual_name(self, individual, name):
        json = {"email": individual["email"], "name": name}
        r = self.api.put(f"individuals/{individual['id']}", json=json)
        r.raise_for_status()
        LOG.info(f"Updated individual {individual['email']} name to {name}")

    def _create_individual(self, project, email, name):
        json = {"email": email, "name": name, "project": {"name": project}}
        r = self.api.post("individuals", json=json)
        r.raise_for_status()
        LOG.info(f"Created individual {email} name in project {project}")

    def sync_ldap_users(self, users, role):
        d_users = self.dispatch_users()
        d_individuals = self.dispatch_individuals()

        for user in users:
            if user in self.seen_users:
                LOG.debug(f"User {user} already synced, skipping")
                continue
            meta = self.ldap.uid_meta(user)
            name = meta["cn"][0].decode("utf-8")
            email = meta["mail"][0].decode("utf-8")

            d_user = d_users.get(email)
            # User has not logged in yet
            if d_user is None:
                continue

            # Update the user's role if needed, users are created on first login
            # and default to role 'Member'
            if role != d_user["role"]:
                LOG.debug(f"Updating {email} role to {role}")
                if self.commit:
                    self._update_user_role(d_user, role)

            # Create or update "individual" contact (with real name from LDAP 'cn')
            d_individual = d_individuals.get(email)
            if d_individual is None:
                for project in self.projects:
                    LOG.debug(f"Creating individual {email} in project {project}")
                    if self.commit:
                        self._create_individual(project, email, name)
            elif name != d_individual["name"]:
                LOG.debug(f"Updating {email} name to {name}")
                if self.commit:
                    self._update_individual_name(d_individual, name)

            self.seen_users.add(user)


def parse_args():
    parser = argparse.ArgumentParser(
        prog="ldap-users-sync",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Sync users from LDAP to Dispatch.",
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
        "--dispatch-api",
        metavar="URL",
        help="Dispatch URL API to talk to",
        default="http://localhost:8000",
    )
    parser.add_argument(
        "--dispatch-org",
        metavar="NAME",
        help="Dispatch organization to sync",
        default="wikimedia",
    )
    parser.add_argument(
        "--dispatch-project",
        metavar="NAME",
        help="Dispatch project to sync (can be specified multiple times)",
        default=["sre"],
        action="append",
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
        "--commit",
        help="Commit changes to Dispatch",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--debug", help="Turn on debug logging", action="store_true", default=False
    )
    return parser.parse_args(), parser


def main():
    opts, parser = parse_args()

    if opts.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if opts.ldaps_skip_check:
        ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

    ldap_api = WikimediaLDAP(opts.ldap_uri)

    dispatch_api = DispatchAPI(
        opts.dispatch_api,
        "sync-ldap-users@wikimedia.bot",
        opts.dispatch_org,
        timeout=opts.timeout,
        tries=opts.retry,
        backoff=opts.retry_backoff_factor,
    )

    syncer = DispatchSyncer(
        dispatch_api, ldap_api, projects=opts.dispatch_project, commit=opts.commit
    )

    for group_config in GROUP_ROLES:
        group = group_config["group"]
        role = group_config["role"]
        ldap_uids = ldap_api.group_uids(group)
        syncer.sync_ldap_users(ldap_uids, role)

    return 0


if __name__ == "__main__":
    sys.exit(main())
