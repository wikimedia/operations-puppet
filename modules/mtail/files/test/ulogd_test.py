'''Test ulogd mtail program'''

import os
import unittest
import mtail_store


TEST_DIR = os.path.join(os.path.dirname(__file__))


class UlogdTest(unittest.TestCase):
    '''Test ulogd mtail program'''
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
            os.path.join(TEST_DIR, '../programs/ulogd.mtail'),
            os.path.join(TEST_DIR, 'logs/ulogd.test'))

    def testIptablesDrop(self):
        '''Test iptables_drop metric'''
        sample = self.store.get_samples('iptables_drops')
        self.assertIn(('ip_version=ipv4,proto=udp', 1), sample)
        self.assertIn(('ip_version=ipv4,proto=tcp', 1), sample)
        self.assertIn(('ip_version=ipv6,proto=udp', 1), sample)
        self.assertIn(('ip_version=ipv6,proto=tcp', 1), sample)
