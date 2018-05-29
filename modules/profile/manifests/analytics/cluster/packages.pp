# == Class profile::analytics::cluster::packages
#
# Common other-packages that should be installed on analytics computation
# nodes (workers and clients).
# This class probably should not be included on any 'master' type nodes.
#
# TODO: refactor this and statistics::packages class.
#
class profile::analytics::cluster::packages {

    # Install MaxMind databases for geocoding UDFs
    class { '::geoip': }

    # Need R for Spark2R.
    class { '::r_lang': }

    # Note: RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
    require_package('r-cran-rmysql')

    require_package(
        'python-pandas',
        'python-scipy',
        'python-requests',
        'python-matplotlib',
        'python-dateutil',
        'python-sympy',
        'python-docopt',
        'python3-dateutil',
        'python3-docopt',
        'python3-tabulate',
        'python3-scipy',
        'python3-enchant',
        'python3-tz',
        'python3-nltk',
        'python3-nose',
        'python3-setuptools',
        'python3-requests',
        'python3-mmh3',
        'python3-docopt',
        'libgomp1',
        'python-numpy',
        'python3-numpy',
        'python3-sklearn',
        'python3-sklearn-lib',
        # Really nice pure python hdfs client
        'snakebite',

    )

    # ores::base for ORES packages
    class { '::ores::base': }
}