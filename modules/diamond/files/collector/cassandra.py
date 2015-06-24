# coding=utf-8

"""
Collect basic metrics from cassandra using nodetool (yuk!)
"""

import subprocess
import re

import diamond.collector


class CassandraCollector(diamond.collector.Collector):
    def get_default_config(self):
        config = super(CassandraCollector, self).get_default_config()
        config.update({
            'path':         'cassandra',
        })
        return config

    def publish_dict(self, prefix, metrics):
        for name, value in metrics.iteritems():
            self.publish('.'.join((prefix, name)), value)

    def _nodetool(self, *args):
        command = ['/usr/bin/nodetool']
        command.extend(args)
        self.log.debug('Running %r' % command)
        return subprocess.check_output(command).split('\n')

    def nodetool_gcstats(self):
        output = self._nodetool('gcstats')
        names = ['interval', 'elapsed_max', 'elapsed_total', 'elapsed_stdev',
                 'reclaimed_mb', 'collections']
        values = re.split(r'\s+', output[1].strip())
        return dict(zip(names, values))

    def nodetool_compactionstats(self):
        output = self._nodetool('compactionstats')
        metrics = {}
        for line in output:
            m = re.search('pending tasks: (\d+)', line)
            if m:
                metrics['pending'] = m.group(1)
        return metrics

    def nodetool_status(self):
        output = self._nodetool('status')
        status_map = {
            'U': 'up', 'D': 'down',
            'N': 'normal', 'L': 'leaving',
            'J': 'joining', 'M': 'moving',
        }
        metrics = {}
        in_status = False
        for line in output:
            if line.startswith('--  '):
                in_status = True
            if not in_status:
                continue
            if re.match('^[UD][NLJM]  ', line):
                node_updown = status_map[line[0]]
                node_status = status_map[line[1]]
                metrics[node_updown] = metrics.setdefault(node_updown, 0) + 1
                metrics[node_status] = metrics.setdefault(node_status, 0) + 1
        return metrics

    def nodetool_tpstats(self):
        output = self._nodetool('tpstats')
        names = ['name', 'active', 'pending', 'completed',
                 'blocked', 'all_time_blocked']
        metrics = {}
        for line in output[1:]:
            parts = re.split('\s+', line.strip())
            if len(parts) != len(names):
                continue
            tp_stat = dict(zip(names, parts))
            for key, value in tp_stat.iteritems():
                if key == 'name':
                    continue
                metric_name = '.'.join((tp_stat['name'], key))
                metrics[metric_name] = value
        return metrics

    def collect(self):
        self.publish_dict('status', self.nodetool_status())
        self.publish_dict('compaction', self.nodetool_compactionstats())
        self.publish_dict('gc', self.nodetool_gcstats())
        self.publish_dict('tpstats', self.nodetool_tpstats())
