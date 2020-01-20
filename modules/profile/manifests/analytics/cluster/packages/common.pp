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
        'libsasl2-modules-gssapi-mit'
    )

    if os_version('debian == stretch') {
        require_package('libssl1.0.2')

        # Hadoop links incorrectly against libcrypto
        # https://issues.apache.org/jira/browse/HADOOP-12845.
        # It links against the soname (libcrypto.so), but not the
        # actual library provided by the libssl* deb packages.
        # There's a workaround: the libssl-dev package provides a
        # symlink (which is otherwise needed during compile time).
        # Debian Stretch provides two versions of OpenSSL (1.0.2 and 1.1),
        # as there was a large API change in OpenSSL and not all packages
        # could be converted to use OpenSSL 1.1 in time for the Buster release.
        # As such, the libssl-dev package on Stretch provides a symlink
        # to OpenSSL 1.1, which is incompatible with the CDH packages
        # provided for Jessie/Stretch. So, on Buster we can use libssl-dev,
        # but on Stretch we need to provide the symlink manually via
        # Puppet.
        # More info: https://phabricator.wikimedia.org/T240934#5817219
        file { '/usr/lib/x86_64-linux-gnu/libcrypto.so':
            ensure => 'link',
            target => '/usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.2',
        }
    } elsif os_version('debian == buster') {
        require_package('libssl1.1', 'libssl-dev')
    }

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
