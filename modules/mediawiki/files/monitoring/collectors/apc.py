# coding=utf-8

"""
Collect stats from our own apc_stats.php

#### Dependencies

 * json
 * urllib2

"""

import json
import urllib2
import diamond.collector


class MW_ApcCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        pass

    def get_default_config(self):
        config = super(MW_ApcCollector, self).get_default_config()
        config.update({
            'host': 'localhost',
            'url': 'apc',
            'timeout': 5
        })
        return config

    def collect(self):
        # publish stats with self.publish
        url = "http://127.0.0.1/{}".format(
            self.config['url']
        )
        headers = {
            'User-agent': 'diamond-apc-collector/1.0',
            'Host': self.config['host']
        }
        try:
            req = urllib2.Request(url, None, headers)
            response = urllib2.urlopen(req, None, self.config['timeout'])
        except urllib2.HTTPError as e:
            self.log.error(
                'Got error status code %d from the HTTP server',
                e.code)
            return
        except urllib2.URLError as e:
            self.log.error('Could not contact server on localhost')
            return

        try:
            data = json.load(response)
            for k, v in data.iteritems():
                metric = 'apache2.mod_php.apc.{}'.format(k)
                self.publish(metric, v)
        except:
            self.log.error(
                "error parsing and publishing data received:\n%s",
                response.read())
            return
