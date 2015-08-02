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
        'nose',
        'opencv',
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
        'yaml',
        'zbar',                 # T58996
        'zmq',
    ],
}

import genpp
import logging
import pprint

logging.basicConfig(level=logging.DEBUG)

notes = []

# build puppet files
for release in genpp.releases:
    for environ, packages in environ_packages.items():
        installable_packages = set()
        for package in packages:
            new_packages = genpp.get_python_packages(release, package).values()
            if not any(new_packages):
                notes.append(
                    "NOTE: No installable candidates "
                    "found for {} in {}".format(
                        package, release)
                )
            installable_packages.update(
                new_packages
            )

        genpp.write_pp(
            "toollabs::genpp::python_{environ}_{release}".format(
                environ=environ, release=release
            ),
            installable_packages
        )

# build report html
with open(__file__ + ".html", 'w', encoding='utf-8') as f:
    f.write("""<html>
<h1>Python packages installed on Tool Labs</h1>
<table>
<tr><th rowspan=2>Package</th><th colspan={nreleases}>Python 2</th><th colspan={nreleases}>Python 3</th></tr>
<tr>""".format(nreleases=len(genpp.releases)))
    for i in range(2):
        for release in sorted(genpp.releases):
            f.write("<th>{}</th>".format(release[0]))
    f.write("</tr>\n")
    for package in packages:
        anything_found = False
        f.write("<tr><td>{}</td>".format(package))
        for py_ver in [2,3]:
            for release in sorted(genpp.releases):
                packages = genpp.get_python_packages(release, package)
                if packages[py_ver]:
                    f.write("<td>x</td>")
                    anything_found = True
                else:
                    f.write("<td></td>")
        f.write("</tr>\n")
        if not anything_found:
            raise Exception("No installable candidates found for {}".format(package))
    f.write("</table>\n")

    f.write("<h2>Notes</h2>\n<ul>")
    for note in notes:
        f.write("<li>{}</li>\n".format(note))
    f.write("</ul>\n")
    f.write("</html>")
