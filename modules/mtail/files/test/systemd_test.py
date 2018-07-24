import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class SystemdTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/systemd.mtail'),
                os.path.join(test_dir, 'logs/systemd.test'))

    def testRespawn(self):
        s = self.store.get_samples('systemd_respawn')
        self.assertIn(('unit=tileratorui.service', 1), s)
        self.assertIn(('unit=udp2log-mw.service', 1), s)
        self.assertIn(('unit=thumbor@8836.service', 1), s)
