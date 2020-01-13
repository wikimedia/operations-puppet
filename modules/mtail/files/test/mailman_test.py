import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class MailmanTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/mailman.mtail'),
                os.path.join(test_dir, 'logs/mailman.test'))

    def testSmtpDuration(self):
        s = self.store.get_samples('mailman_smtp_duration_seconds')[0]
        self.assertEqual(s[0], '')
        self.assertEqual(round(s[1], 2), 262.3)

    def testSmtpTotal(self):
        s = self.store.get_samples('mailman_smtp_total')
        self.assertIn(('', 52), s)

    def testSubscribeRequest(self):
        s = self.store.get_samples('mailman_subscribe_request_total')
        self.assertIn(('', 33), s)
