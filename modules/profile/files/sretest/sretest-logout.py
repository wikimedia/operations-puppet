#!/usr/bin/python3
# -*- coding: utf-8 -*-

import json
import subprocess
from wmflib.idm import LogoutdBase


class SystemdLogind(LogoutdBase):
    """sretest"""

    user_identifier = 'uid'

    # Return codes follow the logout.d semantics, see T283242
    def logout_user(self, user):
        try:
            output = subprocess.check_output(["/usr/bin/loginctl", "terminate-user", user],
                                             universal_newlines=True).strip()
        except subprocess.CalledProcessError as error:
            print('Failed to logout user {}: {}'.format(user, error.returncode))
            return 1

        if self._args.verbose:
            print(output)
        return 0

    def list(self):
        pass

    # Return codes follow the logout.d semantics, see T283242
    def query_user(self, user):
        output = ""
        print(user)
        res = {'id': user}

        try:
            output = subprocess.check_output(["/usr/bin/loginctl", "--no-pager", "user-status",
                                              user], universal_newlines=True).strip()
        except subprocess.CalledProcessError as error:
            res['active'] = 'unknown'
            res['verbose'] = error.output
            print(json.dumps(res))
            return 0

        if output:
            res['active'] = "active"
        else:
            res['active'] = "inactive"

        res['verbose'] = output
        print(json.dumps(res))
        return 1


systemdlogoutd = SystemdLogind()
raise SystemExit(systemdlogoutd.run())  # This includes the parsing of command line arguments.
