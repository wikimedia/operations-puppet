#!/usr/bin/env python3

import argparse
import logging
import ssl
from datetime import datetime

import pytz
from OpenSSL.crypto import FILETYPE_PEM, X509Store, load_certificate

import nagiosplugin


class MCRouterCertVerification(nagiosplugin.Resource):
    """Domain model: client cert validation."""

    def __init__(self, ca_path=None, clientcert_path=None, clientkey_path=None,
                 check_server=False, check_disk=True):
        self.ca_path = ca_path
        self.clientcert_path = clientcert_path
        self.clientkey_path = clientkey_path
        self.check_server = check_server
        self.check_on_disk = check_disk
        self.log = logging.getLogger('nagiosplugin')

    def check_certificates_on_disk(self):
        """ this function checks certificates stored on disk """
        self.log.info('reading certificates')
        with open(self.ca_path, 'r') as f:
            ca_certificate = load_certificate(FILETYPE_PEM, f.read())

        with open(self.clientcert_path, 'r') as f:
            client_certificate = load_certificate(FILETYPE_PEM, f.read())
        store = X509Store()
        store.add_cert(ca_certificate)
        now = datetime.utcnow().replace(tzinfo=pytz.UTC)
        client_cert_notafter_date = (datetime.strptime(
                                    client_certificate
                                    .get_notAfter()
                                    .decode('utf-8'), "%Y%m%d%H%M%SZ")
                                    .replace(tzinfo=pytz.UTC)
                                    )
        ca_notafter_date = (datetime.strptime(
                            ca_certificate.get_notAfter()
                            .decode('utf-8'), "%Y%m%d%H%M%SZ")
                            .replace(tzinfo=pytz.UTC))

        return ((client_cert_notafter_date-now).days,
                (ca_notafter_date-now).days)

    def check_certificates_running_on_server(self):
        """ this function checks certificates lives on mcrouter

            TODO: evolve this check or add a new one that checks
                  if a client certificate
                  can establish a TLS session with the server
        """
        host_addr = '127.0.0.1'
        host_port = 11214
        self.log.debug('creating SSL context')
        context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH,
                                             cafile=self.ca_path)
        context.verify_mode = ssl.CERT_OPTIONAL
        context.check_hostname = False
        cert = ssl.get_server_certificate(
            (host_addr, host_port),
            ca_certs=self.ca_path)
        x509_cert = load_certificate(FILETYPE_PEM, cert)
        server_cert_notafter_date = (datetime.strptime(
                                     x509_cert
                                     .get_notAfter()
                                     .decode('utf-8'), "%Y%m%d%H%M%SZ")
                                     .replace(tzinfo=pytz.UTC))
        now = datetime.utcnow().replace(tzinfo=pytz.UTC)
        return (server_cert_notafter_date-now).days

    def probe(self):
        if self.check_on_disk is True:
            cert_exp_days, ca_exp_days = self.check_certificates_on_disk()
            yield nagiosplugin.Metric(
                'days_left_to_client_cert_expiration',
                cert_exp_days,
                min=0,
                context='mcrouter_cert_expiration')
            yield nagiosplugin.Metric(
                'days_left_to_ca_expiration',
                ca_exp_days,
                min=0,
                context='mcrouter_cert_expiration')
        if self.check_server is True:
            runningsocket = self.check_certificates_running_on_server()
            yield nagiosplugin.Metric(
                 'days_left_expiration_on_cert_used_by_mcrouter',
                 runningsocket,
                 min=0,
                 context='mcrouter_cert_expiration')


@nagiosplugin.guarded
def main():
    argp = argparse.ArgumentParser(description=__doc__)
    argp.add_argument(
        '-w', '--warning', metavar='RANGE', default='@~:60',
        help='return warning if expiration date is outside RANGE')
    # reducing it to 1 day to reduce noise.
    argp.add_argument(
        '-c', '--critical', metavar='RANGE', default='@~:1',
        help='return critical if expiration date is outside RANGE')
    argp.add_argument(
        '-r', '--ca', default='/etc/mcrouter/ssl/ca.pem', action='store',
        help='path to the CA pem file')
    argp.add_argument('-p', '--client-certificate',
                      default='/etc/mcrouter/ssl/cert.pem',
                      action='store',
                      help='path to the client certificate pem file')
    argp.add_argument('-k', '--client-certificate-key',
                      default='/etc/mcrouter/ssl/cert.key',
                      action='store',
                      help='path to the client certificate key pem file')
    argp.add_argument(
        '--server-check', dest='check_server', action='store_true')
    argp.add_argument(
        '--no-server-check', dest='check_server', action='store_false')
    argp.add_argument(
        '--check-certs-on-disk',
        dest='check_certs_on_disk',
        action='store_true')
    argp.add_argument(
        '--no-check-certs-on-disk',
        dest='check_certs_on_disk',
        action='store_false')
    argp.set_defaults(check_certs_on_disk=True)
    argp.set_defaults(check_server=False)
    argp.add_argument(
        '-v', '--verbose', action='count', default=0,
        help='increase output verbosity (use up to 3 times)')
    args = argp.parse_args()
    check = nagiosplugin.Check(
        MCRouterCertVerification(
            args.ca,
            args.client_certificate,
            args.client_certificate_key,
            args.check_server,
            args.check_certs_on_disk),
        nagiosplugin.ScalarContext(
            'mcrouter_cert_expiration',
            args.warning,
            args.critical),
        )
    check.main(verbose=args.verbose)


if __name__ == '__main__':
    main()
