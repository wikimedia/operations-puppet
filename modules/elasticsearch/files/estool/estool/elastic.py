from __future__ import print_function

import logging
import time


logger = logging.getLogger('estool.elastic')

class ElasticException(Exception):
    pass


class Elastic(object):
    def __init__(self, elasticsearch, timeout=10, master_timeout=10):
        self.logger = logging.getLogger('estool.elastic.Elastic')
        self.master_timeout = master_timeout
        self.timeout = timeout
        self.elasticsearch = elasticsearch

    def cluster_health(self):
        return self.elasticsearch.cluster.health(
            master_timeout=self.master_timeout,
            timeout=self.timeout)['status']

    def is_cluster_healthy(self):
        try:
            return self.cluster_health() == "green"
        except:
            self.logger.warn("Error while checking for cluster health")
            return False

    def is_longest_running_node_in_cluster(self):

        node_stats = self.elasticsearch.nodes.stats(metric='jvm')

        local_node_stats = self.elasticsearch.nodes.stats(metric='jvm', node_id='_local')
        local_node_uptime = local_node_stats['nodes'][local_node_stats['nodes'].keys()[0]]['jvm']['uptime_in_millis']

        return local_node_uptime >= longest_uptime(node_stats)

    def cluster_status(self, columns=None):
        cluster_health = self.elasticsearch.cluster.health(
            master_timeout=self.master_timeout,
            timeout=self.timeout)
        if columns is None:
            columns = sorted(cluster_health)
        values = [cluster_health[x] for x in columns]

        column_fmt = ' '.join('{:>}' for x in columns)
        value_fmt = ' '.join('{:>%s}' % len(x) for x in columns)

        yield column_fmt.format(*columns)
        yield value_fmt.format(*values)

    def get_banned_nodes(self, node_type):
        res = self.elasticsearch.cluster.get_settings(
            master_timeout=self.master_timeout,
            timeout=self.timeout)
        try:
            bannedstr = res["transient"]["cluster"]["routing"]["allocation"]["exclude"][node_type]
            if bannedstr:
                return bannedstr.split(",")
        except KeyError:
            pass
        return []

    def set_banned_nodes(self, nodelist, node_type):
        return self.set_setting("cluster.routing.allocation.exclude." + node_type,
                                ",".join(nodelist))

    def set_allocation_state(self, status, max_attempts=10):
        retry(
            lambda: self.set_setting("cluster.routing.allocation.enable", status),
            max_attempts)

    def set_setting(self, setting, value, settingtype="transient"):
        res = self.elasticsearch.cluster.put_settings(
            body={
                settingtype: {
                    setting: value
                }
            }
        )
        if res["acknowledged"]:
            return
        else:
            raise ElasticException("Could not set settings")


def longest_uptime(nodes_stats):
    max_uptime = 0
    for node_id, node in nodes_stats['nodes'].iteritems():
        max_uptime = max(max_uptime, node['jvm']['uptime_in_millis'])
    return max_uptime


def retry(action, max_attempts=10, sleep_between_attempts=3):
    for attempt in range(max_attempts):
        try:
            return action()
        except:
            logger.warn("failed! -- retrying (%d/%d)" % (attempt, max_attempts))
            time.sleep(sleep_between_attempts)
    raise ElasticException("Number of attempts exceeded, aborting")
