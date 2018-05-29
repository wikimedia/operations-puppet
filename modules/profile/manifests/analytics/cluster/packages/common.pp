# == Class profile::analytics::cluster::packages::common
#
# Common other-packages that should be installed on analytics computation
# nodes (workers and clients).
# This class probably should not be included on any 'master' type nodes.
#
class profile::analytics::cluster::packages::common {

    # Install MaxMind databases for geocoding UDFs
    class { '::geoip': }

    # Need R for Spark2R.
    class { '::r_lang': }

    # Note: RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
    require_package('r-cran-rmysql')

    require_package(
        'python-sympy',
        'python-pandas',          'python3-pandas',
        'python-scipy',           'python3-scipy',
        'python-requests',        'python3-requests',
        'python-matplotlib',      'python3-matplotlib',
        'python-dateutil',        'python3-dateutil',
        'python-docopt',          'python3-docopt',
        'python-numpy',           'python3-numpy',
        'python-yaml',            'python3-yaml',
        'python-kafka',           'python3-kafka',
        'python-confluent-kafka', 'python3-confluent-kafka',
        'python3-tabulate',
        'python3-enchant',
        'python3-tz',
        'python3-nltk',
        'python3-nose',
        'python3-setuptools',
        'python3-mmh3',
        'python3-sklearn',
        'python3-sklearn-lib',
        'libgomp1',
        'snakebite', # Really nice pure python hdfs client
    )

    # ores::base for ORES packages
    class { '::ores::base': }
}