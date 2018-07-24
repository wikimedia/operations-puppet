import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class KernelTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/kernel.mtail'),
                os.path.join(test_dir, 'logs/kernel.test'))

    def testOOM(self):
        s = self.store.get_samples('oom_kill')
        self.assertIn(('binary=thumbor', 2), s)
        self.assertIn(('binary=Chrome_IOThread', 1), s)

    def testSegfault(self):
        s = self.store.get_samples('segfault')
        self.assertIn(('binary=rsvg-convert', 3), s)
        self.assertIn(('binary=HTML5 Parser', 1), s)
