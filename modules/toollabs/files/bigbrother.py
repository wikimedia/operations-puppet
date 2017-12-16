#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright © 2016 Wikimedia Foundation and contributors.
# Copyright © 2014 Marc-André Pelletier <mpelletier@wikimedia.org>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

from __future__ import print_function

from email.mime.text import MIMEText
import argparse
import datetime
import logging
import os
import pwd
import random
import re
import smtplib
import subprocess
import time
import traceback
import xml.etree.ElementTree as ET


logger = logging.getLogger(__name__)


class BigBrother(object):
    """Monitor OGE job queues and start missing jobs."""
    def __init__(self, scoreboard, dry_run=False):
        self.watchdb = {}
        self.scoreboard = scoreboard
        self.dry_run = dry_run

    def log_event(self, tool, etype, msg):
        if tool not in self.watchdb:
            return

        event = '%s %s: %s' % (
            datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
            etype,
            msg)

        if self.dry_run:
            logger.info('tool=%s %s', tool, event)
            return

        with open(self.watchdb[tool]['logfile'], 'a') as log:
            print(event, file=log)

        email = MIMEText(event)
        email['Subject'] = '[bigbrother] %s: %s' % (etype, msg)
        email['To'] = '%s maintainers <%s>' % (tool, tool)
        email['From'] = 'Bigbrother <%s>' % tool
        mta = smtplib.SMTP('localhost')
        mta.sendmail(tool, [tool], email.as_string())
        mta.quit()

    def read_config(self, tool):
        now = time.time()
        if tool not in self.watchdb:
            pwnam = pwd.getpwnam(tool)
            if pwnam.pw_name != tool:
                # Paranoia!
                return
            if not os.path.isdir(pwnam.pw_dir):
                # Tool's homedir not found
                return
            self.watchdb[tool] = {
                'rcfile': '%s/.bigbrotherrc' % pwnam.pw_dir,
                'logfile': '%s/bigbrother.log' % pwnam.pw_dir,
                'mtime': 0,
                'refresh': now,
            }

        if now < self.watchdb[tool]['refresh']:
            return

        # Schedule for a refresh sometime in the next 60 minutes
        self.watchdb[tool]['refresh'] = now + random.randint(0, 60)

        rcfile = self.watchdb[tool]['rcfile']
        try:
            sb = os.stat(rcfile)
        except OSError:
            # File doesn't exist
            # T94500: clear any jobs that we were tracking
            self.watchdb[tool]['jobs'] = {}
            return
        if sb.st_mtime <= self.watchdb[tool]['mtime']:
            # File hasn't changed since the last time we read it
            return
        self.watchdb[tool]['mtime'] = sb.st_mtime

        with open(rcfile, 'r') as fh:
            jobs = {}
            for i, line in enumerate(fh):
                if re.match(r'^\s*(#.*)?$', line):
                    # Ignore empty lines and comments
                    continue
                if line.startswith('webservice'):
                    # Ignore webservice lines, they are taken care of by
                    # service manifests
                    continue

                m = re.match(r'^jstart\s+-N\s+(\S+)\s+(.*)$', line)
                if m:
                    job_name = m.group(1)
                    cmd = "/usr/bin/jstart -N '%s' %s" % (job_name, m.group(2))
                else:
                    # FIXME: throttle email sends! This will spam the heck out
                    # of anyone who has bad commands in their .bigbrotherrc
                    self.log_event(
                        tool, 'error',
                        '%s:%d: command not supported' % (rcfile, i + 1))
                    continue
                if job_name in jobs:
                    self.log_event(
                        tool, 'warn',
                        '%s:%d: duplicate job name "%s" ignored' % (
                            rcfile, i + 1, job_name))
                    continue

                jobs[job_name] = {
                    'cmd': cmd,
                    'jname': job_name,
                }

        if 'jobs' in self.watchdb[tool]:
            # Do a complicated dance to preserve any state data for job names
            # that existed before this run.

            # First, clear the 'cmd' member of every old job definition
            for jn in self.watchdb[tool]['jobs']:
                self.watchdb[tool]['jobs'][jn]['cmd'] = None

            for jn in jobs:
                # Update/insert the new jobs into the stored data
                if jn in self.watchdb[tool]['jobs']:
                    job = self.watchdb[tool]['jobs'][jn]
                    job['cmd'] = jobs[jn]['cmd']
                else:
                    self.watchdb[tool]['jobs'][jn] = jobs[jn]

            # Finally, delete any jobs that still have an empty 'cmd' member
            for jn in self.watchdb[tool]['jobs']:
                if self.watchdb[tool]['jobs'][jn]['cmd'] is None:
                    del self.watchdb[tool]['jobs'][jn]
        else:
            self.watchdb[tool]['jobs'] = jobs

    def start_job(self, tool, job):
        now = time.time()
        if 'restarts' not in job:
            job['restarts'] = []

        # Forget about restarts that were more than 24 hours ago
        job['restarts'] = [s for s in job['restarts'] if s < (now - 60*60*24)]

        if len(job['restarts']) > 10:
            self.log_event(
                tool, 'warn',
                "Too many attempts to restart job '%s'; throttling" % job['name'])
            job['state'] = 'THROTTLED'
            job['since'] = now
            # Don't try to restart this job again until 24 hours after the
            # first restart that we remember
            job['timeout'] = job['restarts'][0] + 60*60*24
            return

        job['restarts'].append(now)
        # Give the new job 90-120 seconds to start before trying again
        job['state'] = 'STARTING'
        job['timeout'] = now + 90 + random.randint(0, 30)
        job['since'] = now
        self.log_event(tool, 'info', "Restarting job '%s'" % job['jname'])

        if not self.dry_run:
            with open(self.watchdb[tool]['logfile'], 'a') as log:
                subprocess.call(
                    [
                        '/usr/bin/sudo',
                        '--login',
                        '--user', tool,
                        '--',
                        job['cmd']
                    ],
                    stdout=log, stderr=log)

    def update_db(self):
        """Update our internal database state"""
        for tool in self.watchdb:
            if 'jobs' not in self.watchdb[tool]:
                continue
            for jname in self.watchdb[tool]['jobs']:
                job = self.watchdb[tool]['jobs'][jname]
                if 'timeout' in job:
                    # Waiting on a restart or throttled,
                    # leave the current state alone
                    continue
                # Mark as dead pending verification of state from qstat
                job['state'] = 'DEAD'

        # Update the known state of all jobs from qstat data
        xml = ET.fromstring(subprocess.check_output(
            ['/usr/bin/qstat', '-u', '*', '-xml']))
        for j in xml.iter('job_list'):
            tool = j.find('JB_owner').text
            try:
                self.read_config(tool)
            except IOError:
                logger.exception('Failed to read config for %s', tool)
                continue

            if tool not in self.watchdb or 'jobs' not in self.watchdb[tool]:
                # Not watching any jobs for this tool
                continue

            jname = j.find('JB_name').text
            if jname not in self.watchdb[tool]['jobs']:
                # Not watching this job for this tool
                continue

            # Update the watched job's state
            job = self.watchdb[tool]['jobs'][jname]
            job['jname'] = jname
            job['state'] = j.find('state').text

            since_xml = j.find('JAT_start_time')
            if since_xml is None:
                since_xml = j.find('JB_submission_time')
            job['since'] = datetime.datetime.strptime(
                since_xml.text, '%Y-%m-%dT%H:%M:%S')

            if 'timeout' in job:
                del job['timeout']

    def check_watches(self):
        tmp_name = '%s.%d' % (self.scoreboard, os.getpid())
        with open(tmp_name, 'w') as sb:
            print(datetime.datetime.utcnow(), file=sb)
            for tool in self.watchdb:
                try:
                    if 'jobs' not in self.watchdb[tool]:
                        print('%s:-:-:-:-' % tool, file=sb)
                        continue
                    for job in self.watchdb[tool]['jobs'].values():
                        if 'state' not in job:
                            print('%s:%s:-:-:-' % (tool, job['jname']), file=sb)
                            continue
                        if job['state'] == 'DEAD':
                            self.start_job(tool, job)
                        elif job['state'] in ['STARTING', 'THROTTLED']:
                            if time.time() >= job.get('timeout', 0):
                                self.log_event(
                                    tool, 'warn',
                                    "job '%s' failed to start" % job['jname'])
                                self.start_job(tool, job)
                        print(
                            '%s:%s:%s:%s:%s' % (
                                tool,
                                job['jname'],
                                job.get('state', 'UNKNOWN'),
                                job.get('since', 0),
                                job.get('timeout', 0)
                            ),
                            file=sb)
                except:
                    logger.exception('Exception during restart of tool %s',
                                     tool)
                    traceback.print_exc()
                    print('--------------')
                    traceback.print_stack()

        os.rename(tmp_name, self.scoreboard)

    def run(self):
        while True:
            self.update_db()
            self.check_watches()
            time.sleep(10)


if __name__ == '__main__':
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)-8s - %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%S')
    parser = argparse.ArgumentParser(
        description='Monitor OGE job queues and start missing jobs.')
    parser.add_argument(
        '--dry-run', action='store_true', dest='dry_run',
        help='Do not send emails or run jobs')
    parser.add_argument(
        '--scoreboard', metavar='FILE',
        default='/data/project/.system/bigbrother.scoreboard',
        help='System state file')
    args = parser.parse_args()
    bb = BigBrother(scoreboard=args.scoreboard, dry_run=args.dry_run)
    bb.run()
