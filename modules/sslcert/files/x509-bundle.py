#!/usr/bin/env python
# -*- coding: utf-8 -*-

# x509-bundle - creates bundles of X.509 certificates
#
# Copyright 2015 Faidon Liambotis
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

import argparse
import glob
import os
from subprocess import check_output


def file_exists(fname):
    """Helper for argparse to do check if a filename argument exists"""
    if not os.path.exists(fname):
        raise argparse.ArgumentTypeError("{0} does not exist".format(fname))
    return fname


def parse_options():
    """Parse command-line options, return args hash"""
    parser = argparse.ArgumentParser(description="X.509 bundler")
    parser.add_argument('--skip-root', '-s', dest="skip_root",
                        help="skip the final (root) certificate",
                        action='store_true')
    parser.add_argument('--skip-first', '-f', dest="skip_first",
                        help="skip the first (server) certificate",
                        action='store_true')
    parser.add_argument('--certificate', '-c', dest="cert",
                        type=file_exists,
                        help="certificate filename",
                        required=True)
    parser.add_argument('--ca-certs', dest="cadir",
                        help="SSL CA certificates directory",
                        default='/etc/ssl/certs')
    parser.add_argument('--output', '-o', dest="output",
                        help="output filename",
                        required=True)

    return parser.parse_args()


def issuer_hash(filename):
    """Returns the issuer_hash of the certificate"""
    return check_output([
            "openssl", "x509", "-noout",
            "-in", filename,
            "-issuer_hash",
         ]).rstrip()


def traverse_tree(cert, cadir):
    """Construct a tree of the certificate up to a root CA.

    This is a recursive function that takes a certificate filename and a
    c_rehash()ed dir as input (typically, /etc/ssl/certs) and constructs a
    path from the bottom to the root, returning it in a list of filenames.

    In case multiple paths may exist to a self-signed certificate (e.g.
    cross-signed CAs), this picks the shortest one, constructing it in a
    hop-by-hop fashion.
    """
    issuer = issuer_hash(cert)
    issuer_files = glob.glob(os.path.join(cadir, issuer + '.[0-9]'))
    if len(issuer_files) == 0:
        return [cert, ]

    paths = []
    for issuer_variant in issuer_files:
        output = [cert, ]
        if issuer == issuer_hash(issuer_variant):
            # self-signed, end of the road
            output.extend([issuer_variant])
        else:
            # recurse
            output.extend(traverse_tree(issuer_variant, cadir))

        paths.append(output)

    # short ascending by path length, pick the first (i.e. shortest)
    shortest_path = sorted(paths, key=len)[0]
    return shortest_path


def main():
    args = parse_options()
    certpath = traverse_tree(args.cert, args.cadir)
    if args.skip_root:
        certpath.pop()
    if args.skip_first:
        certpath.pop(0)

    if len(certpath):
        pretty = [certpath[0]] + [os.readlink(f) for f in certpath[1:]]
        print(" -> ".join(pretty))
    else:
        print("empty chain (due to skipped root/first?)")

    # now that we have an issuer path, actually write the bundle
    with open(args.output, "wb") as outfile:
        for cert in certpath:
            # open with U, to handle Windows newlines
            with open(cert, "rU") as infile:
                incontents = infile.read()
                # add an eol if not already there, frequent source of trouble
                if incontents[-1] != "\n":
                    incontents += "\n"
                outfile.write(incontents)


if __name__ == '__main__':
    main()

# vim: set ts=4 sw=4 et:
