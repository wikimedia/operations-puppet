# coding=utf-8

"""
collect nscd statistics (name service caching daemon)

no native structured access

#### Dependencies

  * nscd (Debian GLIBC 2.19-18+deb8u1) 2.19
  * sudo for nscd -g

"""

import syslog
import subprocess
import diamond.collector


def runBash(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out = p.stdout.read().strip()
    return out


class NscdCollector(diamond.collector.Collector):

    nscd = ['current number of threads',
            'maximum number of threads',
            'number of times clients had to wait']

    caches = ['cache hits on positive entries',
              'cache hits on negative entries',
              'cache misses on positive entries',
              'cache misses on negative entries',
              'cache hit rate',
              'current number of cached values',
              'maximum number of cached values']

    def get_default_config_help(self):
        config_help = super(NscdCollector, self).get_default_config_help()
        config_help.update({
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(NscdCollector, self).get_default_config()
        config.update({
            'enabled':  False,
            'path':     'nscd',
            'command':  'sudo /usr/sbin/nscd -g',
        })
        return config

    def format_metric(self, value):
        # Example value:
        # 0  maximum number of cached values
        value = value.strip().split(' ', 2)
        integer = value[0].strip('%')
        name = value[2].replace(' ', '_').strip()
        return name, integer

    def collect(self):

        try:
            stats = runBash(self.config['command'])
        except:
            self.log.error("nscd stats collection failed")
            return

        # break on the one unique char per section
        sep_stats = stats.split(':')

        # name, index, value array
        sections = [('nscd', 1, self.nscd),
                    ('passwd', 2, self.caches),
                    ('group', 3, self.caches),
                    ('hosts', 4, self.caches)]

        results = {}
        for section in sections:
            results[section[0]] = {}
            # Get the values for the relevant section
            values = sep_stats[section[1]].splitlines()

            # match up real lines and intended metrics
            for value in values:
                for metric in section[2]:
                    if metric in value:
                        name, integer = self.format_metric(value)
                        results[section[0]][name] = integer

        for section, kv in results.iteritems():
            for k, v in kv.iteritems():
                self.publish("%s.%s" % (section, k),  v)
