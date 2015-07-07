"""
Collect essential system-level statistics for a given upstart/systemd service.

#### Dependencies

 * psutil
 * configparser
 * subprocess
"""

import configparser
import os

from diamond.collector import Collector

from servicestats_lib import UpstartService, SystemdService


class ServiceStatsCollector(Collector):
    """
    Gather statistics for services found in config_dir.

    Each configuration file must end in .conf and parsable by python's
    configparser module, each file must contain a section for the
    init system in use with a 'name' entry describing the service name.
    e.g. /etc/diamond/servicestats.d/ssh.conf would contain

      [systemd]
      name=ssh

    """
    INITSYSTEMS = {
        'systemd': SystemdService,
        'upstart': UpstartService,
    }

    def _load_conf(self, filename):
        p = configparser.SafeConfigParser()
        with open(filename, 'r') as f:
            p.readfp(f)
        return p

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(ServiceStatsCollector, self).get_default_config()
        config.update({
            'path': 'services',
            'initsystem': 'systemd',
            'config_dir':  '/etc/diamond/servicestats.d',
        })
        return config

    def collect(self):
        initsystem = self.config['initsystem']
        config_dir = self.config['config_dir']
        if initsystem not in self.INITSYSTEMS:
            self.log.error('invalid init system in config: %r',
                           initsystem)

        if not os.access(config_dir, os.R_OK):
            self.log.error('unable to access %s', config_dir)
            return None

        for filename in os.listdir(config_dir):
            if not filename.endswith('.conf'):
                self.log.warn('skipping %r', filename)
                continue

            conf = self._load_conf(os.path.join(config_dir, filename))
            if not conf.has_option(initsystem, 'name'):
                self.log.error('config option "name" for %s not found in %s',
                               initsystem, filename)
                continue
            name = conf.get(initsystem, 'name')
            service = self.INITSYSTEMS.get(initsystem)()
            stats = service.stats(name)

            if stats is None:
                self.log.error('unable to collect metrics for %s', name)
                return None

            for key, value in service.stats(name).iteritems():
                metric_name = '.'.join([name, key])
                self.publish_gauge(metric_name, value)
