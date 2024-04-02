#!/usr/bin/python3
"""
Basic logstash error rate checker.

Theory of operation:
    - fetch histogram of error / fatals from logstash for the last hour
    - calculate the mean rates before/after a time <delay> seconds in the past
    - if the `after` rate is more than <fail-threshold> times the before rate,
      return an error; else, exit with 0.
"""


import argparse
import getpass
import json
import logging
import os
import sys
import time
import yaml

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
            headers = kw.get('headers', {})
            content_type = headers.get('content-type', '')

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
            urllib3.exceptions.ConnectionError,
            urllib3.exceptions.ReadTimeoutError):
        raise CheckServiceError("Timeout on connection while "
                                "downloading {}".format(url))
    except Exception as e:
        raise CheckServiceError("Generic connection error: {}".format(e))


class CheckService(object):
    """Shell class for checking services."""

    def __init__(self, host, service_name, logstash_host, user='', password='',
                 verbose=False, delay=120.0, fail_threshold=2.0,
                 absolute_threshold=1.0,
                 mediawiki_deployments_file="/etc/helmfile-defaults/mediawiki-deployments.yaml"):
        """Initialize the checker."""
        self.host = host
        self.service_name = service_name
        self.logstash_host = logstash_host
        self.delay = delay
        self.fail_threshold = fail_threshold
        self.absolute_threshold = absolute_threshold
        self.mediawiki_deployments_file = mediawiki_deployments_file
        self.auth = None
        self.logger = logging.getLogger(__name__)

        if user:
            self.auth = '{}:{}'.format(user, password)

    def _logstash_query(self):
        if self.service_name == 'mwdeploy':
            return self._mwdeploy_query()

        return self._make_logstash_query()

    def _get_baremetal_mediawiki_canaries(self) -> set:
        bare_metal_canaries = set()

        for group in ["mediawiki-api-canaries", "mediawiki-appserver-canaries"]:
            with open(os.path.join("/etc/dsh/group", group)) as f:
                for canary in f.readlines():
                    canary = canary.strip()
                    if canary == "" or canary.startswith("#"):
                        continue
                    # Strip domain from hostname since logstash records hold unqualified hostnames.
                    canary = canary.split(".")[0]
                    bare_metal_canaries.add(canary)

        return bare_metal_canaries

    def _get_k8s_canary_namespaces(self) -> set:
        res = set()

        if os.path.exists(self.mediawiki_deployments_file):
            with open(self.mediawiki_deployments_file) as f:
                for entry in yaml.load(f):
                    if entry.get("canary"):
                        res.add(entry["namespace"])

        return res

    def _one_of_query(self, key, values) -> str:
        return f"{key}:(" + " OR ".join(values) + ")"

    def _mwdeploy_query(self):
        """Return a query that tracks MediaWiki deploy problems."""

        if self.host == "canaries":
            host_query = []

            k8s_labels_deployment = self._get_k8s_canary_namespaces()
            if k8s_labels_deployment:
                host_query.append("(kubernetes.labels.release:canary AND "
                                  + self._one_of_query("kubernetes.labels.deployment",
                                                       k8s_labels_deployment)
                                  + ")")

            baremetal_mediawiki_canaries = self._get_baremetal_mediawiki_canaries()
            if baremetal_mediawiki_canaries:
                host_query.append(self._one_of_query("host", baremetal_mediawiki_canaries))

            host_query = " OR ".join(host_query)
        else:
            host_query = f'host:"{self.host}"'

        query = (f"{host_query} AND type:mediawiki AND channel:(exception OR error)")

        return {
            # "size": 0, means don't return the matching records, just count.
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
                                    "DEBUG"
                                ]
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

    def run(self) -> int:
        """
        Query logstash and check error rate.

        Queries logstash & checks whether a deploy caused a significant
        increase in the event rate.

        Returns:
        0  if the error rate is below threshold.
        10 if the error threshold has been exceeded.
        1  if some other error occurred.
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
        query_object = self._logstash_query()
        self.logger.debug('logstash query: %s', query_object)
        try:
            response = fetch_url(
                http,
                logstash_search_url,
                timeout=10,
                headers=headers,
                method='POST',
                body=query_object
            )
            resp = response.data.decode('utf-8')
            r = json.loads(resp)
            self.logger.debug('logstash response %s', r)
        except ValueError as e:
            raise ValueError(f"Logstash request returned error: {e}")

        if type(r) is not dict:
            raise ValueError(
                "Unexpected response from %s. Expected a dict but got: %s\n\nQuery was: %s"
                % (logstash_search_url, json.dumps(r), json.dumps(query_object)))

        if r.get('error', None):
            raise ValueError(
                "Logstash request to %s returned error:\n%s\n\nQuery was: %s"
                % (logstash_search_url, r, json.dumps(query_object)))

        # Calculate mean event rates before / after the deploy.

        # buckets is an array of records like the following:
        # {
        #     "key_as_string": "2024-02-15T20:15:00.000Z",
        #     "key": 1708028100000,
        #     "doc_count": 0
        # },
        # {
        #     "key_as_string": "2024-02-15T20:15:10.000Z",
        #     "key": 1708028110000,
        #     "doc_count": 1
        # },
        # {
        #     "key_as_string": "2024-02-15T20:15:20.000Z",
        #     "key": 1708028120000,
        #     "doc_count": 1
        # },

        # The "key" appears to be a unix timestamp with millisecond resolution.

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

            self.logger.error('%d%% OVER_THRESHOLD (Avg. errors per 10 seconds: '
                              'Before: %.2f, After: %.2f, Threshold: %.2f)',
                              percent_over, mean_before, mean_after,
                              target_error_rate)

        else:
            self.logger.info('OK (Avg. errors per 10 seconds: '
                             'Before: %.2f, After: %.2f, Threshold: %.2f)',
                             mean_before, mean_after, target_error_rate)

        return 10 if over_threshold else 0

    def _spawn_downloader(self):
        """Spawn a urllib3.Poolmanager with the correct configuration."""
        kw = {
            'retries': 1,
            'timeout': 10
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolManager(**kw)


def main():
    """Handle args, kick off check."""
    parser = argparse.ArgumentParser(
        description='Check the error rate change across all WMF canaries, or a single service/host',
        epilog=f'Example: {__file__} --service-name mwdeploy '
        '--logstash-host logstash1023.eqiad.wmnet:9200 --host canaries')

    parser.add_argument('--service-name', default='mediawiki',
                        help='The service name to match')
    parser.add_argument('--host', required=True,
                        help='The host to check.  '
                        'Specify "canaries" to check all MediaWiki canaries')
    parser.add_argument('--logstash-host',
                        default='https://logstash.wikimedia.org:9200',
                        help='The logstash host.')
    parser.add_argument('--delay', default=120.0, type=float,
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
    parser.add_argument('--mediawiki-deployments-file',
                        default='/etc/helmfile-defaults/mediawiki-deployments.yaml',
                        help='The file to read to determine k8s canary deployment namespaces, '
                        'when using --host "canaries"')

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
    try:
        sys.exit(checker.run())
    except CheckServiceError as e:
        # Avoid spamming the user with nested backtraces when there
        # are connection problems to logstash.
        logging.error(e)
        sys.exit(1)


if __name__ == '__main__':
    main()
