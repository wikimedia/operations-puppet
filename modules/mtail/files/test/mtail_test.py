import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class EximTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/exim.mtail'),
                os.path.join(test_dir, 'logs/exim.test'))

    def testEximMessages(self):
        m = self.store.get_metric('exim_messages_total')
        self.assertEqual(3, m._value)
        self.assertIn('status=out', m._labelpairs)

        m = self.store.get_metric('exim_messages_bytes')
        self.assertEqual(183084, m._value)
        self.assertIn('status=out', m._labelpairs)
