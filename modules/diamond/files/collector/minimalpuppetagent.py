# coding=utf-8

"""
Collect minimal stats from puppet agent's last_run_summary.yaml

Only reports:
    - Time since last run
    - Total time taken for last puppet run

Adapted from PuppetAgentCollector

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

    def _get_summary(self):
        process_path = ['/usr/bin/sudo', '-u', self.config['sudo_user'],
                        '/bin/cat', self.config['yaml_path']
                        ]
        proc = subprocess.Popen(process_path, stdout=subprocess.PIPE)
        out, _ = proc.communicate()

        summary = yaml.loads(out)

        return summary

    def collect(self):
        if yaml is None:
            self.log.error('Unable to import yaml')
            return

        summary = self._get_summary()

        # Only publish total executed time and 'time since last puppet run'
        total_time = summary['time']['total']
        time_since = int(time.time()) - int(summary['time']['last_run'])

        self.publish('total_time', total_time)
        self.publish('time_since_last_run', time_since)
