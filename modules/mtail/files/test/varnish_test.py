# SPDX-License-Identifier: Apache-2.0
import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class VarnishXcacheTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishxcache.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testCacheStatus(self):
        s = self.store.get_samples('varnish_x_cache')
        self.assertIn(('x_cache=int-front,status=301', 2), s)
        self.assertIn(('x_cache=hit-front,status=200', 7), s)


class VarnishRlsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishrls.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testIfNoneMatch(self):
        s = self.store.get_samples('varnish_resourceloader_inm')
        self.assertIn(('', 1), s)

    def testResp(self):
        s = self.store.get_samples('varnish_resourceloader_resp')
        self.assertIn(('status=200,cache_control=long,x_cache=hit-front', 2), s)
        self.assertIn(('status=304,cache_control=short,x_cache=hit-front', 1), s)
        self.assertIn(('status=304,cache_control=no,x_cache=hit-front', 1), s)


class VarnishMediaTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishmedia.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testThumbnails(self):
        s = self.store.get_samples('varnish_thumbnails')
        self.assertIn(('status=200', 2), s)


class VarnishReqStatsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishreqstats.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testRespStatus(self):
        s = self.store.get_samples('varnish_requests')
        self.assertIn(('status=200,method=GET', 6), s)
        self.assertIn(('status=301,method=GET', 2), s)
        self.assertIn(('status=200,method=HEAD', 2), s)
        self.assertIn(('status=200,method=invalid', 1), s)


class VarnishTTFBTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishttfb.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testTTFBHistogram(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb')
        s_dict = dict(s)
        self.assertIn('origin=cp3052,cache_status=hit', s_dict)
        self.assertIn('origin=cp3062,cache_status=miss', s_dict)

    def testTTFBSum(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb')
        values = dict(s)['origin=cp3062,cache_status=miss']
        self.assertEqual(values['sum'], 0.155195)

    def testTTFBBucket(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb')
        values = dict(s)
        self.assertEqual(values['origin=cp3050,cache_status=pass']['buckets']['0.001'], 2)
        self.assertEqual(values['origin=cp3062,cache_status=miss']['buckets']['0.25'], 1)


class VarnishProcessingSecondsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishprocessing.mtail'),
                os.path.join(test_dir, 'logs/varnishinternal.test'))

    def testProcessingCount(self):
        s = dict(self.store.get_samples('varnish_processing_seconds'))
        expected_process = {
           '+Inf': 0,
           '0.0001': 4,
           '0.0005': 6,
           '0.001': 0,
           '0.005': 0,
           '0.01': 0,
           '0.025': 0,
           '0.05': 0,
           '0.1': 0,
           '0.5': 0,
           '1': 0
        }
        self.assertEqual(expected_process, s['event=process']['buckets'])


class VarnishErrorsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnisherrors.mtail'),
                os.path.join(test_dir, 'logs/varnishinternal.test'))

    def testErrors(self):
        s = dict(self.store.get_samples('varnish_errors'))
        expected = {
            'type=Error': 1,
            'type=FetchError': 1,
        }
        self.assertEqual(expected, s)


class VarnishSLITest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishsli.mtail'),
                os.path.join(test_dir, 'logs/varnishinternal.test'))

    def testSLI(self):
        sli_all = self.store.get_samples('varnish_sli_all')
        self.assertIn(('', 11), sli_all)

        # Two lines are not good: one has a fetcherror (Resource temporarily
        # unavailable), another has "trestart 0.099903", which makes the
        # timestamps sum go above threshold (0.100001 > 0.1).
        sli_good = self.store.get_samples('varnish_sli_good')
        self.assertIn(('', 8), sli_good)
