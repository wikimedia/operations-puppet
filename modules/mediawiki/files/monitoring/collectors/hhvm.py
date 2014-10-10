# coding=utf-8
"""
Collect stats from hhvm

### Dependencies

 * json
 * urllib2

"""

import json
import urllib2
import diamond.collector

class mw_hhvmCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        pass

    def get_default_config(self):
        config = super(mw_hhvmCollector, self).get_default_config()
        config.update({
            'host': 'localhost:9002',
            'url': '/',
            'timeout': 5,
        })

    def collect(self):
        # publish stats with self.publish
        url = "http://{}{}".format(
            self.config['host']
            self.config['url']
        )
        headers = {
            'User-agent': 'diamond-hhvm-collector/1.0',
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
                self.publish(k, v)
        except:
            self.log.error(
                "error parsing and publishing data received:\n%s",
                response.read())
            return
