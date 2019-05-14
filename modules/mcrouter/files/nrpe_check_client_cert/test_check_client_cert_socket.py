#!/usr/bin/env python3
import sys
import unittest
import multiprocessing
import time
import socket
import ssl
try:
    # python 3.4+ should use builtin unittest.mock not mock package
    from unittest.mock import patch
except ImportError:
    from mock import patch


class CheckValidSocketCertificateTestCase(unittest.TestCase):

    def launch_fake_mcrouter_server(self,
                                    listen_addr,
                                    listen_port,
                                    server_cert,
                                    server_key,
                                    capath):
        context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        context.verify_mode = ssl.CERT_OPTIONAL
        context.load_cert_chain(certfile=server_cert, keyfile=server_key)
        context.load_verify_locations(cafile=capath)
        bindsocket = socket.socket()
        bindsocket.bind((listen_addr, listen_port))
        bindsocket.listen(5)
        while True:
            try:
                newsocket, fromaddr = bindsocket.accept()
                conn = context.wrap_socket(newsocket, server_side=True)
                conn.recv(4096)
            except Exception:
                pass
            finally:
                conn.close()
                bindsocket.close()

    def test_socket_ssl_valid_ca_and_valid_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/2_valid_ca.pem",
                    "-p", "./fixtures/2_valid_cert.pem",
                    "-k", "./fixtures/2_valid_cert.key",
                    "--no-check-certs-on-disk",
                    "--server-check"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '0'):
                process = multiprocessing.Process(
                    target=self.launch_fake_mcrouter_server,
                    args=(
                        'localhost',
                        11214,
                        './fixtures/2_valid_ca.pem',
                        './fixtures/2_valid_ca.key',
                        './fixtures/2_valid_cert.pem'))
                process.daemon = True
                process.start()
                target.main()
                process.terminate()
                time.sleep(60)

    def test_socket_ssl_expired_ca_and_expired_cert(self):
        testargs = [sys.argv[0],
                    "-w", "@~:60",
                    "-c", "@~:30",
                    "-r", "./fixtures/4_expired_ca.pem",
                    "-p", "./fixtures/4_expired_cert.pem",
                    "-k", "./fixtures/4_expired_cert.key",
                    "--no-check-certs-on-disk",
                    "--server-check"]
        with patch.object(sys, 'argv', testargs):
            target = __import__("check_client_cert")
            with self.assertRaisesRegexp(SystemExit, '2'):
                process = multiprocessing.Process(
                    target=self.launch_fake_mcrouter_server,
                    args=(
                        'localhost',
                        11214,
                        './fixtures/4_expired_ca.pem',
                        './fixtures/4_expired_ca.key',
                        './fixtures/4_expired_cert.pem'))
                process.daemon = True
                process.start()
                target.main()
                process.terminate()
                time.sleep(60)
