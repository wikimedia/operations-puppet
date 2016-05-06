#! /usr/bin/env python
try:
    from irc.bot import SingleServerIRCBot
except ImportError:
    from ircbot import SingleServerIRCBot
import argparse
import json
import threading
import socket
import sys
reload(sys)
sys.setdefaultencoding('utf8')

argparser = argparse.ArgumentParser()
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/udpmxircecho-config.json',
    type=argparse.FileType('r')
)
args = argparser.parse_args()
config_data = json.load(args.config_file)


class EchoReader(threading.Thread):
    def __init__(self, bot):
        threading.Thread.__init__(self)
        self.bot = bot

    def run(self):
        udpsock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udpsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        try:
            udpsock.bind(('', config_data['udp_port']))
        except socket.error, msg:
            sys.stderr.write("[ERROR] %s\n" % msg[1])
            sys.exit(2)

        while True:
            try:
                s = udpsock.recv(65535)
                sp = s.split("\t")
                if len(sp) == 2:
                    channel = sp[0]
                    text = sp[1].lstrip().replace('\r', '').replace('\n', '')

                    if channel not in self.bot.chans:
                        self.bot.chans.append(channel)
                        self.bot.connection.join(channel)
                    # this throws an exception if not connected.
                    self.bot.connection.privmsg(channel, text)
            except EOFError:
                # Once the input is finished, the bot should exit
                sys.exit()
            except Exception as e:
                print e


class EchoBot(SingleServerIRCBot):
    def __init__(self):
        port = config_data['irc_port']
        nickname = config_data['irc_nickname']
        server = config_data['irc_server']
        print "connecting to %s as %s on port %s" % (server, nickname, port)
        server_list = [(server, port)]
        realname = config_data['irc_realname']
        SingleServerIRCBot.__init__(self, server_list, nickname, realname)
        self.chans = []

    def on_nicknameinuse(self, c, e):
        print '%s nickname in use!' % (c.get_nickname(),)
        c.nick(c.get_nickname() + "_")

    def on_welcome(self, c, e):
        print "got welcome"
        c.oper("rc", config_data['irc_oper_pass'])

        for chan in self.chans:
            c.join(chan)


def main():
    bot = EchoBot()
    sthr = EchoReader(bot)
    sthr.start()
    bot.start()
main()
