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
        m = self.store.get_metric('varnish_x_cache')
        self.assertEqual(2, m._value)
        self.assertIn('x_cache=int-front', m._labelpairs)


class VarnishRlsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishrls.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testIfNoneMatch(self):
        m = self.store.get_metric('varnish_resourceloader_inm')
        self.assertEquals(m._value, 1)


class VarnishMediaTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishmedia.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testThumbnails(self):
        m = self.store.get_metric('varnish_thumbnails')
        self.assertEquals(2, m._value)
        self.assertIn('status=200', m._labelpairs)


class VarnishXcpsTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/varnishxcps.mtail'),
                os.path.join(test_dir, 'logs/varnish.test'))

    def testH2(self):
        m = self.store.get_metric('tls_h2')
        self.assertEqual(1, m._value)

    def testReusedSessions(self):
        m = self.store.get_metric('tls_sess_reused')
        self.assertEqual(1, m._value)

    def testTLSversion(self):
        m = self.store.get_metric('tls_version')
        self.assertEqual(1, m._value)
        self.assertIn('version=TLSv1.2', m._labelpairs)

    def testTLSKeyExchange(self):
        m = self.store.get_metric('tls_key_exchange')
        self.assertEqual(1, m._value)
        self.assertIn('type=X25519', m._labelpairs)

    def testTLSAuth(self):
        m = self.store.get_metric('tls_auth')
        self.assertEqual(1, m._value)
        self.assertIn('type=ECDSA', m._labelpairs)

    def testTLSCipher(self):
        m = self.store.get_metric('tls_cipher')
        self.assertEqual(1, m._value)
        self.assertIn('name=CHACHA20-POLY1305', m._labelpairs)

    def testTLSFullCipher(self):
        m = self.store.get_metric('tls_full_cipher')
        self.assertEqual(1, m._value)
        self.assertIn('name=ECDHE-ECDSA-CHACHA20-POLY1305', m._labelpairs)
