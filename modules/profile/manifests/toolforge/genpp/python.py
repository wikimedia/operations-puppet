#!/usr/bin/env python3
# This script generates python package listings for
# different host types (dev, exec, ...) for both
# python 2 and 3, and for all genpp-supported
# distributions

import genpp
import logging

environ_packages = {
    'dev': [
        'cffi',
        'coverage',
        'dev',
        'stdeb',
    ],
    'exec': [
        'babel',                # T60220
        'beautifulsoup',        # For valhallasw.
        'bottle',               # T58995
        'celery',
        'cffi',                 # T204422
        'egenix-mxdatetime',
        'egenix-mxtools',
        'enum34',               # T111602
        'flask',
        'flask-login',
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
        'mysql.connector',
        'mysqldb',
        'newt',
        'numpy',                # T131675
        'nose',
        'opencv',
        'requests-oauthlib',    # T130529
        'pandas',               # T131675
        'pil',                  # T108210
        'problem-report',
        'psycopg2',
        'pycountry',            # T86015
        'pydot',                # T86015
        'pyexiv2',              # T61122.
        'pygments',             # T71050
        'pyicu',                # T102165
        'pyinotify',            # T59003
        'requests',
        'rsvg',                 # T58996
        'scipy',                # T103136
        'sqlalchemy',
        'svn',                  # T58996
        'tk',                   # T182562
        'twisted',
        'twitter',
        'unicodecsv',           # T86015
        'unittest2',            # T86015
        'venv',
        'virtualenv',
        'wadllib',
        'webpy',
        'werkzeug',
        'zbar',                 # T58996
        'zmq',
    ],
}

logging.basicConfig(level=logging.DEBUG)

environ_processed = {}

for environ, packages_post in environ_packages.items():
    package_list = {}
    for package_post in packages_post:
        for prefix in ['python-', 'python3-']:
            package_name = prefix + package_post
            package_list[package_name] = {
                release: genpp.get_version(package_name, release)
                for release in genpp.releases
            }

    for release in genpp.releases:
        genpp.write_pp(
            'python',
            release,
            environ,
            package_list
        )

    environ_processed[environ] = package_list

genpp.write_report(
    'python',
    environ_processed
)
