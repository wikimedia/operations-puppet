# === Class mediawiki::packages::php5
#
# This class declares packages that make up Wikimedia's PHP5-based
# MediaWiki deployment stack. As of August 2016, most installs are
# configured for HHVM, but a few are still using PHP5 (T86081).
#
class mediawiki::packages::php5 {

    # Wikimedia PHP extensions
    package { [
        'php-luasandbox',
        'php-wikidiff2',
    ]:
        ensure => present,
    }

    # Third-party PHP extensions
    package { [
        'php5-geoip',
        'php5-xmlrpc',
    ]:
        ensure => present,
    }
}
