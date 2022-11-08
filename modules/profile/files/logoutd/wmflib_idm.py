#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Base module IDM related classes and functions (Python 3.5 version).

See pywmflib for the original version.
"""
from abc import ABC, abstractmethod
from argparse import ArgumentParser, Namespace
from logging import getLogger
from typing import List, Optional

from wmflib.exceptions import WmflibError


class IdmValueError(WmflibError):
    """Raised by the IDM module value errors."""


# We make the description optional to deal with the following issue
# https://github.com/python/mypy/issues/9170
def logoutd_args(description: Optional[str] = None, args: Optional[List] = None) -> Namespace:
    """Logout scripts common CLI for parsing the command line arguments.

    When not using the higher level API :py:class:`wmflib.idm.LogoutdBase`, a user could just
    implement their own script still using the same command line arguments processing, of the
    form::

        from wmflib.idm import logoutd_args
        args = logoutd_args('Some description')
        # write your own script

    Arguments:
        description (str): the description to use
        args (list): A list of arguments to use (used for testing)

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace

    """
    if description is None:
        raise IdmValueError('Must provide a string description')

    parser = ArgumentParser(description=description)
    parser.add_argument('-v', '--verbose', action='count', default=0)
    sub = parser.add_subparsers(dest='command')
    query = sub.add_parser('query', help='display the status of logged-in users')
    query.add_argument(
        '-u',
        '--uid',
        help='The uid of the user to use',
    )
    query.add_argument('-c', '--cn', help='The cn of the user to use')

    sub.add_parser(
        'logout',
        parents=[query],
        add_help=False,
        help='display the status of logged in users',
    )

    sub.add_parser('list', help='list all active sessions')

    return parser.parse_args(args)


class LogoutdBase(ABC):  # noqa: D300,D301 See https://github.com/PyCQA/pydocstyle/issues/542
    """Base class for a standardized API for logout scripts.

    A simple logout.d python script would then be of the form::

        from wmflib.idm import LogoutdBase

        class MyLogoutd(LogoutdBase):
            \"\"\"Some description.\"\"\"

            def logout_user(self, user):
                # logout the given user

            def query_user(self, user):
                # check the login status of a given user

            def list(self):
                # list all active login sessions

        logoutd = MyLogoutd()
        raise SystemExit(logoutd.run())  # This includes the parsing of command line arguments.

    """

    user_identifier = 'cn'

    def __init__(self, args: Optional[List] = None) -> None:
        """Init function.

        Arguments:
            args (list): A list of arguments to use (used for testing)

        """
        self._args = logoutd_args(self.__doc__, args)
        self._logger = getLogger('.'.join((self.__module__, self.__class__.__name__)))

    @property
    def user(self) -> str:
        """Return either common_name or uid with a preference for common_name.

        Returns:
            (str): representing the user

        """
        return getattr(self._args, self.user_identifier)

    @abstractmethod
    def logout_user(self, user: str) -> int:
        """Log out the specified user.

        Arguments:
            user (User): object representing the user

        Returns:
            (int): 0 if the users session was successfully cleared otherwise 1

        """

    @abstractmethod
    def query_user(self, user: str) -> int:
        """Return status of logged in user.

        Arguments:
            user (User): object representing the user

        Returns:
            (int): 1 if the user is logged in otherwise 0

        """

    @abstractmethod
    def list(self) -> int:
        """Return data of all logged in users.

        Returns:
            (int): 0 on success non-zero on fail

        """

    def run(self) -> int:
        """Execute the correct action.

        Returns:
            (int): exit code depends on command

        """
        self._logger.debug('Running action: %s', self._args.command)
        if self._args.command == 'query':
            return self.query_user(self.user)
        if self._args.command == 'logout':
            return self.logout_user(self.user)
        return self.list()
