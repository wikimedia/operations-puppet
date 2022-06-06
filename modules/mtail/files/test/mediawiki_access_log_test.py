#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class MediaWikiAccessLogTest(unittest.TestCase):
    def setUp(self):
        self._handler_codes = {
            'php7': 'proxy:unix:/run/php/fpm-www.sock|fcgi://localhost',
            'php74': 'proxy:unix:/run/php/fpm-www-7.4.sock|fcgi://localhost',
            'static': '-'
        }
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/mediawiki_access_log.mtail'),
                os.path.join(test_dir, 'logs/mediawiki_access_log.test'))

    def id_str(self, handler, method='GET', code=200, endpoint=None):
        return "handler=%s,method=%s,code=%d%s" % (
            self._handler_codes[handler],
            method,
            code,
            f",endpoint={endpoint}" if endpoint else ""
        )

    def testByHandler(self):
        """Test requests are correctly divided by handler."""
        s = self.store.get_samples('mediawiki_http_requests_duration')
        for sample in s:
            if sample[0] == self.id_str('php7'):
                self.assertEqual(sample[1]['count'], 6)
            elif sample[0] == self.id_str('static', code=301):
                self.assertEqual(sample[1]['count'], 1)
            elif sample[0] == self.id_str('php74'):
                self.assertEqual(sample[1]['count'], 1)

    def testByBucket(self):
        """Tests requests are correctly divided by bucket."""
        s = self.store.get_samples('mediawiki_http_requests_duration')
        req_id = self.id_str('php7')
        my_sample = None
        # Find the sample with the correct labels
        for sample in s:
            if sample[0] == req_id:
                my_sample = sample
                break
        # verify the sample was found
        self.assertIsNotNone(my_sample)
        # now verify the distribution of requests in the histogram
        bucket = my_sample[1]['buckets']
        self.assertEqual(bucket['0.05'], 2)
        self.assertEqual(bucket['0.1'], 2)
        self.assertEqual(bucket['0.25'], 2)
        self.assertEqual(my_sample[1]['count'], 6)

    def testByEndpoint(self):
        """Test that per-endpoint breakdowns are bucketed correctly."""

        expected_counts = {
            "load": 2, "rest_api": 1, "website": 3}
        actual_counts = {
            "load": 0, "rest_api": 0, "website": 0}

        s = self.store.get_samples('mediawiki_requests_by_endpoint_duration')
        endpoint_ids = {
            self.id_str("php7", endpoint=endpoint):
            endpoint for endpoint in expected_counts.keys()
        }

        for sample in s:
            if sample[0] in endpoint_ids.keys():
                actual_counts[endpoint_ids[sample[0]]] += sample[1]["count"]

        self.assertEqual(expected_counts, actual_counts)
