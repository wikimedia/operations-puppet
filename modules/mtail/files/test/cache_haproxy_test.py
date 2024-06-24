# SPDX-License-Identifier: Apache-2.0
import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class CacheHAProxyTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/cache_haproxy.mtail'),
                os.path.join(test_dir, 'logs/cache_haproxy.test'))

    def testClientMetrics(self):
        s = self.store.get_samples('haproxy_client_ttfb')
        s_dict = dict(s)

        count_2xx = s_dict['cache_status=hit,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
        count_2xx = s_dict['cache_status=miss,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
        count_2xx = s_dict['cache_status=int-front,http_status_family=2']['count']
        self.assertEqual(count_2xx, 2)
        count_4xx = s_dict['cache_status=int-front,http_status_family=4']['count']
        self.assertEqual(count_4xx, 2)
        count_5xx = s_dict['cache_status=none,http_status_family=5']['count']
        self.assertEqual(count_5xx, 1)

        self.assertEqual(s_dict['cache_status=int-front,http_status_family=4']['buckets']['0.001'],
                         2)
        self.assertEqual(s_dict['cache_status=hit,http_status_family=2']['buckets']['0.07'], 1)
        self.assertEqual(s_dict['cache_status=miss,http_status_family=2']['buckets']['0.15'], 1)

        s = self.store.get_samples('haproxy_client_healthcheck_ttfb')
        s_dict = dict(s)

        count_2xx = s_dict['cache_status=int-front,http_status_family=2']['count']
        self.assertEqual(count_2xx, 2)

        s = self.store.get_samples('haproxy_termination_states_total')
        self.assertIn(('termination_state=--', 6), s)
        self.assertIn(('termination_state=IH', 1), s)
        self.assertIn(('termination_state=CD', 1), s)

    def testSLI(self):
        sli_total = self.store.get_samples('haproxy_sli_total')
        self.assertIn(('', 8), sli_total)

        sli_good = self.store.get_samples('haproxy_sli_good')
        self.assertIn(('', 7), sli_good)

        sli_bad = self.store.get_samples('haproxy_sli_bad')
        self.assertIn(('', 1), sli_bad)
