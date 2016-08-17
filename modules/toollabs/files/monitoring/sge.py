# coding=utf-8

"""
SGE queue statistics

Example:

continuous.job_count 146
continuous.Rr 61

The list of queues and states are dynamic
"""

import diamond.collector
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

    def get_jobs(self, queue):
        """ retrieve all users job output for a queue
        :queue: str
        :returns: str
        :note: shell=true is to honor askerisk via subprocess
        """
        job_query = "/usr/bin/qstat -q %s -u '*'" % (queue,)
        return subprocess.check_output([job_query], shell=True)

    def get_queues(self):
        """ retrieve list of queues
        """
        queues = subprocess.check_output(['/usr/bin/qconf', '-sql'],
                                         env={"SGE_ROOT": '/data/project/.system/gridengine/'})
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

    def collect(self):
        for q in self.get_queues():
            jobs = self.get_jobs(q)
            job_count = len(jobs.splitlines()[1:])
            self.publish("%s.job_count" % (q,), job_count)

            states = self.job_state_stats(jobs.splitlines())
            for state, scount in states.iteritems():
                self.publish("%s.%s" % (q, state), scount)
