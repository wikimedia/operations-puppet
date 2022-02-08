#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""A simple example of how to access the Google Analytics API."""

import json

from argparse import ArgumentParser
from configparser import ConfigParser
from os import access, environ, R_OK
from textwrap import dedent, indent

from apiclient.discovery import build
from google.oauth2 import service_account
from requests import get
from requests.exceptions import RequestException
from spicerack import Spicerack
from spicerack.remote import RemoteExecutionError


class GsuiteUsers:
    """Class for listing Gsuite managed users"""

    api_name = 'admin'
    api_version = 'directory_v1'
    scopes = ['https://www.googleapis.com/auth/admin.directory.user.readonly']

    def __init__(self, key_file_location, impersonate=None):
        self.key_file_location = key_file_location
        self.impersonate = impersonate
        self.domain = self.impersonate.split('@', 1)[1]
        self._credentials = None
        self._service = None

    @property
    def credentials(self):
        """Return a credentials object"""
        if self._credentials is None:
            self._credentials = service_account.Credentials.from_service_account_file(
                self.key_file_location, scopes=self.scopes
            )
            if self.impersonate is not None:
                self._credentials = self._credentials.with_subject(self.impersonate)
        return self._credentials

    @property
    def service(self):
        """Return a service object"""
        if self._service is None:
            self._service = build(
                self.api_name, self.api_version, credentials=self.credentials
            )
        return self._service

    def emails(self):
        """A generator to list all emails managed by gsuite"""
        page_token = None
        while True:
            results = self.get_users(page_token)
            for data in results.get('users', []):
                yield data['primaryEmail']
                for alias in data.get('aliases', []):
                    yield alias
            page_token = results.get('nextPageToken')
            if page_token is None:
                break

    def get_users(self, page_token=None, max_results=25):
        """Get a list of users"""
        return (
            self.service.users()
            .list(domain=self.domain, maxResults=max_results, pageToken=page_token)
            .execute()
        )

    def get_user(self, email):
        """Get a users object from the primary email address

        Parameters:
            email (str): The primary email address of the user

        Returns:
            : An object representing the user

        """
        return self.service.users().get(userKey=email).execute()


def get_wikitech_user(email: str) -> None:
    """Get the wikitech username, email and authenticated_email attributes from wikitech

    Arguments:
        email (str):  The email to query

    """
    spicerack = Spicerack(dry_run=False)
    confctl = spicerack.confctl('mwconfig')
    primary_site = next(confctl.get(scope='common', name='WMFMasterDatacenter')).val
    mwmaint = spicerack.remote().query(f'A:mw-maintenance and A:{primary_site}')
    command = (
        'mwscript extensions/WikimediaMaintenance/getUsersByEmail.php '
        f'--wiki=labswiki --email {email}'
    )
    if len(mwmaint) > 1:
        raise ValueError('to many mwmaint hosts')
    print('WikiTech Users:')
    try:
        _, results = next(
            mwmaint.run_sync(command, print_output=False, print_progress_bars=False)
        )
    except RemoteExecutionError:
        print(f'\tno user found with {email}')
        return

    results = json.loads(results.message().decode())
    for user in results:
        verified = (
            user['email_authenticated_date']
            if user['email_authenticated_date']
            else '*NO*'
        )
        print(f'\tUsername:\t{user["username"]}\n\tVerified Email:\t{verified}\n')


def get_namely_users(api_key: str, email: str) -> int:
    """Get the c$user details from namely API.

    Arguments:
        api_key (str):  The api key
        email (str):  The email to query

    Returns:
        int: exit code

    """
    api_url = 'https://wikimedia.namely.com/api/v1/profiles'
    headers = {'Authorization': f"Bearer {api_key}", 'Accept': 'application/json'}
    params = {'filter[email]': email}
    print('Namely Users:')
    try:
        response = get(api_url, headers=headers, params=params)
        response.raise_for_status()
    except RequestException as error:
        print(f"\tError fetching namley data: {error}")
        return 1
    json_resp = response.json()
    for user in json_resp['profiles']:
        msg = f"""
        Name:\t\t{user['preferred_name']}
        Groups:\t\t{', '.join(r['name'] for r in user['links']['groups'])}
        Title:\t\t{user['job_title']['title']}
        Type:\t\t{user['employee_type']['title']}
        Status:\t\t{user['user_status']}
        Reports to:\t{', '.join(r['preferred_name'] for r in user['reports_to'])}"""
        print(indent(dedent(msg), '\t'))
    return 0


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-i', '--impersonate', help='A super admin email address')
    parser.add_argument(
        '-c',
        '--config',
        default='/etc/check_user.conf',
        help='Location of the config file',
    )
    parser.add_argument(
        '-K', '--key-file', help='The path to a valid service account JSON key file'
    )
    parser.add_argument('-p', '--proxy-host', help='The proxy host to use')
    parser.add_argument('-A', '--namely-api-key', help='Api key for namely server')
    parser.add_argument('email', help='The primary email address of the user')
    return parser.parse_args()


def main():
    """Main entry point"""
    args = get_args()
    config = ConfigParser()
    exit_code = 0
    if access(args.config, R_OK):
        config.read(args.config)
    # prefer arguments to config file
    try:
        impersonate = (
            args.impersonate if args.impersonate else config['DEFAULT']['impersonate']
        )
        key_file = args.key_file if args.key_file else config['DEFAULT']['key_file']
        proxy = (
            args.proxy_host
            if args.proxy_host
            else config['DEFAULT'].get('proxy_host', None)
        )
        namely_api_key = (
            args.namely_api_key
            if args.namely_api_key
            else config['DEFAULT'].get('namely_api_key')
        )
    except KeyError as error:
        return 'no {} specified'.format(error)
    if not access(key_file, R_OK):
        return 'unable to access {}'.format(key_file)

    # need to do this before setting the proxy
    get_wikitech_user(args.email)
    if proxy:
        # the google api libraries use httplib2 which by default
        # looks in the environment for proxy servers
        environ['https_proxy'] = proxy
    if namely_api_key is not None:
        exit_code = get_namely_users(namely_api_key, args.email)

    users = GsuiteUsers(key_file, impersonate)
    user = users.get_user(args.email)
    try:
        # I dont think there would ever be more then one manager but just in case
        manager = ', '.join(
            [r['value'] for r in user['relations'] if r['type'] == 'manager']
        )
    except KeyError:
        # Seems that the gsuite data is no missing a value for the manager
        manager = 'No manager found.'
    try:
        title = user['organizations'][0]['title']
    except KeyError:
        # Seems that the gsuite data is now also missing a value for the title
        title = 'No title found.'
    msg = f"""
    Gsuite User:
    \tPrimary Email:\t{user['primaryEmail']}
    \tAliases:\t{','.join(user.get('aliases', []))}
    \ttitle:\t\t{title}
    \tmanager:\t{manager}
    \tagreedToTerms:\t{user['agreedToTerms']}
    """
    print(dedent(msg))
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
