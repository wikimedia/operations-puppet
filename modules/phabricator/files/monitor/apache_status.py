# coding=utf-8
import diamond.collector
import re
import urllib2

"""

2015 Chase Pettet

Requires: http://httpd.apache.org/docs/2.4/mod/mod_status.html

$server.apache.Uptime:54227|g
$server.apache.IdleWorkers:40|g
$server.apache.Total_Accesses:929239|g
$server.apache.BytesPerReq:2910|g
$server.apache.CPULoad:7|g
$server.apache.BytesPerSec:49865|g
$server.apache.ReqPerSec:17|g
$server.apache.Total_kBytes:2.64064e+06|g
$server.apache.BusyWorkers:10|g
"""

class ApacheStatusSimple(diamond.collector.Collector):

    def __init__(self, *args, **kwargs):
        super(ApacheStatusSimple, self).__init__(*args, **kwargs)

        self.stats = [
            'Total\sAccesses',
            'Total\skBytes',
            'CPULoad',
            'Uptime',
            'ReqPerSec',
            'BytesPerSec',
            'BytesPerReq',
            'BusyWorkers',
            'IdleWorkers',
        ]

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(ApacheStatusSimple, self).get_default_config()
        config.update({
            'path': 'apache',
             'url': 'http://127.0.0.1/server-status?auto',
        })
        return config

    def _get(self):
        return urllib2.urlopen(self.config['url']).read()

    def pair_stat(self, stat, text):
        return re.search('%s:(.+)' % (stat), text).group(1)

    def collect(self):
        status = self._get()

        stat_values = {}
        for stat in self.stats:
            value = self.pair_stat(stat, status)
            stat_values[stat.replace('\s', '_')] = value.strip()

        for k, v in stat_values.iteritems():
            self.publish(k, v)
