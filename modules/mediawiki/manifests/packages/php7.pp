# === Class mediawiki::packages::php7
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack. We'll be moving to this by mid-2018.
# See T172165
#
class mediawiki::packages::php7 {
    # Run-time
    require_package('php7.0-cli', 'php7.0-common')

    # Wikimedia PHP extensions
    require_package('php-luasandbox', 'php-wikidiff2')

    # Third-party PHP extensions
    require_package('php-curl', 'php-geoip', 'php-intl', 'php-memcached', 'php-mysql', 'php-redis', 'php-xmlrpc')
}
