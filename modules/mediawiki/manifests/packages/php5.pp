# == Class: mediawiki::packages::php5
#
# This class declares packages that make up Wikimedia's PHP5-based
# MediaWiki deployment stack. As of August 2014, this is the most common
# configuration in production, but new installs are configured for HHVM
# instead.
#
class mediawiki::packages::php5 {
    # Run-time
    package { [ 'php-apc', 'php5-cli', 'php5-common', 'php5-dbg' ]:
        ensure => present,
    }

    # Wikimedia PHP extensions
    package { [ 'php-luasandbox', 'php-wikidiff2', 'php5-fss' ]:
        ensure => present,
    }

    # Third-party PHP extensions
    package { [
        'php5-curl',
        'php5-geoip',
        'php5-intl',
        'php5-memcached',
        'php5-mysql',
        'php5-redis',
        'php5-xmlrpc',
    ]:
        ensure => present,
    }

    if ubuntu_version('precise') {
        package { [
            'libmemcached11',  # Formerly a dependency for php5-memcached
            'php5-igbinary',   # No longer in use
            'php5-wmerrors',   # Not packaged for Trusty
        ]:
            ensure => present,
        }
    }
}
