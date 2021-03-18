#!/usr/bin/env python3

import unittest
from datetime import datetime
import cleanup_dlq


class CleanupDLQTest(unittest.TestCase):
    def test_state_last_restarted(self):
        now = datetime.utcnow()
        cleanup_dlq.write_state({'date': {'last_restarted': now}})
        self.assertEqual(cleanup_dlq.read_state()['date']['last_restarted'], now)

    def test_bytes_conversion(self):
        for i, o in [
            ('512kb', 512000),
            ('512mb', 512000000),
            ('512gb', 512000000000),
            ('512tb', 512000000000000)
        ]:
            self.assertEqual(cleanup_dlq.in_bytes(i), o)

        with self.assertRaises(ValueError):
            cleanup_dlq.in_bytes('512d')

    def test_percentage_factor(self):
        for i, o in [('80%', 0.8), ('1', 0.01)]:
            self.assertEqual(cleanup_dlq.percentage_factor(i), o)

        for i in ['%80', '100%', '100', '0%', '0', '0.1']:
            with self.assertRaises(ValueError):
                cleanup_dlq.percentage_factor(i)

    def test_in_seconds(self):
        for i, o in [('1m', 60), ('1h', 3600), ('1d', 86400), ('1', 1)]:
            self.assertEqual(cleanup_dlq.in_seconds(i), o)

        with self.assertRaises(ValueError):
            cleanup_dlq.in_seconds('1w')
