# === Class mediawiki::packages::php7
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack. We'll be moving to this by mid-2018.
# See T172165
#
class mediawiki::packages::php7 {
    # We don't need php-apc on php > 5.3
    package { 'php-apc':
        ensure => absent,
    }

    # Run-time
    package { [
        'php7.0-cli',
        'php7.0-common',
        'php-dbg',
    ]:
        ensure => present,
    }

    # Wikimedia PHP extensions
    # THESE NEED TO BE BUILT AND TESTED
    package { [
        'php7-luasandbox',
        'php7-wikidiff2',
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
