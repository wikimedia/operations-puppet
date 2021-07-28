#!/usr/bin/python3
import configparser
import subprocess

from wmflib.idm import LogoutdBase


class WikitechLogoutd(LogoutdBase):
    """Log out the specific user from Wikitech."""
    user_identifier = 'cn'

    # Return codes follow the logout.d semantics, see T283242
    def logout_user(self, user: str):
        config = configparser.ConfigParser()
        config.read('/etc/wikitech-logoutd.ini')
        dbname = config.get('wikitech', 'dbname')

        try:
            command = [
                '/usr/local/bin/mwscript',
                'maintenance/invalidateUserSessions.php',
                '--wiki',
                dbname,
                '--user',
                user
            ]

            output = subprocess.check_output(command, universal_newlines=True).strip()
        except subprocess.CalledProcessError as error:
            print('Failed to logout user {}: {}'.format(user, error.returncode))
            return 1

        if self._args.verbose:
            print(output)

        return 0

    def query_user(self, user: str):
        # no way to know afaik, so assume the user is logged in
        return 1

    def list(self):
        pass


logoutd = WikitechLogoutd()
raise SystemExit(logoutd.run())  # This includes the parsing of command line arguments.
