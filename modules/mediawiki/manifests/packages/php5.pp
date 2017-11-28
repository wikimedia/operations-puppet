# === Class mediawiki::packages::php5
#
# This class declares packages that make up Wikimedia's PHP5-based
# MediaWiki deployment stack. As of August 2016, most installs are
# configured for HHVM, but a few are still using PHP5 (T86081).
#
class mediawiki::packages::php5 {
    # We don't need php-apc on php > 5.3
    package { 'php-apc':
        ensure => absent,
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
}
