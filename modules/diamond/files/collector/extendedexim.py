# coding=utf-8

"""
Exim collector. Collects queue properties and paniclog size.

Queue properties:
    - queue.oldest: age of oldest e-mail in queue (seconds)
    - queue.youngest: age of youngest e-mail in queue (seconds)
    - queue.size: total size of the queue (bytes)
    - queue.length: total number of e-mails in the queue
    - queue.num_frozen: number of frozen e-mails in the queue

Paniclog properties:
    - paniclog.length: number of lines in /var/log/exim4/paniclog

Queue length is retrieved from exim; the paniclog is read directly.
Both support the use of sudo, so diamond can run as unprivileged user.

#### History
Based on EximCollector bundled with Diamond (collectors/exim/exim.py)
Extended by Merlijn van Deen <valhallasw@arctus.nl>

#### Dependencies
 * /usr/sbin/exim

"""

import diamond.collector
import subprocess
import os
from datetime import timedelta
from collections import namedtuple
from diamond.collector import str_to_bool


class EximCollectorException(Exception):
    pass


EximQueueLine = namedtuple('EximQueueLine',
                           ['age', 'size', 'mail_id', 'frozen'])


class ExtendedEximCollector(diamond.collector.Collector):
    def get_default_config_help(self):
        config_help = super(EximCollector, self).get_default_config_help()
        config_help.update({
            'bin':         'The path to the exim binary',
            'use_sudo':    'Use sudo?',
            'sudo_cmd':    'Path to sudo',
            'sudo_user':   'User to sudo as',
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(EximCollector, self).get_default_config()
        config.update({
            'path':            'exim',
            'bin':              '/usr/sbin/exim',
            'use_sudo':         False,
            'sudo_cmd':         '/usr/bin/sudo',
            'sudo_user':        'root',
        })
        return config

    def _get_file(self, file):
        if not str_to_bool(self.config['use_sudo']):
            return open(file).read()
        else:
            command = [self.config['sudo_cmd'], "-u", self.config['sudo_user'],
                       "cat", file]
            try:
                return subprocess.check_output(
                    command,
                    stderr=subprocess.STDOUT
                )
            except subprocess.CalledProcessError as e:
                raise IOError(e)

    def _get_queue(self):
        if not os.access(self.config['bin'], os.X_OK):
            raise EximCollectorException('exim not found')

        command = [self.config['bin'], '-bpr']

        if str_to_bool(self.config['use_sudo']):
            command = [
                self.config['sudo_cmd'],
                '-u',
                self.config['sudo_user']
            ] + command
        print 'commando = ', command
        queue = subprocess.check_output(command)

        # remove empty lines
        queue = [l.strip() for l in queue.split("\n")]
        queue = [l for l in queue if l]

        # remove indented lines
        queue = [l for l in queue if l[0] != " "]

        return queue

    def _parse_age(self, age):
        postfix = age[-1]
        if postfix == "m":
            return timedelta(minutes=int(age[:-1]))
        elif postfix == "h":
            return timedelta(hours=int(age[:-1]))
        elif postfix == "d":
            return timedelta(days=int(age[:-1]))
        elif postfix == "w":
            return timedelta(weeks=int(age[:-1]))

    def _parse_size(self, size):
        postfix = size[-1]
        if postfix == "K":
            return float(size[:-1]) * 1024
        elif postfix == "M":
            return float(size[:-1]) * 1024
        else:
            return float(size)

    def _parse_line(self, line):
        parts = [x for x in line.split(" ") if x]
        age = self._parse_age(parts[0])
        size = self._parse_size(parts[1])
        mail_id = parts[2]
        frozen = "*** frozen ***" in line

        return EximQueueLine(age=age, size=size,
                             mail_id=mail_id, frozen=frozen)

    def collect_queue(self):
        try:
            queue = self._get_queue()
        except EximCollectorException:
            return

        parsed_queue = [self._parse_line(line) for line in queue]

        oldest = max(l.age for l in parsed_queue)
        youngest = min(l.age for l in parsed_queue)
        self.publish('queue.oldest', oldest.total_seconds())
        self.publish('queue.youngest', youngest.total_seconds())
        self.publish('queue.size', sum(l.size for l in parsed_queue))
        self.publish('queue.length', len(parsed_queue))
        self.publish('queue.num_frozen', sum(l.frozen for l in parsed_queue))

    def collect_paniclog(self):
        try:
            contents = self._get_file('/var/log/exim4/paniclog')
        except IOError:
            return

        num_lines = len(contents.split("\n"))
        self.publish('paniclog.length', num_lines)

    def collect(self):
        self.collect_queue()
        self.collect_paniclog()
