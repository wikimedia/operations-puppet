#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

import json
import os
import subprocess
import datetime
import glob
import requests
import configparser
from wmflib.idm import LogoutdBase


class Tgt:
    def __init__(self, exists, tgt):
        self.exists = exists
        self.tgt = tgt


class IdpLogoutd(LogoutdBase):
    """idp"""

    user_identifier = 'cn'

    def query_tgt(self, cn):
        memcached_host = 'localhost:11000'
        max_tgt_lifetime = 7  # Max ticket lifetime is seven days
        logfile_globbing = '/var/log/cas/cas_audit*log'
        logs_processed = 0
        base_cmd = ['/usr/local/sbin/return-tgt-for-user', '-u', cn, '-s', memcached_host, '-f']

        max_log_age = datetime.datetime.now() - datetime.timedelta(days=max_tgt_lifetime)
        for f in glob.glob(logfile_globbing):
            logs_processed += 1
            if (datetime.datetime.fromtimestamp(os.path.getmtime(f)) > max_log_age):
                base_cmd.append(f)

        if not logs_processed:
            return Tgt(False, "")
        else:
            try:
                output = subprocess.check_output(base_cmd, universal_newlines=True).strip()
            except subprocess.CalledProcessError:
                return Tgt(False, "")

        return Tgt(True, output)

    # Return codes follow the logout.d semantics, see T283242
    def logout_user(self, user):
        try:
            cfg = configparser.ConfigParser()
            # The cas.properties is not a standard .ini file to prepend a dummy section
            with open("/etc/cas/config/cas.properties") as stream:
                cfg.read_string("[dummy]\n" + stream.read())
                idp_prefix = cfg.get("dummy", "cas.server.prefix")

        except IOError as e:
            print("Failed to open cas.properties file: {}".format(e))
            return 1

        tgt = self.query_tgt(user)
        url = "{}api/ssoSessions/{}".format(idp_prefix, tgt.tgt)

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
        pass

    # Return codes follow the logout.d semantics, see T283242
    def query_user(self, user):
        res = {}
        res['id'] = user
        # TODO if verbose is enabled we could print since when a user is logged in
        res['verbose'] = ''

        tgt = self.query_tgt(user)

        if tgt.exists:
            res['active'] = "active"
            print(json.dumps(res))
            return 1
        else:
            res['active'] = "inactive"
            print(json.dumps(res))
            return 0


if os.geteuid() != 0:
    print("Logout script needs to be run as root")
    raise SystemExit(1)

idplogoutd = IdpLogoutd()
raise SystemExit(idplogoutd.run())  # This includes the parsing of command line arguments.
