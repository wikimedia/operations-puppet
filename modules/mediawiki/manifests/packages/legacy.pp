# === Class mediawiki::packages::legacy
#
# This class declares packages that are used on legacy versions of ubuntu
class mediawiki::packages::legacy {
    requires_os('ubuntu < trusty')

    # Run-time
    package { [
        'php5-cli',
        'php5-common',
        'php5-dbg',
    ]:
        ensure => present,
    }

    # Wikimedia PHP extensions
    package { [
        'php-luasandbox',
        'php-wikidiff2',
        'php5-fss',
    ]:
        ensure => present,
    }

    # Third-party PHP extensions
    package { [
        'php5-apc',
        'php5-curl',
        'php5-geoip',
        'php5-igbinary',
        'php5-intl',
        'php5-memcached',
        'php5-mysql',
        'php5-redis',
        'php5-xmlrpc',
        'php5-wmerrors',
    ]:
        ensure => present,
    }
}
