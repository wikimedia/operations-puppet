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

    def testDKIM(self):
        m = self.store.get_metric('exim_dkim_failure_total')
        self.assertEqual(2, m._value)

        m = self.store.get_metric('exim_dkim_success_total')
        self.assertEqual(1, m._value)

    def testMiscErrors(self):
        m = self.store.get_metric('exim_smtp_errors_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_rejected_rcpt_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_tls_errors_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_sender_verify_fail_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_sender_verify_defer_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_too_many_connections_total')
        self.assertEqual(1, m._value)

        m = self.store.get_metric('exim_rejected_helo_total')
        self.assertEqual(1, m._value)
