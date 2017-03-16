#!/usr/bin/python

"""
Basic logstash error rate checker.

Theory of operation:
    - fetch histogram of error / fatals from logstash for the last ~10 minutes
    - calculate the mean rates before/after a time <delay> seconds in the past
    - if the `after` rate is more than <threshold> times the before rate,
      return an error; else, exit with 0.
"""


import argparse
import getpass
import json
import logging
import os
import sys
import time

import urllib3


class CheckServiceError(Exception):
    """Generic Exception used as a catchall."""

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
    """Shell class for checking services."""

    def __init__(self, host, service_name, logstash_host, user='', password='',
                 verbose=False, delay=120, fail_threshold=2.0,
                 absolute_threshold=1.0):
        """Initialize the checker."""
        self.host = host
        self.service_name = service_name
        self.logstash_host = logstash_host
        self.delay = delay
        self.fail_threshold = fail_threshold
        self.absolute_threshold = absolute_threshold
        self.auth = None
        self.logger = logging.getLogger(__name__)

        if user:
            self.auth = '{}:{}'.format(user, password)

    def _logstash_query(self):
        if self.service_name == 'mwdeploy':
            return self._mwdeploy_query()

        return self._make_logstash_query()

    def _mwdeploy_query(self):
        """Return a query that tracks MediaWiki deploy problems."""
        query = ('host:("%(host)s") '
                 'AND ((type:mediawiki '
                 'AND channel:exception) '
                 'OR type:hhvm)') % vars(self)

        return {
            "size": 0,
            "aggs": {
                "2": {
                    "date_histogram": {
                        "interval": "10s",
                        "field": "@timestamp"
                    }
                }
            },
            "query": {
                "bool": {
                    "filter": [
                        {
                            "range": {
                                "@timestamp": {
                                    "lte": "now",
                                    "gte": "now-60m"
                                }
                            }
                        },
                        {
                            "query_string": {
                                "query": query
                            }
                        }
                    ],
                    "must_not": [
                        {
                            "terms": {
                                "level": [
                                    "INFO",
                                    "NOTICE",
                                    "WARNING"
                                ]
                            }
                        },
                        {
                            "match": {
                                "message": {
                                    "query": "SlowTimer",
                                    "type": "phrase"
                                }
                            }
                        },
                        {
                            "match": {
                                "message": {
                                    "query": "Invalid host name",
                                    "type": "phrase"
                                }
                            }
                        }
                    ]
                }
            }
        }

    def _make_logstash_query(self):
        query = ('host:("%(host)s") '
                 'AND (level:("ERROR") OR level:("FATAL")) '
                 'AND type:("%(service_name)s")') % vars(self)

        return {
            "size": 0,
            "aggs": {
                "2": {
                    "date_histogram": {
                        "interval": "10s",
                        "field": "@timestamp"
                    }
                }
            },
            "query": {
                "bool": {
                    "filter": [
                        {
                            "range": {
                                "@timestamp": {
                                    "lte": "now",
                                    "gte": "now-60m"
                                }
                            }
                        },
                        {
                            "query_string": {
                                "query": query
                            }
                        }
                    ]
                }
            }
        }

    def run(self):
        """
        Query logstash and check error rate.

        Queries logstash & checks whether a deploy caused a significant
        increase in the event rate.
        """
        # Query logstash
        http = self._spawn_downloader()

        if self.auth:
            headers = urllib3.util.make_headers(basic_auth=self.auth)
        else:
            headers = urllib3.util.make_headers()

        headers['content-type'] = "application/json"
        logstash_search_url = os.path.join(self.logstash_host,
                                           'logstash-*', '_search')
        try:
            response = fetch_url(
                http,
                logstash_search_url,
                timeout=10,
                headers=headers,
                method='POST',
                body=self._logstash_query()
            )
            resp = response.data.decode('utf-8')
            r = json.loads(resp)
        except ValueError:
            raise ValueError("Logstash request returned error")

        self.logger.debug('logstash response %s', r)

        # Calculate mean event rates before / after the deploy.
        entries = r['aggregations']['2']['buckets']
        cutoff_ts = (time.time() - self.delay) * 1000

        counts_before = [entry['doc_count'] for entry in entries
                         if entry['key'] < cutoff_ts]

        mean_before = float(sum(counts_before)) / max(1, len(counts_before))

        counts_after = [entry['doc_count'] for entry in entries
                        if entry['key'] >= cutoff_ts]

        mean_after = float(sum(counts_after)) / max(1, len(counts_after))

        # Check if there was a significant increase in the rate.
        target_error_rate = max(
            self.absolute_threshold, (mean_before * self.fail_threshold))

        over_threshold = mean_after > target_error_rate

        if over_threshold:
            percent_over = (1 - target_error_rate / mean_after) * 100

            self.logger.error('%d%% OVER_THRESHOLD (Avg. Error rate: '
                              'Before: %.2f, After: %.2f, Threshold: %.2f)',
                              percent_over, mean_before, mean_after,
                              target_error_rate)

        else:
            self.logger.info('OK (Avg. Error rate: '
                             'Before: %.2f, After: %.2f, Threshold: %.2f)',
                             mean_before, mean_after, target_error_rate)

        return over_threshold

    def _spawn_downloader(self):
        """Spawn a urllib3.Poolmanager with the correct configuration."""
        kw = {
            # 'retries': 1, uncomment this once we've got rid of trusty
            'timeout': 10
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolManager(**kw)


def main():
    """Handle args, kick off check."""
    parser = argparse.ArgumentParser(
        description='Check the error rate change of a single WMF service/host',
        epilog='Example: logstash_checker.py --host mw1167 --user "<user>" -p')

    parser.add_argument('--service-name', default='mediawiki',
                        help='The service name to match')
    parser.add_argument('--host', required=True, help='The host to check')
    parser.add_argument('--logstash-host',
                        default='https://logstash.wikimedia.org:9200',
                        help='The logstash host.')
    parser.add_argument('--delay', default=120, type=int,
                        help='Length of the delay (in seconds) between a '
                             'deploy & the call to this check script')
    parser.add_argument('--fail-threshold', type=float, default=2.0,
                        help='Event rate change ratio before / after delay '
                             'that is considered a failure')
    parser.add_argument('--absolute-threshold', type=float, default=1.0,
                        help='Average error rate per 10s above which we '
                             'will compare the error rate before / after '
                             'delay (i.e., if the 10s error rate is below '
                             'this threshold -- all is well')
    parser.add_argument('--user', '-u',
                        help='User for logstash authentication')
    parser.add_argument('--password', '-p', action='store_true',
                        help='Prompt for password')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='More verbose output')

    args = parser.parse_args()
    args = vars(args)

    if args.get('password'):
        password = getpass.getpass().strip()
        args.update({'password': password})

    log_level = logging.INFO

    if args.get('verbose'):
        log_level = logging.DEBUG

    logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

    # Turn off urllib3 logging
    logging.getLogger('urllib3').setLevel(logging.WARNING)

    args.pop('verbose')

    checker = CheckService(**args)
    sys.exit(checker.run())


if __name__ == '__main__':
    main()
