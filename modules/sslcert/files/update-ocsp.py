#!/usr/bin/env python
# -*- coding: utf-8 -*-

# update-ocsp - creates or updates an OCSP stapling file for an SSL cert
#
# Copyright 2015 Brandon Black
# Copyright 2015 Wikimedia Foundation, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import re
import errno
import argparse
import ConfigParser
import subprocess
import glob
import tempfile
import datetime
import urlparse


def file_exists(fname):
    """Helper for argparse to do check if a filename argument exists"""
    if not os.path.exists(fname):
        raise argparse.ArgumentTypeError("{0} does not exist".format(fname))
    return fname


def parse_options():
    """Parse command-line options, return args hash"""
    parser = argparse.ArgumentParser(description="OCSP Fetcher")

    # read options from a config file first
    parser.add_argument("--config", "-f",
                        type=file_exists, metavar="FILE",
                        help="Specify config file")

    args, _ = parser.parse_known_args()
    defaults = {}
    if args.config:
        config = ConfigParser.SafeConfigParser()
        config.read([args.config])
        defaults = dict(config.items("Options"))

        # Handle the list of certificates (separated by comma) manually.
        # While at it, also allow the simple form of "Certificate"
        if 'certificates' in defaults:
            defaults['certificates'] = defaults['certificates'].split(',')
        elif 'certificate' in defaults:
            defaults['certificates'] = [defaults['certificate']]
            del defaults['certificate']

    parser.set_defaults(**defaults)

    # parse command-line arguments, overriding the config if we have both
    parser.add_argument('--certificate', '-c', dest="certificates",
                        type=file_exists, metavar="FILE",
                        action="append",
                        help="certificate filename",
                        required=('certificates' not in defaults))
    parser.add_argument('--output', '-o', dest="output",
                        metavar="FILE",
                        help="output filename",
                        required=('output' not in defaults))
    parser.add_argument('--proxy', '-p', dest="proxy",
                        help="HTTP proxy host:port to use for OCSP request")
    parser.add_argument('--ca-certs', '-d', dest="cadir",
                        help="SSL CA certificates directory",
                        default='/etc/ssl/certs')
    parser.add_argument('--time-offset-start', '-s', dest="time_offset_start",
                        help="validate thisUpdate/NotBefore <= X secs ahead",
                        type=int, default=60)
    parser.add_argument('--time-offset-end', '-e', dest="time_offset_end",
                        help="validate nextUpdate >= X secs in the future",
                        type=int, default=3600)
    parser.add_argument('--min-cert-life', '-m', dest="min_cert_life",
                        help="validate cert life >= X secs in the future",
                        type=int, default=3600)

    return parser.parse_args()


def check_output_errtext(args):
    """exec args, returns (stdout,stderr). raises on rv!=0 w/ stderr in msg"""

    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (p_out, p_err) = p.communicate()
    if p.returncode != 0:
        raise Exception("Command %s failed with exit code %i, stderr:\n%s" %
                        (" ".join(args), p.returncode, p_err))
    return (p_out, p_err)


def ossl_parse_stamp(stamp):
    """Parse an timestamp from OpenSSL output to a datetime object"""

    return datetime.datetime.strptime(stamp, "%b %d %H:%M:%S %Y %Z")


def cert_x509_option(filename, attrib):
    """Returns output of an openssl x509 cert option w/ noout"""

    return check_output_errtext([
        "openssl", "x509", "-noout",
        "-in", filename,
        "-" + attrib,
    ])[0].rstrip()


def cert_x509_option_kv(filename, attrib):
    """As above, but returns the value when output is k=v"""

    k, v = cert_x509_option(filename, attrib).split("=", 1)
    assert k == attrib
    return v


def cert_get_issuer_filename(cert, cadir):
    """Get the filename of the immediate issuer of the given cert"""

    # Note, this uses the pre-0.9.6 algorithm - it can be confused if
    #  there are 2+ distinct possible issuers in cadir with identical subjects!
    #  (is there a way to resolve that ambiguity that isn't unreasonable?)

    issuer_subject = cert_x509_option_kv(cert, "issuer")
    issuer_hash = cert_x509_option(cert, "issuer_hash")
    issuer_glob = glob.glob(os.path.join(cadir, issuer_hash + '.[0-9]'))
    for issuer in issuer_glob:
        if cert_x509_option_kv(issuer, "subject") == issuer_subject:
            return issuer
    raise Exception("No matching issuer file found at %s for %s" %
                    (issuer_glob, cert))


def ocsp_validate_window(cert, now, thisup, nextup, o_start, o_end):
    """Validate the validity range of the OCSP response"""

    thisup_notafter = now + datetime.timedelta(0, o_start)
    if thisup > thisup_notafter:
        raise Exception("OCSP thisUpdate for %s > %i secs in the future" %
                        (cert, o_start))

    nextup_notbefore = now + datetime.timedelta(0, o_end)
    if nextup < nextup_notbefore:
        raise Exception("OCSP nextUpdate for %s < %i secs in the future" %
                        (cert, o_end))


