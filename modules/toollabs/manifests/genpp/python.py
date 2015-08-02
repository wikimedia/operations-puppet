#!/usr/bin/env python3
# This script generates python package listings for
# different host types (dev, exec, ...) for both
# python 2 and 3, and for all genpp-supported
# distributions

environ_packages = {
    'dev': ['coverage', 'dev', 'stdeb'],
    'exec': [
        'apport',
        'babel',                # T60220
        'beautifulsoup',        # For valhallasw.
        'bottle',               # T58995
        'celery',
        'egenix-mxdatetime',
        'egenix-mxtools',
        'flask',
        'flask-login',
        'flask-oauth',
        'flickrapi',            # T86015
        'flup',
        'gdal',
        'gdbm',
        'genshi',               # T50863.
        'genshi-doc',           # T50863.
        'geoip',                # T64649
        'gevent',
        'gi',
        'greenlet',
        'httplib2',
        'imaging',
        'ipaddr',               # T86015.
        'irclib',
        'keyring',
        'launchpadlib',
        'lxml',                 # T61083.
        'magic',                # T62211.
        'matplotlib',           # T63445.
        'mwparserfromhell',     # T65539
        'mysql.connector',
        'mysqldb',
        'newt',
        'nose',
        'opencv',
        'oursql',               # For danilo et al.
        'problem-report',
        'pycountry',            # T86015
        'pydot',                # T86015
        'pyexiv2',              # T61122.
        'pygments',             # T71050
        'pyinotify',            # T59003
        'requests',
        'rsvg',                 # T58996
        'scipy',
        'socketio-client',      # T86015
        'sqlalchemy',
        'svn',                  # T58996
        'twisted',
        'twitter',
        'unicodecsv',           # T86015
        'unittest2',            # T86015
        'virtualenv',
        'wadllib',
        'webpy',
        'werkzeug',
        'wikitools',
        'yaml',
        'zbar',                 # T58996
        'zmq',
    ],
}

import genpp
import logging
import pprint

logging.basicConfig(level=logging.DEBUG)

for release in genpp.releases:
    for environ, packages in environ_packages.items():
        installable_packages = set()
        for package in packages:
            installable_packages.update(
                genpp.get_python_packages(release, package)
            )

        genpp.write_pp(
            "toollabs::genpp::python_{environ}_{release}".format(
                environ=environ, release=release
            ),
            installable_packages
        )

