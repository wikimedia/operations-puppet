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
import os
import json
import argparse
import time

import urllib3

reload(sys)
sys.setdefaultencoding('utf-8')


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

    def __init__(self, host, service_name, logstash_host,
                 auth='', delay=120, fail_threshold=2):
        """
        Initialize the checker
        """
        self.host = host
        self.service_name = service_name
        self.logstash_host = logstash_host
        self.auth = auth
        self.delay = delay
        self.fail_threshold = fail_threshold

    def _logstashQuery(self):
        return {"facets": {"0": {
            "date_histogram": {"field": "@timestamp", "interval": "10s"},
            "global": True,
            "facet_filter": {"fquery": {"query": {
                "filtered": {
                    "query": {
                        "query_string": {
                            "query": "host:(\"" +
                            self.host +
                            "\") AND (level:(\"ERROR\") "
                            "OR level:(\"FATAL\")) "
                            "AND type:(\"" + self.service_name + "\")"
                        }},
                    "filter": {"bool": {
                        "must": [
                            {"range": {
                                "@timestamp": {
                                    "from": "now-60m",
                                    "to": "now"
                                }
                            }}
                        ]}}}}}}
        }}, "size": 0}

    def run(self):
        """
        Queries logstash & checks whether a deploy caused a significant
        increase in the event rate.
        """

        # Query logstash
        http = self._spawn_downloader()
        headers = urllib3.util.make_headers(basic_auth=self.auth)
        headers['content-type'] = "application/json"
        logstash_index_name = time.strftime('logstash-%Y.%m.%d', time.gmtime())

        try:
            response = fetch_url(
                http,
                os.path.join(self.logstash_host,
                             logstash_index_name, '_search'),
                timeout=10,
                headers=headers,
                method='POST',
                body=self._logstashQuery()
            )
            resp = response.data.decode('utf-8')
            r = json.loads(resp)
        except ValueError:
            raise ValueError("Logstash request returned error")

        print 'DEBUG: logstash response', r

        # Calculate mean event rates before / after the deploy.
        entries = r['facets']['0']['entries']
        cutoff_ts = (time.time() - self.delay) * 1000
        counts_before = [entry['count'] for entry in entries
                         if entry['time'] < cutoff_ts]
        mean_before = float(sum(counts_before)) / max(1, len(counts_before))
        counts_after = [entry['count'] for entry in entries
                        if entry['time'] >= cutoff_ts]
        mean_after = float(sum(counts_after)) / max(1, len(counts_after))

        # Check if there was a significant increase in the rate.
        over_threshold = mean_after > (mean_before * self.fail_threshold)
        if over_threshold:
            print 'OVER_THRESHOLD (', mean_before, '->', mean_after, ')'
        else:
            print 'OK (', mean_before, '->', mean_after, ')'

        sys.exit(over_threshold)

    def _spawn_downloader(self):
        """
        Spawns an urllib3.Poolmanager with the correct configuration.
        """
        kw = {
            # 'retries': 1, uncomment this once we've got rid of trusty
            'timeout': 10
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolManager(**kw)


def main():
    parser = argparse.ArgumentParser(
        description="Checks the error rate change of "
        "a single WMF service / host",
        epilog="""
        Example: logstash_checker.py --host mw1167 --auth '<user>:<pass>'
        """)
    parser.add_argument('--service-name',
                        default='mediawiki',
                        help="The service name to match")
    parser.add_argument('--host', required=True, help="The host to check")
    parser.add_argument('--logstash-host',
                        default='https://logstash.wikimedia.org',
                        help="The logstash host.")
    parser.add_argument('--delay',
                        default=120,
                        type=int,
                        help="Length of the delay between a deploy & the call"
                        "to this check script")
    parser.add_argument('--fail-threshold',
                        help="Event rate change ratio "
                        "before / after delay that is considered "
                        "a failure",
                        type=float,
                        default=2.0)
    parser.add_argument('--auth',
                        help="User:Pass for logstash authentication")
    args = parser.parse_args()
    checker = CheckService(**vars(args))
    checker.run()


if __name__ == '__main__':
    main()