def certs_fetch_ocsp(out_temp, args):
    """Fetch validated OCSP response for certs"""

    cadir = args.cadir
    certs = args.certificates
    proxy = args.proxy
    o_start = args.time_offset_start
    o_end = args.time_offset_end
    min_cert = args.min_cert_life

    issuer_path = cert_get_issuer_filename(certs[0], cadir)
    ocsp_uri = cert_x509_option(certs[0], "ocsp_uri")

    if len(certs) > 1:
        for cert_idx in range(1, len(certs)):
            this_issuer_path = cert_get_issuer_filename(certs[cert_idx], cadir)
            this_ocsp_uri = cert_x509_option(certs[cert_idx], "ocsp_uri")
            if issuer_path != this_issuer_path:
                raise Exception("Certs must have same Issuer (%s vs %s)!" %
                                (issuer_path, this_issuer_path))
            if ocsp_uri != this_ocsp_uri:
                raise Exception("Certs must have same OCSP URI (%s vs %s)!" %
                                (ocsp_uri, this_ocsp_uri))

    cmd = [
        "openssl", "ocsp", "-resp_text",
        "-respout", out_temp,
        "-issuer", issuer_path,
        "-verify_other", issuer_path,
    ]

    if proxy:
        cmd.extend([
            "-path", ocsp_uri,
            "-host", proxy,
        ])
    else:
        # OpenSSL only speaks HTTP/1.0 and sends no Host header. This doesn't
        # really work in many OCSP servers, so supply the Host header manually.
        hosthdr = urlparse.urlparse(ocsp_uri).netloc
        cmd.extend([
            "-url", ocsp_uri,
            "-header", "Host={}".format(hosthdr),
        ])

    for cert in certs:
        cmd.extend(["-cert", cert])

    (ocsp_text, ocsp_err) = check_output_errtext(cmd)

    # Check the overall response verification
    if not re.search('^Response verify OK$', ocsp_err, re.M):
        raise Exception("Did not find verification OK in stderr:\n%s" %
                        (ocsp_err))

    # Check the response says successful rather than revoked
    if not re.search(r'^\s*OCSP Response Status: successful \(0x0\)$',
                     ocsp_text, re.M):
        raise Exception("OCSP Response Status not successful:\n%s" %
                        (ocsp_text))

    now_dt = datetime.datetime.utcnow()

    # This starts out based on min_cert, then is raised to the greater
    #   of that and the "Next Update" of all certs in the set
    cert_notafter_compare = now_dt + datetime.timedelta(0, min_cert)

    # Check the windows on each of the cert responses
    for cert in certs:
        pat = (
            '^' + re.escape(cert) + ': good\n'
            + r'\s*This Update: ([^\n]+)\n'
            + r'\s*Next Update: ([^\n]+)\n'
        )
        res = re.search(pat, ocsp_text, re.M)
        if not res:
            raise Exception("Did not find good update for %s in output:\n%s" %
                            (cert, ocsp_text))
        this_up = ossl_parse_stamp(res.group(1))
        next_up = ossl_parse_stamp(res.group(2))
        ocsp_validate_window(cert, now_dt, this_up, next_up, o_start, o_end)
        if next_up > cert_notafter_compare:
            cert_notafter_compare = next_up

    # Check the signing cert's validity, if included in response
    v_pat = (
        r'^\s*Validity\n'
        + r'\s*Not Before: ([^\n]+)\n'
        + r'\s*Not After : ([^\n]+)\n'
    )
    v_res = re.search(v_pat, ocsp_text, re.M)
    if v_res:
        cert_notbefore = ossl_parse_stamp(v_res.group(1))
        cert_notafter = ossl_parse_stamp(v_res.group(2))
        cert_notbefore_compare = now_dt + datetime.timedelta(0, o_start)
        if cert_notbefore > cert_notbefore_compare:
            raise Exception("signing cert starts > %i secs in the future!" %
                            (o_start))
        if cert_notafter < cert_notafter_compare:
            raise Exception("signing cert ends before %s!" %
                            (cert_notafter_compare))


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


def main():
    args = parse_options()

    os.umask(022)
    out_fn = os.path.basename(args.output)
    out_basedir = os.path.dirname(args.output)
    mkdir_p(out_basedir)
    out_tempdir = tempfile.mkdtemp(".tmp", "update-ocsp-", out_basedir)
    out_tempfile = os.path.join(out_tempdir, out_fn)

    certs_fetch_ocsp(out_tempfile, args)

    os.rename(out_tempfile, args.output)
    os.rmdir(out_tempdir)


if __name__ == '__main__':
    main()

# vim: set ts=4 sw=4 et:
