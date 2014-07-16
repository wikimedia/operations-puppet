# coding=utf-8

"""
Collect minimal stats from puppet agent's last_run_summary.yaml

Only reports:
    - Time since last run
    - Total time taken for last puppet run

Adapted from PuppetAgentCollector

Requires the ability to sudo as puppet to be able to collect.

#### Dependencies

 * yaml

"""

import time
import subprocess
try:
    import yaml
    yaml  # workaround for pyflakes issue #13
except ImportError:
    yaml = None

import diamond.collector


class MinimalPuppetAgentCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        config_help = super(MinimalPuppetAgentCollector,
                            self).get_default_config_help()
        config_help.update({
            'yaml_path': "Path to last_run_summary.yaml",
            'sudo_user': "The user to sudo as to read the file at yaml_path"
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(MinimalPuppetAgentCollector, self).get_default_config()
        config.update({
            'yaml_path': '/var/lib/puppet/state/last_run_summary.yaml',
            'sudo_user': 'puppet',
            'path':     'puppetagent',
            'method':   'Threaded',
        })
        return config

    def _check_sudo(self):
        """Check if diamond can sudo as puppet to read the summary file"""
        check_path = ['/usr/bin/sudo', '-l', '-u', self.config['sudo_user'],
                      '/bin/cat', self.config['yaml_path']
                      ]
        proc = subprocess.Popen(check_path, stdout=subprocess.PIPE)
        out, _ = proc.communicate()
        return out.strip() == '/bin/cat %s' % self.config['yaml_path']

    def _get_summary(self):

        process_path = ['/usr/bin/sudo', '-u', self.config['sudo_user'],
                        '/bin/cat', self.config['yaml_path']
                        ]
        proc = subprocess.Popen(process_path, stdout=subprocess.PIPE)
        out, _ = proc.communicate()

        summary = yaml.load(out)

        return summary

    def collect(self):
        if yaml is None:
            self.log.error('Unable to import yaml')
            return

        if not self._check_sudo():
            self.log.error("diamond can't sudo as puppet to read summary file")
            return
        summary = self._get_summary()

        # Only publish total executed time and 'time since last puppet run'
        total_time = summary['time']['total']
        time_since = int(time.time()) - int(summary['time']['last_run'])
        failed_events = summary['events']['failure']

        self.publish('total_time', total_time)
        self.publish('time_since_last_run', time_since)
        self.publish('failed_events', failed_events)
