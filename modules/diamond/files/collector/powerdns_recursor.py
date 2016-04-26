# coding=utf-8

"""
Collects all metrics exported by the powerdns recursor using the
rec_control binary.

#### Dependencies

 * rec_control

"""

import diamond.collector
import subprocess
import os
from diamond.collector import str_to_bool


class PowerDNSRecursorCollector(diamond.collector.Collector):
    def get_default_config_help(self):
        config_help = super(PowerDNSRecursorCollector, self).get_default_config_help()
        config_help.update({
            'bin': 'The path to the rec_control binary',
            'use_sudo': 'Use sudo?',
            'sudo_cmd': 'Path to sudo',
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(PowerDNSRecursorCollector, self).get_default_config()
        config.update({
            'bin': '/usr/bin/rec_control',
            'path': 'powerdns_recursor',
            'use_sudo': False,
            'sudo_cmd': '/usr/bin/sudo',
        })
        return config

    def collect(self):
        if not os.access(self.config['bin'], os.X_OK):
            self.log.error("%s is not executable", self.config['bin'])
            return False

        command = [self.config['bin'], 'get-all']

        if str_to_bool(self.config['use_sudo']):
            command.insert(0, self.config['sudo_cmd'])

        data = subprocess.Popen(command,
                                stdout=subprocess.PIPE).communicate()[0]

        for metric in data.split('\n'):
            if not metric.strip():
                continue
            metric, value = metric.split('\t')
            try:
                value = float(value)
            except:
                pass
            self.publish(metric, value)
