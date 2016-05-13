from __future__ import print_function

import time


class Elastic(object):
    def __init__(self, elasticsearch, timeout=10, master_timeout=10):
        self._master_timeout = master_timeout
        self._timeout = timeout
        self._elasticsearch = elasticsearch

    def cluster_health(self):
        return self._elasticsearch.cluster.health(
            master_timeout=self._master_timeout,
            timeout=self._timeout)['status']

    def is_cluster_healthy(self):
        try:
            return self.cluster_health() == "green"
        except:
            print("Error while checking for cluster health")
            return False

    def is_longest_running_node_in_cluster(self):

        node_stats = self._elasticsearch.nodes.stats(metric='jvm')

        local_node_stats = self._elasticsearch.nodes.stats(metric='jvm', node_id='_local')
        local_node_uptime = local_node_stats['nodes'][local_node_stats['nodes'].keys()[0]]['jvm']['uptime_in_millis']

        return local_node_uptime >= longest_uptime(node_stats)

    def cluster_status(self, columns=None):
        cluster_health = self._elasticsearch.cluster.health(
            master_timeout=self._master_timeout,
            timeout=self._timeout)
        if columns is None:
            columns = sorted(cluster_health)
        values = [cluster_health[x] for x in columns]

        column_fmt = ' '.join('{:>}' for x in columns)
        value_fmt = ' '.join('{:>%s}' % len(x) for x in columns)

        yield column_fmt.format(*columns)
        yield value_fmt.format(*values)

    def get_banned_nodes(self, node_type):
        res = self._elasticsearch.cluster.get_settings(
            master_timeout=self._master_timeout,
            timeout=self._timeout)
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

    def set_allocation_state(self, status, replication_enable_attempts=10):
        for attempt in range(replication_enable_attempts):
            try:
                if self.set_setting("cluster.routing.allocation.enable", status):
                    return True
            except:
                time.sleep(3)
                print("failed! -- retrying (%d/%d)" % (attempt,
                                                       replication_enable_attempts))
        return False

    def set_setting(self, setting, value, settingtype="transient"):
        res = self._elasticsearch.cluster.put_settings(
            body={
                settingtype: {
                    setting: value
                }
            }
        )
        if res["acknowledged"]:
            return True
        else:
            return False


def longest_uptime(node_stats):
    max_uptime = 0
    for node_id, node in node_stats['nodes'].iteritems():
        max_uptime = max(max_uptime, node['jvm']['uptime_in_millis'])
    return max_uptime
