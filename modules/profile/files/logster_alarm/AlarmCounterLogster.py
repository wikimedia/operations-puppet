# This is in anticipation of a better solution
# This is a logster parser(hack) where we look for
# instances of defined strings, count them, extract lines and log them elsewhere

# Warning: re.search only matches first entry
#
# Example YAML config:
#
# regex:
#  csp_warn:
#    pattern: '\sCSP\sreport:\s<(.+?)>\sblocked\sfrom\sbeing\sloaded\son\s<(https://.+?)>(.+?)'
#    fields:
#      uri:
#        position: 1
#        keys:
#          - baduri
#          - worseuri
#      project:
#        position: 2
#        keys:
#          - badproject
#          - worseproject
#      ipaddress:
#        position: 3
#        iprange: True
#        keys:
#          - 192.168.0.0/16
#          - 172.16.0.0/12


import datetime
import ipaddress
import optparse
import smtplib
import re
import socket
import yaml

from ipaddress import ip_address as IP
from ipaddress import ip_network as IPNet
from logster.logster_helper import MetricObject, LogsterParser


def sendMail(sender, receivers, subject, body):
    """ Send a simple email
    :param sender: string
    :param receivers: list of strings
    :param subject: string
    :param body: string
    """
    sender_full = "{}@{}".format(sender, socket.getfqdn())

    message = """\
From: %s
To: %s
Subject: %s

%s
""" % (sender_full,
        ", ".join(receivers),
        subject,
        body)

    server = smtplib.SMTP('localhost')
    server.sendmail(sender_full, receivers, message)
    server.quit()


class AlarmCounterLogster(LogsterParser):

    def __init__(self, option_string=None):

        self.line_count = 0
        self.alarm_count = 0

        optparser = optparse.OptionParser()
        optparser.add_option('--savefile', '-s', dest='savefile', default=None,
                             help='logfile to output matches to')
        optparser.add_option('--alarmfile', '-a', dest='alarmfile', default=None,
                             help='file to read for alarms (one per line)')
        optparser.add_option('--name', '-n', dest='name', default='',
                             help='Human readable name for job')
        optparser.add_option('--email', '-e', dest='email', default='',
                             help='Comma separated list of emails')
        optparser.add_option('--alarmthreshold', '-t', type='int', dest='alarmthreshold',
                             default=0,
                             help='Alarm count to alert at')

        if option_string:
            options = option_string.split(' ')
        else:
            options = []
        opts, args = optparser.parse_args(args=options)

        self.name = opts.name
        self.alarmthreshold = opts.alarmthreshold
        self.emails = opts.email.split(',')

        if opts.savefile:
            self.savefile = opts.savefile
        else:
            self.savefile = None

        self.alarmfile = opts.alarmfile

        try:
            with open('myfile', 'r') as f:
                f.close()
        except IOError:
            with open('myfile', 'w') as f:
                f.close()

        with open(self.alarmfile) as f:
            settings = yaml.safe_load(f)

        header = '{} Alarms[{}]'.format(datetime.datetime.now(),
                                        self.alarmfile)

        # create header for runs that persists to emails and log file
        for re_name, re_meta in settings['regex'].iteritems():
            ren_name = ' - {}'.format(re_name)
            for field, attr in re_meta['fields'].iteritems():
                if attr['keys']:
                    ren_name += '({}: {})'.format(field, ','.join(attr['keys']))
            header += ren_name

        self.re_matches = {}
        self.settings = settings
        self.header = header

    def write(self, line):

        if not self.savefile:
            return

        with open(self.savefile, 'a') as a:
            a.write(str(line) + '\n')

    def parse_line(self, line):

        self.line_count += 1

        # Find regex matches and build a dict of tuples
        # for confirmed matches and later processing
        for re_name, re_meta in self.settings['regex'].iteritems():
            if re_name not in self.re_matches:
                self.re_matches[re_name] = []
            match = re.search(re_meta['pattern'], line)
            if match:
                self.re_matches[re_name].append((match,
                                                 re_meta,
                                                 line))

    def ip_in_net(self, ip, net):
        """:param ip: string ('10.0.0.1')
           :param net: string ('10.0.0.0/8')
        """
        try:
            return IP(unicode(ip)) in IPNet(unicode(net))
        except ipaddress.AddressValueError:
            self.write('WARN {} {} failed evaluation'.format(ip, net))
            return None

    def keyword_match(self):
        keyword_hits = []
        for re_name, re_match in self.re_matches.iteritems():
            for item in re_match:
                result = item[0]
                config = item[1]
                for field, fkey in config['fields'].iteritems():
                    extracted = result.group(fkey['position'])

                    for key in fkey['keys']:
                        if 'iprange' in fkey and fkey['iprange']:
                            found = self.ip_in_net(extracted, key)
                        elif key in extracted:
                            found = True
                        else:
                            found = False

                        if found:
                            content = (re_name,
                                       field,
                                       key,
                                       extracted,
                                       result.group())
                            self.alarm_count += 1
                            keyword_hits.append(content)

        return keyword_hits

    def notify(self, rate, keyword_matches):

        body = ''
        body += self.header
        body += '\n\n'
        body += 'Logging rate is {}\n'.format(str(rate))
        body += 'Alarm match count is {}\n'.format(self.alarm_count)
        body += 'Alerting match count threshold is {}\n\n'.format(self.alarmthreshold)

        for hit in keyword_matches:
            hit_msg = "({}) {} found in {} {}".format(hit[0], hit[2], hit[1], hit[3])
            hit_msg += " with extract {}".format(hit[4])
            self.write(hit_msg)
            body += hit_msg
            body += "\n\n"

        if self.savefile:
            body += '\nExtracted content is stored in {}'.format(self.savefile)

        self.write('{} sending email for {} rate {}'.format(datetime.datetime.now(),
                                                            self.name,
                                                            rate))

        sendMail('LogsterAlarm',
                 self.emails,
                 'LogsterAlarm{} match count is {}\n'.format(self.name, self.alarm_count),
                 body)

    def get_state(self, duration):
        self.write(self.header)

        kmatches = self.keyword_match()
        self.duration = duration
        line_rate = float(self.line_count) / float(self.duration)
        alarm_rate = float(self.alarm_count) / float(self.duration)

        if self.alarm_count > self.alarmthreshold and self.emails:
            self.write("Alarm count is {}".format(self.alarm_count))
            self.notify(line_rate, kmatches)

        return [
            MetricObject('{}.alarm_rate'.format(self.name),
                         (alarm_rate),
                         'lines per sec',
                         type='float',
                         slope='both'),
        ]
