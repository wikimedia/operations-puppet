# -*- coding: utf-8 -*-
#
# This file is a cut down and slightly modified part of IRC Bot Behavior Bundle
# (IB3)
# Copyright (C) 2017 Bryan Davis and contributors
# Modified August 2018 by Alex Monk <krenair@gmail.com> for python-irc 8.5.3
#  compatibility.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

import base64
import logging

logger = logging.getLogger(__name__)


class AbstractAuth(object):
    """Base class for authentication mixins."""
    def __init__(
            self, server_list, nickname, realname,
            ident_password, username=None, **kwargs):
        """
        :param server_list: List of servers the bot will use.
        :param nickname: The bot's nickname
        :param realname: The bot's realname
        :param ident_password: The bot's password
        :param username: IRC username (default: nickname)
        """
        self._username = username or nickname
        self._ident_password = ident_password

        super(AbstractAuth, self).__init__(
                server_list=server_list,
                nickname=nickname,
                realname=realname,
                username=self._username,
                **kwargs)


class SASL(AbstractAuth):
    """Authenticate using SASL before joining channels."""
    def __init__(self, *args, **kwargs):
        super(SASL, self).__init__(*args, **kwargs)
        self.ircobj._on_connect = self._handle_connect

        for event in ['cap', 'authenticate', '903', '908', 'welcome']:
            logger.debug('Registering for %s', event)
            self.connection.add_global_handler(
                event, getattr(self, '_handle_%s' % event))

    def _handle_connect(self, sock):
        """Send CAP REQ :sasl on connect."""
        self.connection.cap('REQ', 'sasl')

    def _handle_cap(self, conn, event):
        """Handle CAP responses."""
        if event.arguments and event.arguments[0] == 'ACK':
            conn.send_raw('AUTHENTICATE PLAIN')
        else:
            logger.warning('Unexpcted CAP response: %s', event)
            conn.disconnect()

    def _handle_authenticate(self, conn, event):
        """Handle AUTHENTICATE responses."""
        if event.target == '+':
            creds = '{username}\0{username}\0{password}'.format(
                username=self._username,
                password=self._ident_password)
            conn.send_raw('AUTHENTICATE {}'.format(
                    base64.b64encode(creds.encode('utf8')).decode('utf8')))
        else:
            logger.warning('Unexpcted AUTHENTICATE response: %s', event)
            conn.disconnect()

    def _handle_903(self, conn, event):
        """Handle 903 RPL_SASLSUCCESS responses."""
        self.connection.cap('END')

    def _handle_908(self, conn, event):
        """Handle 908 RPL_SASLMECHS responses."""
        logger.warning('SASL PLAIN not supported: %s', event)
        self.die()

    def _handle_welcome(self, conn, event):
        """Handle WELCOME message."""
        logger.info('Connected to server %s', conn.get_server_name())
