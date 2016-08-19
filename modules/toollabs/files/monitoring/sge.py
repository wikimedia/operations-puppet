# coding=utf-8

"""
SGE queue statistics

Example:

jobseqnum 9967586

continuous.job_count 146
continuous.Rr 61

foo.eqiad.wmflabs.job_count 22

The list of queues and states are dynamic
"""

import diamond.collector
import re
import subprocess


class SGECollector(diamond.collector.Collector):

    def __init__(self, *args, **kwargs):
        super(SGECollector, self).__init__(*args, **kwargs)

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(SGECollector, self).get_default_config()
        config.update({
            'path':           'sge',
            'exclude':        ['test'],
        })
        return config

    def get_job_count(self):
        """ this is a sequential all time job count"""
        with open('/data/project/.system/gridengine/spool/qmaster/jobseqnum', 'r') as f:
            return f.read()

    def grid_cmd(self, cmd, shell=False):
        return subprocess.check_output([cmd],
                                       env={"SGE_ROOT": '/data/project/.system/gridengine/'},
                                       shell=shell)

    def get_all_exec_hosts(self):
        return self.grid_cmd('/usr/bin/qconf -sel')

    def get_jobs(self, queue):
        """ retrieve all users job output for a queue
        :queue: str
        :returns: str
        :note: shell=true is to honor askerisk via subprocess
        """
        return self.grid_cmd("/usr/bin/qstat -q %s -u '*'" % (queue,), shell=True)

    def get_queues(self):
        """ retrieve list of queues
        """
        queues = self.grid_cmd('/usr/bin/qconf -sql', shell=True)
        return [q for q in queues.splitlines() if q not in self.config['exclude']]

    def job_state_stats(self, jobs):
        """ count jobs per state
        :jobs: list
        :returns: dict
        """
        states = []
        # remove title bar
        for j in jobs[1:]:
            if len(j.split()) >= 4:
                states.append(j.split()[4])
        unique_states = list(set(states))

        stats = {}
        for s in unique_states:
            stats[s] = states.count(s)
        return stats

    def get_exec_hosts(self):
        """find all hosts that can execute jobs"""
        return self.grid_cmd('/usr/bin/qconf -sel', shell=True).splitlines()

    def get_jobs_by_host(self, host):
        """for a given exec host get jobs
        :param host: fqdn str
        :returns: array
        """
        output = self.grid_cmd('/usr/bin/qhost -j -h %s' % (host,), shell=True)
        jobs = []
        # job line example:
        #   3771218 0.57889 run tools.foo r 1/1/2016 21:18:39 task MASTER
        for line in output.splitlines():
            if re.match('\s+\d', line):
                jobs.append(line)
        return jobs

    def collect(self):

        # This rolls over at 10million
        self.publish('jobseqnum', self.get_job_count().strip())

        # total concurrent jobs and broken down by state
        for q in self.get_queues():
            jobs = self.get_jobs(q)
            job_count = len(jobs.splitlines()[1:])
            self.publish("%s.job_count" % (q,), job_count)

            states = self.job_state_stats(jobs.splitlines())
            for state, scount in states.iteritems():
                self.publish("%s.%s" % (q, state), scount)

        # job counts by exec node
        execs = self.get_exec_hosts()
        for host in execs:
            jcount = len(self.get_jobs_by_host(host.strip()))
            santitary_host = host.split('.')[0]
            self.publish('hosts.%s.job_count' % (santitary_host,), jcount)
