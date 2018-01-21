#!/usr/bin/python -u
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
#
# stdin -> IRC echo bot, with optional file input support.
#
# Written by Kate Turner <kate.turner@gmail.com>, source is in the public
# domain.
# Modified by Ryan Lane <rlane@wikimedia.org> for watching and taking input
# for files.  Changes are also public domain.
# Modified by Ryan Anderson <ryan@michonline.com> to handle disconnections more
# gracefully. Changes in the public domain.

import pyinotify
import threading
import random
import string
import re
import sys

import irc.client  # for exceptions.
from optparse import OptionParser
from irc.bot import SingleServerIRCBot


def beautify_message(m):
    '''Clean up formatting of alert messages.'''
    m = m.strip()                           # Strip trailing whitespace
    m = re.sub(r'(\w+): \1:\b', r'\1', m)   # Dedupe severity
    m = re.sub(r' {2,}', ' ', m)            # Collapse whitespace
    m = m.replace(': -', ':')               # Combine separators
    m = m.strip(':-')                       # Strip trailing separators
    return m


class EchoNotifier(threading.Thread):
    def __init__(self, notifier):
        threading.Thread.__init__(self)
        self.notifier = notifier
        self.daemon = True

    def run(self):
        self.notifier.loop()


class EchoReader():
    '''
    Essentially an initalization class
    '''

    def __init__(self, infile='', associatedchannel=''):
        self.infile = infile
        self.associatedchannel = associatedchannel
        self.uniques = {';': 'UNIQ_' + self.get_unique_string() + '_QINU',
                        ':': 'UNIQ_' + self.get_unique_string() + '_QINU',
                        ',': 'UNIQ_' + self.get_unique_string() + '_QINU'}

        if self.infile:
            print('Using infile')
            self.notifiers = []
            self.associations = {}
            self.files = {}
            infiles = self.escape(self.infile)
            for filechan in infiles.split(';'):
                temparr = filechan.split(':')
                filename = self.unescape(temparr[0])
                try:
                    print('Opening: ' + filename)
                    f = open(filename)
                    f.seek(0, 2)
                    self.files[filename] = f
                except IOError:
                    print('Failed to open file: ' + filename)
                    self.files[filename] = None
                    pass
                wm = pyinotify.WatchManager()
                mask = pyinotify.IN_MODIFY | pyinotify.IN_CREATE
                wm.watch_transient_file(filename, mask, EventHandler)
                notifier = EchoNotifier(pyinotify.Notifier(wm))
                self.notifiers.append(notifier)
                # Does this file have channel associations?
                if len(temparr) > 1:
                    chans = self.unescape(temparr[1])
                    self.associations[filename] = chans
            for notifier in self.notifiers:
                print('Starting notifier loop')
                notifier.start()
        else:
            while True:
                try:
                    s = raw_input()
                    # this throws an exception if not connected.
                    s = beautify_message(s)
                    self.bot.connection.privmsg(self.chans, s.replace('\n', ''))
                except EOFError:
                    # Once the input is finished, the bot should exit
                    break
                except Exception:
                    pass

    def get_unique_string(self):
        unique = ''
        for i in range(15):
            unique = unique + random.choice(string.letters)
        return unique

    def escape(self, string):
        escaped_string = re.sub('\\\;', self.uniques[';'], string)
        escaped_string = re.sub('\\\:', self.uniques[':'], escaped_string)
        escaped_string = re.sub('\\\,', self.uniques[','], escaped_string)
        return escaped_string

    def unescape(self, string):
        unescaped_string = re.sub(self.uniques[';'], ';', string)
        unescaped_string = re.sub(self.uniques[':'], ':', unescaped_string)
        unescaped_string = re.sub(self.uniques[','], ',', unescaped_string)
        return unescaped_string

    def readfile(self, filename):
        if self.files[filename]:
            return self.files[filename].read()
        else:
            return

    def getchannels(self, filename):
        if filename in self.associations:
            return self.associations[filename]
        else:
            return bot.chans


class EchoBot(SingleServerIRCBot):
    def __init__(self, chans, nickname, server, ssl):
        print('Connecting to IRC server %s...' % server)

        if ssl:
          port = 6697
        else:
          port = 6667

        SingleServerIRCBot.__init__(self, [(server, port)], nickname, 'IRC echo bot')
        self.chans = chans
        self.use_ssl = ssl

    def connect(self, *args, **kwargs):
        if self.use_ssl:
            import ssl
            ssl_factory = irc.connection.Factory(wrapper=ssl.wrap_socket)
            self.connection.connect(*args, connect_factory=ssl_factory, **kwargs)
        else:
            self.connection.connect(*args, **kwargs)

    def on_nicknameinuse(self, c, e):
        c.nick(c.get_nickname() + '_')

    def on_welcome(self, c, e):
        print('Connected')
        for chan in [self.chans]:
            c.join(chan)


class EventHandler(pyinotify.ProcessEvent):
    def process_IN_MODIFY(self, event):
        s = reader.readfile(event.pathname)
        s = beautify_message(s)
        if s:
            chans = reader.getchannels(event.pathname)
            try:
                s = s.replace('\n', '')
                # python irc library enforces a 512 maximum byte limit per
                # message per RFC 2812. While this is overly strict, let's try
                # to conform. Split the message into multiple messages.
                # Unfortunately the library enforces this limit at the protocol
                # level meaning we have to account for the entire IRC command,
                # the format of which is:
                #     :source PRIVMSG <target> :Message
                # which is not easy to calculate as the channel is of variable
                # size. Using #wikimedia-operations means this is 40 bytes, so
                # set a 450 max message size and hope is enough.
                # We anyway catch and silently drop the message later on if that
                # turns out to not be true
                outputs = [s[0+i:450+i] for i in range(0, len(s), 450)]
                for out in outputs:
                    bot.connection.privmsg(chans, out)
            except (irc.client.ServerNotConnectedError, irc.client.MessageTooLong) as e:
                print('Error writing: %s'
                      'Dropping this message: "%s"') % (e, s)

    def process_IN_CREATE(self, event):
        try:
            print('Reopening file: ' + event.pathname)
            reader.files[event.pathname] = open(event.pathname)
        except IOError:
            print('Failed to reopen file: ' + event.pathname)
            pass


parser = OptionParser(conflict_handler='resolve')
parser.set_usage('ircecho [--infile=<filename>] <channel> <nickname> <server> <ssl>')
parser.add_option('--infile', dest='infile',
                  help='Read input from the specific file instead of from stdin')
(options, args) = parser.parse_args()
chans = args[0]
nickname = args[1]
server = args[2]
ssl = args[3]
global bot
bot = EchoBot(chans, nickname, server, ssl)
global reader
reader = EchoReader(options.infile)
try:
    bot.start()
except Exception:
    sys.exit(1)
