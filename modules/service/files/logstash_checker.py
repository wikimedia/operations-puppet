#!/usr/bin/python

"""
Basic logstash error rate checker

Theory of operation:
    - fetch histogram of error / fatals from logstash for the last ~10 minutes
    - calculate the mean rates before/after a time <delay> seconds in the past
    - if the `after` rate is more than <threshold> times the before rate,
      return an error; else, exit with 0.
"""


import sys
reload(sys)
sys.setdefaultencoding('utf-8')

try:
    import urlparse
except ImportError:
    import urllib.parse as urlparse
import json
import urllib3
import sys
import argparse
import re
import urllib
import time
from collections import namedtuple


class CheckServiceError(Exception):

    """
    Generic Exception used as a catchall
    """
    pass


def fetch_url(client, url, **kw):
    """
    Standalone function to fetch an url.

    Args:
        client (urllib3.Poolmanager):
                                 The HTTP client we want to use
        url (str): The URL to fetch

        kw: any keyword arguments we want to pass to
            urllib3.request.RequestMethods.request
    """
    if 'method' in kw:
        method = kw['method'].upper()
        del kw['method']
    else:
        method = 'GET'
    try:
        if method == 'GET':
            return client.request(
                method,
                url,
                **kw
            )
        elif method == 'POST':
            try:
                headers = kw.get('headers', {})
                content_type = headers.get('content-type', '')
            except:
                content_type = ''

            # Handle json-encoded requests
            if content_type.lower() == 'application/json':
                kw['body'] = json.dumps(kw['body'])
                return client.urlopen(
                    method,
                    url,
                    **kw
                )

            return client.request_encode_body(
                method,
                url,
                encode_multipart=False,
                **kw
            )
    except urllib3.exceptions.SSLError:
        raise CheckServiceError("Invalid certificate")
    except (urllib3.exceptions.ConnectTimeoutError,
            urllib3.exceptions.TimeoutError,
            # urllib3.exceptions.ConnectionError, # commented out until we can
            # remove trusty (aka urllib3 1.7.1) support
            urllib3.exceptions.ReadTimeoutError):
        raise CheckServiceError("Timeout on connection while "
                                "downloading {}".format(url))
    except Exception as e:
        raise CheckServiceError("Generic connection error: {}".format(e))


class CheckService(object):

    """
    Shell class for checking services
    """
    nagios_codes = ['OK', 'WARNING', 'CRITICAL']
    spec_url = '/?spec'
    default_response = {'status': 200}
    _supported_methods = ['get', 'post']

    def __init__(self, args):
        """
        Initialize the checker

        Args:
            host_ip (str): The host ipv4 address (also works with a hostname)

            base_url (str): The base url the service expects to respond from

            timeout (int): Number of seconds to wait for each request
        """
        self.host = args.host
        self.service_name = args.service_name
        self.delay = args.delay
        self.threshold = 2
        self.logstash_query_url = 'https://logstash.wikimedia.org/logstash-2016.06.02/_search'
        #args.logstash_query_url

    def _logstashQuery(self):
        return {"facets":{"0":{
            "date_histogram":{"field":"@timestamp","interval":"10s"},
            "global":True,
            "facet_filter":{"fquery":{"query":{
                "filtered":{"query":{"query_string":{"query":"*"}},
                    "filter":{"bool":{
                        "must":[
                            {"range":{"@timestamp":{"from":"now-10m","to":"now"}}},
                            {"terms":{"_type":["mediawiki"]}},
                            {"fquery":{"query":{"query_string":{"query":"host:(\"" + self.host +
                                "\")"}},"_cache":True}}
                            ],
                        "must_not":[
                            {"fquery":{
                                "query":{"query_string":{"query":"level:(\"INFO\")"}},"_cache":True}},{"fquery":{"query":{"query_string":{"query":"level:(\"WARNING\")"}},"_cache":True}}
                        ]}}}}}}
                    }},"size":20,
                    "query":{"filtered":{"query":{"query_string":{"query":"type:scap AND (channel.raw:scap.announce OR message:\"Started sync_wikiversions\")"}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":"now","to":"now"}}}]}}}},
                    "sort":[{"@timestamp":{"order":"desc","ignore_unmapped":True}},{"@timestamp":{"order":"desc","ignore_unmapped":True}}]}

    def run(self):
        """
        Gets the full spec from base_url + '/?spec' and parses it.
        Returns a generator iterating over the available endpoints
        """
        http = self._spawn_downloader()
        headers=urllib3.util.make_headers(basic_auth='user:pass')
        headers['content-type'] = "application/json"
        response = fetch_url(
            http,
            self.logstash_query_url,
            timeout=5,
            headers=headers,
            method='POST',
            body=self._logstashQuery()
        )
        resp = response.data.decode('utf-8')

        try:
            r = json.loads(resp)
        except ValueError:
            raise ValueError("Logstash request returned error")

        print r


        entries = r['facets']['0']['entries']
        cutoff_ts = (time.time() - self.delay) * 1000
        print cutoff_ts
        counts_before = [entry['count'] for entry in entries
                            if entry['time'] < cutoff_ts]
        mean_before = float(sum(counts_before)) / max(1, len(counts_before))
        counts_after = [entry['count'] for entry in entries
                            if entry['time'] >= cutoff_ts]
        print 'counts_after', counts_after
        mean_after = float(sum(counts_after)) / max(1, len(counts_after))
        over_threshold = mean_after > (mean_before * self.threshold)
        print 'over_threshold', mean_before, mean_after, over_threshold
        sys.exit(over_threshold)

    def _spawn_downloader(self):
        """
        Spawns an urllib3.Poolmanager with the correct configuration.
        """
        kw = {
            # 'retries': 1, uncomment this once we've got rid of trusty
            'timeout': 5
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolManager(**kw)


def main():
    parser = argparse.ArgumentParser(
        description="Checks the error rate change of a single "
            "WMF service / host")
    parser.add_argument('host', help="The host to check")
    parser.add_argument('service_name',
                        help="The service name to match")
    parser.add_argument('-d', dest="delay", default=5, type=int,
                        help="Length of the delay between a deploy & the call"
                            "to this check script")
    args = parser.parse_args()
    checker = CheckService(args)
    checker.run()


if __name__ == '__main__':
    main()
