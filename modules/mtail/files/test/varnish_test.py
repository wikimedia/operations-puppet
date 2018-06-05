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
        self.assertIn(('x_cache=hit-front,status=200', 6), s)


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


class VarnishXcpsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishxcps.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testH2(self):
        s = self.store.get_samples('xcps_h2')
        self.assertIn(('', 1), s)

    def testReusedSessions(self):
        s = self.store.get_samples('xcps_tls_sess_reused')
        self.assertIn(('', 1), s)

    def testTLS(self):
        s = self.store.get_samples('xcps_tls')
        labels, count = s[0][0], s[0][1]
        expected = [
            'version=TLSv1.2',
            'key_exchange=X25519',
            'auth=ECDSA',
            'cipher=CHACHA20-POLY1305-SHA256',
        ]
        for value in expected:
            self.assertIn(value, labels)

        self.assertEquals(1, count)


class VarnishReqStatsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishreqstats.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testRespStatus(self):
        s = self.store.get_samples('varnish_requests')
        self.assertIn(('status=200,method=GET', 3), s)
        self.assertIn(('status=301,method=GET', 2), s)
        self.assertIn(('status=200,method=HEAD', 2), s)
        self.assertIn(('status=200,method=invalid', 1), s)


class VarnishBackendTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishbackend.mtail'),
                os.path.join(test_dir, 'logs/varnishbackend.test'))

    def testRespStatus(self):
        s = self.store.get_samples('varnish_backend_requests_seconds_count')
        self.assertIn(('status=200,method=GET,backend=be_wdqs_svc_eqiad_wmnet', 12), s)
        self.assertIn(('status=204,method=GET,backend=be_matomo1001_eqiad_wmnet', 2), s)
        self.assertIn(('status=200,method=POST,backend=be_matomo1001_eqiad_wmnet', 1), s)
        self.assertIn(('status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1), s)

        bucket_samples = self.store.get_samples('varnish_backend_requests_seconds_bucket')
        self.assertIn(('le=0.01,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.05,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.1,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.5,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=1.0,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=5.0,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=+Inf,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)

        sum_samples = self.store.get_samples('varnish_backend_requests_seconds_sum')
        self.assertIn(('status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 0.001797),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_wdqs_svc_eqiad_wmnet', 1.229273),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_phab1003_eqiad_wmnet', 1.245995),
                      sum_samples)
        self.assertIn(('status=200,method=GET,backend=be_labmon1001_eqiad_wmnet', 0.049231),
                      sum_samples)
        self.assertIn(('status=200,method=POST,backend=be_matomo1001_eqiad_wmnet', 0.061224),
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
