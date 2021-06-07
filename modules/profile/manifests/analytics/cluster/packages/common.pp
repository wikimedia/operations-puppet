# == Class profile::analytics::cluster::packages::common
#
# Common other-packages that should be installed on analytics computation
# nodes (workers and clients).
# Before including this class, check its "extensions":
# - profile::analytics::cluster::packages::statistics
#
class profile::analytics::cluster::packages::common {
    # See: https://gerrit.wikimedia.org/r/c/operations/puppet/+/480041/
    # and: https://phabricator.wikimedia.org/T229347
    # python3.7 will assist with a Spark & Buster upgrade.
    require profile::python37

    # Install MaxMind databases for geocoding UDFs
    class { '::geoip': }

    # Need R for Spark2R.
    class { '::r_lang': }

    # Note: RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
    ensure_packages([
        'r-cran-rmysql',  # RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
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
        'python3-mock', # needed to run refinery-drop-older-than
        'python3-setuptools',
        'python3-sklearn-lib',
        # for uploading files from Hadoop, etc. to Swift object store.
        'python3-swiftclient',
        'libgomp1',
        # For pyhive
        'libsasl2-dev',
        'libsasl2-modules-gssapi-mit',
        # For any package that requires gss-api libs,
        # like requests-kerberos (used by presto-python-client).
        'libkrb5-dev',
        # We hope to eventually replace all of the above python packages
        # with this one.  It is easier to maintain this single anaconda
        # based package than many different python debian packages.
        # See: https://wikitech.wikimedia.org/wiki/Analytics/Systems/Anaconda
        'anaconda-wmf',
    ])

    # These packages need to be reviewed in the context of Debian Buster
    # to figure out if we need to rebuild them or simply copy them over in reprepro.
    if debian::codename::le('stretch') {
        ensure_packages('python3-mmh3')
    }

    # Apache BigTop 1.4+ ships with Hadoop 2.8+,
    # compatible with openssl 1.1.0
    ensure_packages(['libssl1.1', 'libssl-dev'])

    # ores::base for ORES packages
    class { '::ores::base': }
    class { '::git::lfs': }

    # Include maven and our archiva settings everywhere to make it
    # easier to resolve job dependencies at runtime from archiva.wikimedia.org
    class { '::maven': }
}
