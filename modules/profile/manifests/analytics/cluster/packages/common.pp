# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::cluster::packages::common
#
# Common other-packages that should be installed on analytics computation
# nodes (workers and clients).
# Before including this class, check its "extensions":
# - profile::analytics::cluster::packages::statistics
#
class profile::analytics::cluster::packages::common {
    # Install MaxMind databases for geocoding UDFs
    include profile::analytics::geoip

    # Install the ua-parser updated regexes.yaml file
    class { 'ua_parser': }

    # Need R for Spark2R.
    class { 'r_lang': }

    ensure_packages([
        'ipython3',
        'python3-dev',
        'python3-virtualenv',
        'python3-geoip',
        'python3-geoip2',
        'python3-requests',
        'python3-dateutil',
        'python3-docopt',
        'python3-yaml',
        'python3-tabulate',
        'python3-nose',
        'python3-mock', # needed to run refinery-drop-older-than
        'python3-setuptools',
        # for uploading files from Hadoop, etc. to Swift object store.
        'python3-swiftclient',
        'libgomp1',
        # For pyhive
        'libsasl2-dev',
        'libsasl2-modules-gssapi-mit',
        # For any package that requires gss-api libs,
        # like requests-kerberos (used by presto-python-client).
        'libkrb5-dev',

        # Apache BigTop 1.4+ ships with Hadoop 2.8+,
        # compatible with openssl 1.1.0
        'libssl1.1',
        'libssl-dev',
    ])

    # Include maven and our archiva settings everywhere to make it
    # easier to resolve job dependencies at runtime from archiva.wikimedia.org
    class { 'maven': }
}
