# SPDX-License-Identifier: Apache-2.0
import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class ATSBackendTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/atsbackend.mtail'),
                os.path.join(test_dir, 'logs/atsbackend.test'))

    def testRespStatus(self):
        s = self.store.get_samples('trafficserver_backend_requests_seconds_count')
        self.assertIn(('status=200,method=GET,backend=swift.discovery.wmnet', 2), s)

        s = self.store.get_samples('trafficserver_backend_connections_total')
        self.assertIn(('backend=swift.discovery.wmnet', 1), s)

        bucket_samples = self.store.get_samples('trafficserver_backend_requests_seconds_bucket')
        self.assertIn(('le=0.1,method=GET,backend=appservers-rw.discovery.wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.07,method=GET,backend=swift.discovery.wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.25,method=GET,backend=swift.discovery.wmnet', 3),
                      bucket_samples)

        sum_samples = self.store.get_samples('trafficserver_backend_requests_seconds_sum')
        self.assertIn(('status=304,method=GET,backend=swift.discovery.wmnet', 0.055),
                      sum_samples)

    def testBackendClientMetrics(self):
        s = self.store.get_samples('trafficserver_backend_client_ttfb_sum')
        self.assertIn(('backend=appservers-rw.discovery.wmnet', 140), s)

        s = self.store.get_samples('trafficserver_backend_client_cache_read_time_sum')
        self.assertIn(('backend=swift.discovery.wmnet', 10), s)

        s = self.store.get_samples('trafficserver_backend_client_cache_write_time_sum')
        self.assertIn(('backend=appservers-rw.discovery.wmnet', 3), s)

        bucket_samples = self.store.get_samples('trafficserver_backend_client_ttfb_bucket')
        self.assertIn(('le=0.25,backend=swift.discovery.wmnet', 3),
                      bucket_samples)


class ATSBackendTimingTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/atsbackendtiming.mtail'),
                os.path.join(test_dir, 'logs/atsbackendtiming.test'))

    def testBackendTiming(self):
        s = self.store.get_samples('ats_backend_timing_count')
        self.assertIn(('', 3), s)
        s = self.store.get_samples('ats_backend_timing_sum')
        self.assertIn(('', 0.7525828999999999), s)
        s = self.store.get_samples('ats_backend_timing_bucket')
        self.assertIn((u'le=0.25', 2), s)
        self.assertIn((u'le=0.5', 2), s)
        self.assertIn((u'le=1', 2), s)
        self.assertIn((u'le=2.5', 2), s)
        self.assertIn((u'le=5', 2), s)
        self.assertIn((u'le=10', 3), s)
        self.assertIn((u'le=15', 3), s)
        self.assertIn((u'le=+Inf', 3), s)


class ATSTLSTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/atstls.mtail'),
                os.path.join(test_dir, 'logs/atstls.test'))

    def testClientMetrics(self):
        s = self.store.get_samples('trafficserver_tls_client_ttfb')
        s_dict = dict(s)
        self.assertIn('cache_status=int-front,http_status_family=2', s_dict)
        self.assertIn('cache_status=hit,http_status_family=2', s_dict)
        self.assertIn('cache_status=miss,http_status_family=4', s_dict)

        values = s_dict['cache_status=int-front,http_status_family=2']
        self.assertEqual(values['sum'], 0.001)
        values = s_dict['cache_status=hit,http_status_family=2']
        self.assertEqual(values['sum'], 0.05)

        self.assertEqual(s_dict['cache_status=int-front,http_status_family=2']['buckets']['0.045'],
                         1)
        self.assertEqual(s_dict['cache_status=hit,http_status_family=2']['buckets']['0.07'], 1)
        self.assertEqual(s_dict['cache_status=miss,http_status_family=4']['buckets']['0.25'], 1)

        s = self.store.get_samples('trafficserver_tls_client_healthcheck_ttfb')
        s_dict = dict(s)

        count_2xx = s_dict['cache_status=int-front,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
