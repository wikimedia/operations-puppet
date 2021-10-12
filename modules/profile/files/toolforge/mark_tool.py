#!/usr/bin/python3
# Copyright 2021 Andrew Bogott for the Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
import argparse
import configparser
import datetime
import exception
import ldap
import ldap.modlist

# this is a special ref that indicates an entry has been disabled
LDAP_DISABLED_POLICY_ENTRY = b"cn=disabled,ou=ppolicies,dc=wikimedia,dc=org"

# this is a special case datestamp that indicates a tool should be deleted ASAP
LDAP_LOCKED_TIME_DELETE = b"000001010000Z"

LDAP_GENERAL_TIME_FORMAT = "%Y%m%d%H%M%S.%fZ"

DISABLED_LOGINSHELL = b"/bin/disabledtoolshell"
ENABLED_LOGINSHELL = b"/bin/bash"


def _getLdapInfo(attr, conffile="/etc/ldap.conf"):
    try:
        f = open(conffile)
    except IOError:
        if conffile == "/etc/ldap.conf":
            # fallback to /etc/ldap/ldap.conf, which will likely
            # have less information
            f = open("/etc/ldap/ldap.conf")
    for line in f:
        if line.strip() == "":
            continue
        if line.split()[0].lower() == attr.lower():
            return line.split(None, 1)[1].strip()
            break


def _open_ldap(args):
    ldapHost = _getLdapInfo("uri")
    sslType = _getLdapInfo("ssl")

    binddn = args.ldap_user
    bindpw = args.ldap_password
    ds = ldap.initialize(ldapHost)
    ds.protocol_version = ldap.VERSION3
    if sslType == "start_tls":
        ds.start_tls_s()

    ds.simple_bind_s(binddn, bindpw)
    return ds

    return None


def _get_tool_dn(args):
    return "uid=%s.%s,%s" % (args.project, args.tool, args.ldap_base_dn)


def _get_ldap_entry(args, ds):
    dn = _get_tool_dn(args)
    # The ['+'] here is to include operational attributes pwdAccountLockedTime
    #  and pwdPolicySubentry:
    entry = ds.search_s(dn, ldap.SCOPE_BASE, "(objectclass=*)", ["*", "+"])
    return entry


def disable_tool(args, delete=False):
    dn = _get_tool_dn(args)
    ds = _open_ldap(args)
    if not ds:
        print("Failed to connect to ldap.")
        raise exception.ValidationError()

    existingEntry = _get_ldap_entry(args, ds)

    oldEntry = existingEntry[0][1]
    newEntry = oldEntry.copy()
    newEntry["pwdPolicySubentry"] = [LDAP_DISABLED_POLICY_ENTRY]
    newEntry["loginShell"] = [DISABLED_LOGINSHELL]
    if delete:
        newEntry["pwdAccountLockedTime"] = [LDAP_LOCKED_TIME_DELETE]
    else:
        newEntry["pwdAccountLockedTime"] = [
            datetime.datetime.now().strftime(LDAP_GENERAL_TIME_FORMAT).encode("utf8")
        ]

    modlist = ldap.modlist.modifyModlist(oldEntry, newEntry)
    modlist = ldap.modlist.modifyModlist(oldEntry, newEntry)
    ds.modify_s(dn, modlist)


def enable_tool(args):
    dn = _get_tool_dn(args)
    ds = _open_ldap(args)
    if not ds:
        print("Failed to connect to ldap.")
        raise exception.ValidationError()

    existingEntry = _get_ldap_entry(args, ds)

    oldEntry = existingEntry[0][1]
    newEntry = oldEntry.copy()
    newEntry["pwdPolicySubentry"] = []
    newEntry["pwdAccountLockedTime"] = []
    newEntry["loginShell"] = [ENABLED_LOGINSHELL]

    modlist = ldap.modlist.modifyModlist(oldEntry, newEntry)
    ds.modify_s(dn, modlist)


if __name__ == "__main__":

    config = configparser.ConfigParser()
    config.read("/etc/mark_tool.conf")

    argparser = argparse.ArgumentParser(
        "mark_tool",
        description="Disable or delete toolforge tool accounts. All actions are idempotent.",
    )

    argparser.add_argument(
        "--ldap-user",
        help="dn to use for editing ldap entries",
        default=config.get("ldap", "user"),
    )
    argparser.add_argument(
        "--ldap-password",
        help="ldap user password",
        default=config.get("ldap", "password"),
    )
    argparser.add_argument(
        "--ldap-base-dn",
        help="dn containing tool entries, e.g. 'ou=people,ou=servicegroups,dc=wikimedia,dc=org'",
        default=config.get("ldap", "basedn"),
    )
    argparser.add_argument(
        "--project",
        help="Openstack project (e.g. 'tools')",
        default=config.get("default", "project"),
    )

    argparser.add_argument(
        "--disable",
        dest="disable",
        action="store_true",
        help="disable tool and mark for future deletion",
    )

    argparser.add_argument(
        "--delete", dest="delete", action="store_true", help="delete tool immediately"
    )

    argparser.add_argument(
        "--enable", dest="enable", action="store_true", help="enable disabled tool"
    )

    argparser.add_argument("tool", help="tool name")
    args = argparser.parse_args()

    if (
        (args.delete and args.enable)
        or (args.delete and args.disable)
        or (args.disable and args.enable)
    ):
        print("Only one of delete, disable, or enable may be set.")
        exit(1)

    try:
        if args.disable:
            disable_tool(args, delete=False)
        elif args.delete:
            disable_tool(args, delete=True)
        elif args.enable:
            enable_tool(args)
        else:
            print(
                "Without setting one of delete, disable, or enable, nothing will happen."
            )
            exit(1)
    except ldap.NO_SUCH_OBJECT:
        print("No such tool %s (%s)" % (args.tool, _get_tool_dn(args)))
        exit(1)
