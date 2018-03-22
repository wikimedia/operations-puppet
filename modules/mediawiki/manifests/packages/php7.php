# === Class mediawiki::packages::php7
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack. As of August 2016, most installs are
# configured for HHVM, but a few are still using PHP5 (T86081).
#
class mediawiki::packages::php7 {

    # Run-time
    package { [
        'php7.0-cli',
        'php-common',
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
        'php7.0-curl',
        'php-geoip',
        'php7.0-intl',
        'php-memcached',
        'php7.0-mysql',
        'php-redis',
        'php7.0-xmlrpc',
    ]:
        ensure => present,
    }
}
