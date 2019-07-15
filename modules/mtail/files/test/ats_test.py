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
        s = self.store.get_samples('ats_backend_requests_seconds_count')
        self.assertIn(('status=200,method=GET,backend=swift.discovery.wmnet', 2), s)

        bucket_samples = self.store.get_samples('ats_backend_requests_seconds_bucket')
        self.assertIn(('le=0.1,method=GET,backend=appservers-rw.discovery.wmnet', 1),
                      bucket_samples)

        sum_samples = self.store.get_samples('ats_backend_requests_seconds_sum')
        self.assertIn(('status=304,method=GET,backend=swift.discovery.wmnet', 0.055),
                      sum_samples)
