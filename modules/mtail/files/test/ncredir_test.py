import os
import unittest

import mtail_store

test_dir = os.path.join(os.path.dirname(__file__))


class NcredirTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
            os.path.join(test_dir, '../programs/ncredir.mtail'),
            os.path.join(test_dir, 'logs/ncredir.test'))

    def testRespStatus(self):
        s = self.store.get_samples('ncredir_requests_total')
        self.assertIn(('scheme=http,vhost=www.wikipedia.com,method=GET,status=301', 2), s)
        self.assertIn(('scheme=https,vhost=www.wikipedia.com,method=GET,status=301', 1), s)
        self.assertIn(('scheme=https,vhost=wikipedia.co.il,method=GET,status=301', 1), s)
