# Class: toollabs::genpp::python_exec_precise
#
# This file was auto-generated by genpp.py using the following command:
# python.py
#
# Please do not edit manually!

class toollabs::genpp::python_exec_precise {
    package { [
        'python-apport',        # 2.0.1
        # python3-apport is not available
        'python-babel',         # 0.9.6
        # python3-babel is not available
        'python-beautifulsoup', # 3.2.0
        # python3-beautifulsoup is not available
        'python-bottle',        # 0.10.6
        # python3-bottle is not available
        'python-celery',        # 2.4.6
        # python3-celery is not available
        'python-egenix-mxdatetime', # 3.2.1
        # python3-egenix-mxdatetime is not available
        'python-egenix-mxtools', # 3.2.1
        # python3-egenix-mxtools is not available
        # python-enum34 is not available
        # python3-enum34 is not available
        'python-flask',         # 0.8
        # python3-flask is not available
        # python-flask-login is not available
        # python3-flask-login is not available
        'python-flickrapi',     # 1.2
        # python3-flickrapi is not available
        'python-flup',          # 1.0.2
        # python3-flup is not available
        'python-gdal',          # 1.7.3
        # python3-gdal is not available
        'python-gdbm',          # 2.7.3
        'python3-gdbm',         # 3.2.3
        'python-genshi',        # 0.6
        # python3-genshi is not available
        'python-genshi-doc',    # 0.6
        # python3-genshi-doc is not available
        'python-geoip',         # 1.2.4
        # python3-geoip is not available
        'python-gevent',        # 0.13.6
        # python3-gevent is not available
        'python-gi',            # 3.2.0
        'python3-gi',           # 3.2.0
        'python-greenlet',      # 0.3.1
        # python3-greenlet is not available
        'python-httplib2',      # 0.7.2
        'python3-httplib2',     # 0.7.2
        'python-imaging',       # 1.1.7
        # python3-imaging is not available
        'python-ipaddr',        # 2.1.10
        'python3-ipaddr',       # 2.1.10
        'python-irclib',        # 0.4.8
        # python3-irclib is not available
        'python-keyring',       # 0.9.2
        'python3-keyring',      # 0.9.2
        'python-launchpadlib',  # 1.9.12
        # python3-launchpadlib is not available
        'python-lxml',          # 2.3.2
        'python3-lxml',         # 2.3.2
        'python-magic',         # 5.09
        # python3-magic is not available
        'python-matplotlib',    # 1.1.1~rc1
        # python3-matplotlib is not available
        'python-mysql.connector', # 0.3.2
        # python3-mysql.connector is not available
        'python-mysqldb',       # 1.2.3
        # python3-mysqldb is not available
        'python-newt',          # 0.52.11
        # python3-newt is not available
        'python-nose',          # 1.1.2
        'python3-nose',         # 1.1.2
        'python-opencv',        # 2.3.1
        # python3-opencv is not available
        # python-pil is not available
        # python3-pil is not available
        'python-problem-report', # 2.0.1
        # python3-problem-report is not available
        'python-pycountry',     # 0.14.1
        # python3-pycountry is not available
        'python-pydot',         # 1.0.2
        # python3-pydot is not available
        'python-pyexiv2',       # 0.3.2
        # python3-pyexiv2 is not available
        'python-pygments',      # 1.4
        'python3-pygments',     # 1.4
        'python-pyicu',         # 1.3
        # python3-pyicu is not available
        'python-pyinotify',     # 0.9.2
        # python3-pyinotify is not available
        'python-requests',      # 0.8.2
        # python3-requests is not available
        'python-rsvg',          # 2.32.0
        # python3-rsvg is not available
        'python-scipy',         # 0.9.0
        'python3-scipy',        # 0.9.0
        # python-socketio-client is not available
        # python3-socketio-client is not available
        'python-sqlalchemy',    # 0.7.4
        'python3-sqlalchemy',   # 0.7.4
        'python-svn',           # 1.7.5
        # python3-svn is not available
        'python-twisted',       # 11.1.0
        # python3-twisted is not available
        'python-twitter',       # 0.6
        # python3-twitter is not available
        # python-unicodecsv is not available
        # python3-unicodecsv is not available
        'python-unittest2',     # 0.5.1
        # python3-unittest2 is not available
        'python-virtualenv',    # 1.7.1.2
        # python3-virtualenv is not available
        'python-wadllib',       # 1.3.0
        'python3-wadllib',      # 1.3.0
        'python-webpy',         # 1:0.34
        # python3-webpy is not available
        'python-werkzeug',      # 0.8.1
        # python3-werkzeug is not available
        'python-yaml',          # 3.10
        'python3-yaml',         # 3.10
        'python-zbar',          # 0.10
        # python3-zbar is not available
        'python-zmq',           # 2.1.11
        'python3-zmq',          # 2.1.11
    ]:
        ensure => latest,
    }
}
