# coding=utf-8

"""
LocalCrontabCollector. Collects the number of local user cron tabs.

Main use is Toolforge, where there should be no cron tabs on any
host other than tools-submit.
"""

import subprocess
import diamond.collector
from diamond.collector import str_to_bool


class LocalCrontabCollector(diamond.collector.Collector):
    def get_default_config_help(self):
        config_help = super(LocalCrontabCollector, self).get_default_config_help()  # noqa
        config_help.update({
            'administrative':  'List of user names to report'
                               'as administrative crontabs',
            'use_sudo':    'Use sudo?',
            'sudo_cmd':    'Path to sudo',
            'sudo_user':   'User to sudo as',
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(LocalCrontabCollector, self).get_default_config()
        config.update({
            'path':             'localcrontab',
            'administrative':   ['root', 'puppet', 'prometheus'],
            'use_sudo':         False,
            'sudo_cmd':         '/usr/bin/sudo',
            'sudo_user':        'root',
        })
        return config

    def collect(self):
        command = ['/bin/ls', '/var/spool/cron/crontabs/']

        if str_to_bool(self.config['use_sudo']):
            command = [
                self.config['sudo_cmd'],
                '-u',
                self.config['sudo_user']
            ] + command

        self.log.debug('Running %s' % (' '.join(command)))
        crontabs = subprocess.check_output(command).split("\n")
        crontabs = [c.strip() for c in crontabs]
        crontabs = [c for c in crontabs if c]

        total_crontabs = len(crontabs)
        admin_crontabs = len([c for c in crontabs
                              if c in self.config['administrative']])
        other_crontabs = total_crontabs - admin_crontabs

        self.publish('total', total_crontabs)
        self.publish('administrative', admin_crontabs)
        self.publish('other', other_crontabs)
