# SPDX-License-Identifier: Apache-2.0
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
        # counter zuul_gerrit_reporting_errors_total
        # counter zuul_mutexhandler_errors_total
        # counter zuul_unexpected_errors_total
        s = self.store.get_samples('zuul_mutexhandler_errors_total')
        self.assertIn(('', 2), s)
        s = self.store.get_samples('zuul_gerrit_reporting_errors_total')
        self.assertIn(('', 2), s)
        s = self.store.get_samples('zuul_unexpected_errors_total')
        self.assertIn(('', 1), s)
