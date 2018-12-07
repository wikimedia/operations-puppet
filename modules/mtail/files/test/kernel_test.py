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
        self.assertIn(('binary=thumbor,hostname=thumbor1003', 1), s)
        self.assertIn(('binary=thumbor,hostname=thumbor1001', 1), s)
        self.assertIn(('binary=Chrome_IOThread,hostname=scb1003', 1), s)

    def testSegfault(self):
        s = self.store.get_samples('segfault')
        self.assertIn(('binary=rsvg-convert,hostname=thumbor1003', 2), s)
        self.assertIn(('binary=rsvg-convert,hostname=thumbor1002', 1), s)
        self.assertIn(('binary=HTML5 Parser,hostname=sca2004', 1), s)

    def testThrottle(self):
        s = self.store.get_samples('cpu_throttled')
        self.assertIn(('hostname=mw1227', 1), s)
        self.assertIn(('hostname=mw1225', 1), s)
        self.assertIn(('hostname=mw1253', 2), s)

    def testEdac(self):
        s = self.store.get_samples('edac_events')
        self.assertIn(('hostname=mw1239', 1), s)

    def testRespawn(self):
        s = self.store.get_samples('upstart_respawn')
        self.assertIn(('service=nova-spiceproxy,hostname=labcontrol1002', 1), s)
