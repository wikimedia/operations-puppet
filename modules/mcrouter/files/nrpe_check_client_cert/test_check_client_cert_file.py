#!/usr/bin/env python3
import sys
import unittest

try:
    # python 3.4+ should use builtin unittest.mock not mock package
    from unittest.mock import patch
except ImportError:
    from mock import patch


class CheckValidFileCertificateTestCase(unittest.TestCase):

    def test_expired_ca_and_valid_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/1_expired_ca.pem",
                    "-p", "./fixtures/1_valid_cert.pem"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '2'):
                target.main()

    def test_valid_ca_and_valid_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/2_valid_ca.pem",
                    "-p", "./fixtures/2_valid_cert.pem"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '0'):
                target.main()

    def test_valid_ca_and_expired_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/3_valid_ca.pem",
                    "-p", "./fixtures/3_expired_cert.pem"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '2'):
                target.main()

    def test_expired_ca_and_expired_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/4_expired_ca.pem",
                    "-p", "./fixtures/4_expired_cert.pem"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '2'):
                target.main()

    def test_missing_ca_and_missing_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/unkownca.pem",
                    "-p", "./fixtures/unknown.pem"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '3'):
                target.main()
