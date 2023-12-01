#!/usr/bin/python3
# -*- coding: utf-8 -*-

import json
import subprocess
from wmflib.idm import LogoutdBase


class SystemdLogind(LogoutdBase):
    """systemdlogind"""

    user_identifier = 'uid'

    # Return codes follow the logout.d semantics, see T283242
    def logout_user(self, user):
        if subprocess.run(["/bin/loginctl", "--no-pager", "user-status", user],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                          check=False).returncode != 0:
            return 0

        # terminate-user closes all session associated with a user. With the default
        # setting of KillUserProcesses of logind.conf this doesn't close tmux sessions
        # As such, to make sure those are terminated as well, run kill-user in addition
        for logout_cmd in ['terminate-user', 'kill-user']:
            try:
                output = subprocess.check_output(["/bin/loginctl", logout_cmd, user],
                                                 universal_newlines=True).strip()
            except subprocess.CalledProcessError as error:
                print('Failed to run {} for {}: {}'.format(logout_cmd, user, error.returncode))
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
            output = subprocess.check_output(["/bin/loginctl", "--no-pager", "user-status",
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
