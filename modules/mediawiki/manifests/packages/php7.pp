# === Class mediawiki::packages::php7
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack. We'll be moving to this by mid-2018.
# See T172165
#
# overview of modules needed and their use:
#
# apcu - used by MediaWiki for local server caching
# bz2 - dumps
# curl - HTTP requests
# geoip - fundraising
# intl, mbstring, xml - MediaWiki dependencies
# memcached, mysql, redis - obvious from the name
#
class mediawiki::packages::php7 {
    if os_version('debian == stretch') {
        apt::pin { 'php-wikidiff2':
            package  => 'php-wikidiff2',
            pin      => 'release a=stretch-backports',
            priority => '1010',
        }
        include ::mediawiki::packages::php7
    }

    # Run-time
    require_package('php7-cli', 'php7-common', 'php-curl', 'php-intl',
        'php-mysql', 'php-redis')

    # Wikimedia PHP extensions
    require_package('php-luasandbox', 'php-wikidiff2')

    # Third-party PHP extensions
    require_package('php-apcu', 'php-bz2', 'php-geoip', 'php-mbstring',
        'php-memcached', 'php-xml')
}
