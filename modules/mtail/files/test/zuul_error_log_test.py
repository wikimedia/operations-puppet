import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class ZuulErrorLogTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/zuul_error_log.mtail'),
                os.path.join(test_dir, 'logs/zuul_error_log.test'))

    def testZuulExceptions(self):
        s = self.store.get_samples('zuul_exceptions_total')
        self.assertIn(('', 2), s)
