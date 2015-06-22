# == Class: mediawiki::packages::php5
#
# This class declares packages that make up Wikimedia's PHP5-based
# MediaWiki deployment stack. As of August 2014, this is the most common
# configuration in production, but new installs are configured for HHVM
# instead.
#
class mediawiki::packages::php5 {
    if os_version('ubuntu < trusty') {
        require_package('php-apc')
    }
    else {
        # We don't need php-apc on trusty
        package { 'php-apc':
            ensure => absent,
        }
    }
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

    if os_version('ubuntu precise') {
        package { [
            'php5-igbinary',   # No longer in use
            'php5-wmerrors',   # Not packaged for Trusty
        ]:
            ensure => present,
        }
    }
}
