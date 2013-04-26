#!/usr/bin/env python
# -*- coding: utf8 -*-
"""
TCP -> IRC forwarder bot
Forward data from a TCP socket to an IRC channel

Usage: tcpircbot.py CONFIGFILE

CONFIGFILE should be a JSON file with the following structure:

  {
      "irc": {
          "channel": "#wikimedia-operations",
          "network": ["irc.freenode.net", 7000, "serverpassword"],
          "nickname": "tcpircbot",
          "ssl": true
      },
      "tcp": {
          "max_clients": 5,
          "port": 9125
      }
  }

Requires irclib >=0.4.8 <http://bitbucket.org/jaraco/irc>
Available in Ubuntu as 'python-irclib'

"""
import sys
reload(sys)
sys.setdefaultencoding('utf8')

import atexit
import codecs
import json
import logging
import os
import select
import socket

try:
    # irclib 0.7+
    import irc.bot as ircbot
except ImportError:
    import ircbot


BUFSIZE = 460  # Read from socket in IRC-message-sized chunks.
AF = socket.AF_INET6  # Change to 'AF_INET' to disable IPv6

logging.basicConfig(level=logging.INFO, stream=sys.stderr,
                    format='%(asctime)-15s %(message)s')


class ForwarderBot(ircbot.SingleServerIRCBot):
    """Minimal IRC bot; joins a channel."""

    def __init__(self, network, nickname, channel, **options):
        ircbot.SingleServerIRCBot.__init__(self, [network], nickname, nickname)
        self.channel = channel
        self.options = options
        for event in ['disconnect', 'join', 'part', 'welcome']:
            self.connection.add_global_handler(event, self.log_event)

    def connect(self, *args, **kwargs):
        """Intercepts call to ircbot.SingleServerIRCBot.connect to add support
        for ssl and ipv6 params."""
        kwargs.update(self.options)
        ircbot.SingleServerIRCBot.connect(self, *args, **kwargs)

    def on_privnotice(self, connection, event):
        logging.info('%s %s', event.source(), event.arguments())

    def log_event(self, connection, event):
        if connection.real_nickname in [event._source, event._target]:
            logging.info('%(_eventtype)s [%(_source)s -> %(_target)s]'
                    % vars(event))

    def on_welcome(self, connection, event):
        connection.join(self.channel)


if len(sys.argv) < 2 or sys.argv[1] in ('-h', '--help'):
    sys.exit(__doc__.lstrip())

with open(sys.argv[1]) as f:
    config = json.load(f)

# Create a TCP server socket
server = socket.socket(AF, socket.SOCK_STREAM)
server.setblocking(0)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

server.bind((config['tcp'].get('iface', ''), config['tcp']['port']))
server.listen(config['tcp']['max_clients'])

# Create a bot and connect to IRC
bot = ForwarderBot(**config['irc'])
bot._connect()

sockets = [server, bot.connection.socket]


def close_sockets():
    for sock in sockets:
        sock.close()
atexit.register(close_sockets)

while 1:
    readable, _, _ = select.select(sockets, [], [])
    for sock in readable:
        if sock is server:
            conn, addr = server.accept()
            conn.setblocking(0)
            logging.info('Connection from %s', addr)
            sockets.append(conn)
        elif sock is bot.connection.socket:
            bot.connection.process_data()
        else:
            data = sock.recv(BUFSIZE)
            data = codecs.decode(data, 'utf8', 'replace').strip()
            if data:
                logging.info('TCP %s: "%s"', sock.getpeername(), data)
                bot.connection.privmsg(bot.channel, data)
            else:
                sock.close()
                sockets.remove(sock)
