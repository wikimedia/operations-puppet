#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

import configparser
import json
import os

import redis
import requests

from wmflib.idm import LogoutdBase


class Tgt:
    def __init__(self, exists, principal, tgt):
        self.exists = exists
        self.principal = principal
        self.tgt = tgt


class IdpLogoutd(LogoutdBase):
    """idp"""

    user_identifier = 'cn'
    cfg = configparser.ConfigParser()
    idp_prefix = ''

    def __init__(self, args=None):
        super().__init__(args)

        try:
            # The cas.properties is not a standard .ini file to prepend a dummy section
            with open("/etc/cas/config/cas.properties") as stream:
                self.cfg.read_string("[dummy]\n" + stream.read())
                self.idp_prefix = self.cfg.get("dummy", "cas.server.prefix")

        except IOError as e:
            print("Failed to open cas.properties file: {}".format(e))
            return 1

        self.r = redis.Redis(
            host=self.cfg.get("dummy", "cas.ticket.registry.redis.host"),
            port=self.cfg.get("dummy", "cas.ticket.registry.redis.port"),
            db=self.cfg.get("dummy", "cas.ticket.registry.redis.database"),
            password=self.cfg.get("dummy", "cas.ticket.registry.redis.password")
        )

    def list_keys(self, cn=None):
        # Get all TGTs in Redis. If the user have signed in before and after a
        # server switch over, they will have a ticket for each of the IDP hosts,
        # as the host name is embedded in the TGT.
        # E.g. TGT-1-********VJizN-B-idp-test1005
        keys = self.r.keys("CAS_TICKET:TGT:TGT*")

        tgts = []
        # Find all the tickets for the given CN.
        for key in keys:

            # We are only interested in the user TGTs, which are all hashmaps.
            # There are other keys with a similar naming, which are sets, we do
            # not need those and accessing them with hmget will throw an type
            # exception.
            if self.r.type(key) != b"hash":
                continue

            principal, tgt = self.r.hmget(key, 'principal', 'ticketId')

            # Check for CN/principal, if provided, otherwise return all keys.
            if cn is not None and principal.decode() != cn:
                continue
            tgts.append(Tgt(True, principal.decode(), tgt.decode()))

        return tgts

    def query_tgt(self, cn):
        return self.list_keys(cn)

    # Return codes follow the logout.d semantics, see T283242
    def logout_user(self, user):
        tgts = self.query_tgt(user)
        state = [0, ]
        for tgt in tgts:
            state.append(self.logout_query(user, tgt))
        return max(state)

    def logout_query(self, user, tgt):
        url = "{}/api/ssoSessions/{}".format(self.idp_prefix, tgt.tgt)

        response = requests.delete(url)

        if response.status_code == 200:
            if tgt.tgt:
                returned_tgt = response.json()['ticketGrantingTicket']
                if tgt.tgt != returned_tgt:
                    print("Something went wrong, terminated TGT doesn't match the requested one")
                    return 1

            if self._args.verbose:
                if tgt.tgt:
                    print("User {} has been logged off and TGT {} was invalidated".
                          format(user, tgt.tgt))
                else:
                    print("No TGT for user {} existed, they were probably already logged out".
                          format(user))
            return 0
        else:
            return 1

    def list(self):
        tgts = self.list_keys()
        for tgt in tgts:
            print(json.dumps({
                    'user': tgt.principal,
                    'TGT': tgt.tgt
                }))

    # Return codes follow the logout.d semantics, see T283242
    def query_user(self, user):
        tgts = self.query_tgt(user)
        res = {
            'id': user,
            'active': 'active' if tgts else 'inactive',
            'verbose': ''}

        print(json.dumps(res))
        return 1 if tgts else 0


if os.geteuid() != 0:
    print("Logout script needs to be run as root")
    raise SystemExit(1)

idplogoutd = IdpLogoutd()
raise SystemExit(idplogoutd.run())  # This includes the parsing of command line arguments.
