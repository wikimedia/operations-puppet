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

    require_package(
        'python-sympy',
        'python-matplotlib',      'python3-matplotlib',
        'python-geoip',           'python3-geoip',
        'python-pandas',          'python3-pandas',
        'python-scipy',           'python3-scipy',
        'python-requests',        'python3-requests',
        'python-dateutil',        'python3-dateutil',
        'python-docopt',          'python3-docopt',
        'python-numpy',           'python3-numpy',
        'python-yaml',            'python3-yaml',
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
    )

    # ores::base for ORES packages
    class { '::ores::base': }
}