# SPDX-License-Identifier: Apache-2.0
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
        s = self.store.get_samples('exim_messages_total')
        self.assertIn(('status=out', 4), s)

        s = self.store.get_samples('exim_messages_bytes')
        self.assertIn(('status=out', 364379), s)

        s = self.store.get_samples('exim_tls_connections')
        self.assertIn(('status=in,ciphersuite=TLS1.2:ECDHE_RSA_AES_256_GCM_SHA384:256', 1), s)

        s = self.store.get_samples('exim_tls_connections')
        self.assertIn(('status=out,ciphersuite=TLS1.2:ECDHE_RSA_AES_128_GCM_SHA256:128', 1), s)

    def testDKIM(self):
        s = self.store.get_samples('exim_dkim_failure_total')
        self.assertIn(('', 2), s)

        s = self.store.get_samples('exim_dkim_success_total')
        self.assertIn(('', 1), s)

    def testMiscErrors(self):
        s = self.store.get_samples('exim_smtp_errors_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_smtp_errors_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_rejected_rcpt_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_tls_errors_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_sender_verify_fail_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_sender_verify_defer_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_too_many_connections_total')
        self.assertIn(('', 1), s)

        s = self.store.get_samples('exim_rejected_helo_total')
        self.assertIn(('', 1), s)
