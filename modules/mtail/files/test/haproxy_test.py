import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class HaproxyTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/haproxy.mtail'),
                os.path.join(test_dir, 'logs/haproxy.test'))

    def testRespStatus(self):
        s = self.store.get_samples('haproxy_http_request_duration_count')
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404', 5), s)
        s = self.store.get_samples('haproxy_http_request_duration_sum')
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200', 2.5813), s)
        self.assertIn(
            (u'backend=thumbor,backend_server=server8889,status_code=404', 0.0008000000000000001),
            s)
        s = self.store.get_samples('haproxy_http_request_duration_bucket')
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=2.5', 2), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=5', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=10', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=15', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=20', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=30', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=60', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=200,le=+Inf', 8), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.005', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.025', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.05', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.1', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.25', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=0.5', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=1', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=2.5', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=5', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=10', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=15', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=20', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=30', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=60', 5), s)
        self.assertIn((u'backend=thumbor,backend_server=server8889,status_code=404,le=+Inf', 5), s)
