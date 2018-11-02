# This is in anticipation of a better solution
# This is a logster parser(hack) where we look for
# instances of defined strings, count them, extract lines and log them elsewhere
import datetime
import optparse
import smtplib
import socket

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

        optparser = optparse.OptionParser()
        optparser.add_option('--savefile', '-s', dest='savefile', default=None,
                             help='logfile to output matches to')
        optparser.add_option('--alarmfile', '-a', dest='alarmfile', default=None,
                             help='file to read for alarms (one per line)')
        optparser.add_option('--name', '-n', dest='name', default='',
                             help='Job identifier')
        optparser.add_option('--email', '-e', dest='email', default='',
                             help='Job identifier')

        if option_string:
            options = option_string.split(' ')
        else:
            options = []
        opts, args = optparser.parse_args(args=options)

        self.name = opts.name
        self.email = opts.email

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

        with open(self.alarmfile) as al:
            raw_alarming = al.readlines()
            alarming = [x.lower().strip().strip('\n') for x in raw_alarming]

        self.alarms = alarming
        self.header = "{} Alarms({}): {}".format(datetime.datetime.now(),
                                                 self.alarmfile,
                                                 ', '.join(self.alarms))
        self.alarm_match = dict((k.lower(), []) for k in self.alarms)

        self.write(self.header)

    def write(self, line):

        if not self.savefile:
            return

        with open(self.savefile, 'a') as a:
            a.write(str(line) + '\n')

    def parse_line(self, line):
        '''This function should digest the contents of one line at a time, updating
        object's state variables. Takes a single argument, the line to be parsed.'''

        for alarm in self.alarms:
            if alarm.lower() in line.lower():
                self.alarm_match[alarm.lower()].append(line)
                self.line_count += 1

        for k, v in self.alarm_match.iteritems():
            for log_match in v:
                self.write("{}) {}".format(k, log_match))

    def notify(self, rate):

        body = ''
        body += self.header
        body += '\n\n'
        body += 'Overall match rate {}\n'.format(str(rate))
        body += 'Alarm matches:\n'
        for k, v in self.alarm_match.iteritems():
            if v:
                body += '{}: {}\n'.format(k, len(v))

        if self.savefile:
            body += '\nMatching lines extracted and stored in {}'.format(self.savefile)

        self.write('{} sending email for {} rate {}'.format(datetime.datetime.now(),
                                                            self.name,
                                                            rate))

        sendMail('LogsterAlarm',
                 [self.email],
                 'LogsterAlarm{} rate {}'.format(self.name, str(rate)),
                 body)

    def get_state(self, duration):

        self.duration = duration
        rate = float(self.line_count) / float(self.duration)

        if rate > 0 and self.email:
            self.notify(rate)

        return [
            MetricObject('{}.alarm_rate'.format(self.name),
                         (rate),
                         'lines per sec',
                         type='float',
                         slope='both'),
        ]
