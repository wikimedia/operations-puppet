import diamond.collector
import socket
import sys
import re


class IRCDStatsCollector(diamond.collector.Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(IRCDStatsCollector, self).get_default_config()
        config.update({
            'path':     'ircd',
            'server':   'localhost',
            'user':     'ircd_stats_bot',
            'port':     6667,
        })
        return config

    def recv_until(self, the_socket, end):
        total_data = ''
        while True:
            data = the_socket.recv(8192)
            total_data += (data)
            if end in total_data:
                break
        return total_data.rstrip('\0').strip()

    def collect(self):
        irc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            irc.connect((self.config['server'], int(self.config['port'])))
            # making ircd happy with # of args
            irc.send("USER %s %s %s :%s\n" % (self.config['user'],
                                              self.config['user'],
                                              self.config['user'],
                                              self.config['user']))

            irc.send("NICK %s\n" % (self.config['user'],))
            termout = self.recv_until(irc, 'End of /MOTD command')
            users = re.search("There\sare\s(\d+)\susers", termout)
            chans = re.search("(\d+)\s:channels\sformed", termout)
            if users and chans:
                self.publish('users', users.groups()[0].strip())
                self.publish('channels', chans.groups()[0].strip())
        finally:
            try:
                irc.send("QUIT \n")
                irc.close()
            except:
                pass
