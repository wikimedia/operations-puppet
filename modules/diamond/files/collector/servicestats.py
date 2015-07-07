"""
Collect basic system-level statistics for a given upstart or systemd service.

#### Dependencies

  * psutil
  * configparser
  * python >= 2.7

#### Metrics

For each configured service the following metrics will be exported
(all prefixed with <diamond_path>). The numbers are gathered by asking
systemd/upstart for the main service process PID and aggregate values from
child processes too.

  * <service_name>.cpu_percent    # total % CPU used
  * <service_name>.memory_percent # total % memory used
  * <service_name>.create_time    # UNIX timestamp of service startup
  * <service_name>.num_threads    # total threads
  * <service_name>.system_time    # total seconds spent in kernel
  * <service_name>.user_time      # total seconds spent in user space

"""

import os

import configparser

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
        try:
            with open(filename, 'r') as f:
                p.readfp(f)
            return p
        except configparser.Error, e:
            self.log.error('error parsing %r: %r', filename, e)
            return None
        except OSError, e:
            self.log.error('error reading %r: %r', filename, e)
            return None

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

        config_files = []
        try:
            for filename in os.listdir(config_dir):
                if not filename.endswith('.conf'):
                    self.log.warn('skipping %r', filename)
                    continue
                config_files.append(filename)
        except OSError, e:
            self.log.error('error while listing %r: %r', config_dir, e)
            return None

        if not config_files:
            self.log.warn('no config files found in %r', config_dir)
            return None

        for filename in config_files:
            conf = self._load_conf(os.path.join(config_dir, filename))
            if not conf:
                continue

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
