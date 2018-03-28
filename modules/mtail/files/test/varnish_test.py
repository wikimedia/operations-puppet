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
        self.assertIn(('x_cache=int-front', 2), s)
        self.assertIn(('x_cache=hit-front', 8), s)


class VarnishRlsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishrls.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testIfNoneMatch(self):
        s = self.store.get_samples('varnish_resourceloader_inm')
        self.assertIn(('', 1), s)


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
        self.assertIn(('status=204,method=GET,backend=be_bohrium_eqiad_wmnet', 2), s)
        self.assertIn(('status=200,method=POST,backend=be_bohrium_eqiad_wmnet', 1), s)
        self.assertIn(('status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1), s)

        bucket_samples = self.store.get_samples('varnish_backend_requests_seconds_bucket')
        self.assertIn(('le=0.01,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.05,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.1,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=0.5,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=1.0,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=5.0,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
        self.assertIn(('le=+Inf,status=301,method=GET,backend=be_cp1065_eqiad_wmnet', 1),
                      bucket_samples)
