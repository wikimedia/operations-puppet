# == Class profile::analytics::cluster::packages::common
#
# Common other-packages that should be installed on analytics computation
# nodes (workers and clients).
# Before including this class, check its "extensions":
# - profile::analytics::cluster::packages::hadoop
# - profile::analytics::cluster::packages::statistics
#
class profile::analytics::cluster::packages::common {

    # Install MaxMind databases for geocoding UDFs
    class { '::geoip': }

    # Need R for Spark2R.
    class { '::r_lang': }

    # Note: RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
    require_package('r-cran-rmysql')

    # Python 2 deprecation
    # Note:
    # - python-requests is not explicitly absented since it is a reverse dependency of scap.
    # - python-yaml is not explicitly absented since it is a reverse dependency of scap.
    package {[
            'ipython',
            'python-sympy',
            'python-matplotlib',
            'python-tk',
            'python-geoip',
            'python-geoip2',
            'python-pandas',
            'python-pycountry',
            'python-scipy',
            'python-docopt',
            'python-numpy',
            'python-sklearn',
        ]:
        ensure => absent,
    }

    require_package(
        'ipython3',
        'python3-matplotlib',
        'python3-geoip',
        'python3-geoip2',
        'python3-pandas',
        'python3-pycountry',
        'python3-scipy',
        'python3-requests',
        'python3-dateutil',
        'python3-docopt',
        'python3-numpy',
        'python3-sklearn',
        'python3-yaml',
        'python3-tabulate',
        'python3-enchant',
        'python3-tz',
        'python3-nltk',
        'python3-nose',
        'python3-setuptools',
        'python3-sklearn-lib',
        # for uploading files from Hadoop, etc. to Swift object store.
        'python3-swiftclient',
        'libgomp1',
        # For pyhive
        'libsasl2-dev',
    )

    # These packages need to be reviewed in the context of Debian Buster
    # to figure out if we need to rebuild them or simply copy them over in reprepro.
    if os_version('debian <= stretch') {
        require_package('python3-mmh3')

        # See: https://gerrit.wikimedia.org/r/c/operations/puppet/+/480041/
        # and: https://phabricator.wikimedia.org/T229347
        # python3.7 will assist with a Spark & Buster upgrade.
        apt::repository { 'component-pyall':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/pyall',
            before     => [Package['python3.7'], Package['libpython3.7']],
        }
        if !defined(Package['python3.7']) {
            package { 'python3.7':
                ensure => 'installed',
            }
        }
        if !defined(Package['libpython3.7']) {
            package { 'libpython3.7':
                ensure => 'installed',
            }
        }
    }

    # ores::base for ORES packages
    class { '::ores::base': }
    class { '::git::lfs': }

    # Include maven and our archiva settings everywhere to make it
    # easier to resolve job dependencies at runtime from archiva.wikimedia.org
    class { '::maven': }
}
