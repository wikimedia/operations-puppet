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

    def testTTFBCount(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb_count')
        self.assertIn(('origin=cp3052,cache_status=hit', 1), s)
        self.assertIn(('origin=cp3064,cache_status=hit', 2), s)
        self.assertIn(('origin=cp3062,cache_status=miss', 1), s)

    def testTTFBSum(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb_sum')
        self.assertIn(('origin=cp3062,cache_status=miss', 155.195), s)
        self.assertIn(('origin=cp3064,cache_status=hit', 0.548), s)

    def testTTFBBucket(self):
        s = self.store.get_samples('varnish_frontend_origin_ttfb_bucket')
        self.assertIn(('le=0.5,origin=cp3062,cache_status=miss', 1), s)
        self.assertIn(('le=+Inf,origin=cp3062,cache_status=miss', 1), s)
        self.assertIn(('le=0.045,origin=cp3064,cache_status=hit', 2), s)


class VarnishBackendTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishbackend.mtail'),
                os.path.join(test_dir, 'logs/varnishbackend.test'))

    def testRespStatus(self):
        s = self.store.get_samples('varnish_backend_requests_seconds_count')
        self.assertIn(('status=200,method=GET,backend=be_wdqs_svc_xmp_eggnet', 12), s)
        self.assertIn(('status=204,method=GET,backend=be_matomo01_xmp_eggnet', 2), s)
        self.assertIn(('status=200,method=POST,backend=be_matomo01_xmp_eggnet', 1), s)
        self.assertIn(('status=301,method=GET,backend=be_cp65_xmp_eggnet', 1), s)

        bucket_samples = self.store.get_samples('varnish_backend_requests_seconds_bucket')
        self.assertIn(('le=0.01,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.05,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.1,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.5,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=1.0,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=5.0,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)
        self.assertIn(('le=+Inf,method=GET,backend=be_cp65_xmp_eggnet', 1),
                      bucket_samples)

        sum_samples = self.store.get_samples('varnish_backend_requests_seconds_sum')
        self.assertIn(('status=301,method=GET,backend=be_cp65_xmp_eggnet', 0.001797),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_wdqs_svc_xmp_eggnet', 1.229273),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_phab01_xmp_eggnet', 1.245995),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_labmon01_xmp_eggnet', 0.049231),
                      sum_samples)
        self.assertIn(('status=200,method=POST,backend=be_matomo01_xmp_eggnet', 0.061224),
                      sum_samples)


class VarnishBackendTimingTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishbackendtiming.mtail'),
                os.path.join(test_dir, 'logs/varnishbackendtiming.test'))

    def testRespStatus(self):
        s = self.store.get_samples('varnish_backend_timing_count')
        self.assertIn(('', 10), s)
        s = self.store.get_samples('varnish_backend_timing_sum')
        self.assertIn(('', 0.1529112), s)
        s = self.store.get_samples('varnish_backend_timing_bucket')
        self.assertIn((u'le=0.1', 5), s)
        self.assertIn((u'le=0.25', 8), s)
        self.assertIn((u'le=0.5', 10), s)
        self.assertIn((u'le=1', 10), s)
        self.assertIn((u'le=2.5', 10), s)
        self.assertIn((u'le=5', 10), s)
        self.assertIn((u'le=10', 10), s)
        self.assertIn((u'le=15', 10), s)
        self.assertIn((u'le=+Inf', 10), s)
